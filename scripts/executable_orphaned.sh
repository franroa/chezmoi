#!/usr/bin/env bash
set -euo pipefail

# --- Configuration & Defaults ---
MIN_AGE_HOURS=24
KUBE_DIR="$HOME/.kube"
DRY_RUN=true
CREATE_SNAPSHOT=false

# --- Usage / Help ---
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Scans every AKS cluster found in the kubeconfigs under $KUBE_DIR, resolves each
cluster's node resource group, and reports unattached 'pvc-*' disks that no PV
in that cluster references.

Options:
  -k, --kube-dir         Directory with kubeconfig files (Default: $KUBE_DIR)
  -a, --min-age-hours    Minimum age in hours before a disk is eligible for deletion (Default: 24)
  -s, --snapshot         Take an Azure snapshot of each disk before deletion
  --apply                Perform actual deletion (Default is dry-run mode).
                         Never applied to contexts whose name contains 'live'.
  -h, --help             Show this help message
EOF
  exit 1
}

# --- Parse Arguments ---
while [[ $# -gt 0 ]]; do
  case "$1" in
  -k | --kube-dir)
    KUBE_DIR="$2"
    shift 2
    ;;
  -a | --min-age-hours)
    MIN_AGE_HOURS="$2"
    shift 2
    ;;
  -s | --snapshot)
    CREATE_SNAPSHOT=true
    shift
    ;;
  --apply)
    DRY_RUN=false
    shift
    ;;
  -h | --help)
    usage
    ;;
  *)
    echo "Unknown argument: $1" >&2
    usage
    ;;
  esac
done

# --- Dependency Verification ---
for cmd in az kubectl jq; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: Required command '$cmd' is not installed or not in PATH." >&2
    exit 1
  fi
done

# --- Kubeconfig Discovery ---
# Skip *.bak (same user names, stale exec args), non-Azure configs and anything that is not a kubeconfig.
mapfile -t KUBECONFIGS < <(
  find "$KUBE_DIR" -maxdepth 1 -type f ! -name '*.bak' ! -name '__None__*' ! -name 'kubie.yaml' | sort |
    while read -r f; do grep -qE '^kind: ?Config' "$f" 2>/dev/null && echo "$f"; done
)

if [[ ${#KUBECONFIGS[@]} -eq 0 ]]; then
  echo "Error: no kubeconfig files found in $KUBE_DIR." >&2
  exit 1
fi

echo "================================================================="
echo " ORPHANED PVC DISK SCAN"
echo "================================================================="
echo "Kubeconfigs:         ${#KUBECONFIGS[@]} in $KUBE_DIR"
echo "Min Age Threshold:   ${MIN_AGE_HOURS} hours"
echo "Execution Mode:      $([[ "$DRY_RUN" == true ]] && echo "DRY-RUN (No changes)" || echo "LIVE RUN (Destructive, non-live contexts only)")"
echo "Snapshot on Delete:  $CREATE_SNAPSHOT"
echo "================================================================="
echo ""

if [[ "$DRY_RUN" == false ]]; then
  read -r -p "Are you sure you want to proceed with live deletion? (Type 'CONFIRM' to continue): " confirmation
  if [[ "$confirmation" != "CONFIRM" ]]; then
    echo "Aborted by user."
    exit 0
  fi
  echo ""
fi

NOW_EPOCH=$(date +%s)
MIN_AGE_SECONDS=$((MIN_AGE_HOURS * 3600))

declare -A SEEN_RGS=()       # "<sub>/<nodeRG>" already scanned (contexts overlap between kubeconfigs)
declare -a UNREACHABLE=()    # contexts whose PVs could not be listed
declare -a SKIPPED=()        # contexts that are not AKS clusters or could not be resolved
declare -a SUMMARY=()        # one line per scanned cluster
TOTAL_ALL=0

# --- Per-cluster scan ---
scan_cluster() {
  local kubeconfig="$1" ctx="$2" aks_rg="$3" aks_name="$4"

  echo "-----------------------------------------------------------------"
  echo " $ctx  (AKS: $aks_name, RG: $aks_rg)"
  echo "-----------------------------------------------------------------"

  # Resolve subscription + node resource group via Resource Graph
  local info sub node_rg
  info=$(az graph query -q "resources | where type=='microsoft.containerservice/managedclusters' and tolower(name)=='${aks_name,,}' and tolower(resourceGroup)=='${aks_rg,,}' | project sub=subscriptionId, nodeRg=tostring(properties.nodeResourceGroup)" \
    --query 'data[0]' -o json 2>/dev/null || echo null)
  if [[ "$info" == "null" || -z "$info" ]]; then
    echo "  Could not resolve AKS cluster in Azure (no access or wrong name). Skipping."
    SKIPPED+=("$ctx (cluster not found in Azure)")
    return 0
  fi
  sub=$(jq -r '.sub' <<<"$info")
  node_rg=$(jq -r '.nodeRg' <<<"$info")

  if [[ -n "${SEEN_RGS["$sub/${node_rg,,}"]:-}" ]]; then
    echo "  Already scanned via context '${SEEN_RGS["$sub/${node_rg,,}"]}'. Skipping."
    return 0
  fi
  SEEN_RGS["$sub/${node_rg,,}"]="$ctx"

  echo "  Subscription: $sub"
  echo "  Node RG:      $node_rg"

  # 1. K8s PV references. If this fails every disk would look orphaned, so bail out for this cluster.
  local pv_json k8s_pvs
  if ! pv_json=$(kubectl --kubeconfig "$kubeconfig" --context "$ctx" --request-timeout=20s get pv -o json 2>/dev/null); then
    echo "  UNREACHABLE: cannot list PVs. Skipping (results would be false orphans)."
    UNREACHABLE+=("$ctx")
    return 0
  fi
  k8s_pvs=$(jq -r '
    .items[] |
    [
      .metadata.name,
      ((.spec.csi.volumeHandle // "") | split("/") | last),
      (.spec.azureDisk.diskName // "")
    ] | .[] | select(length > 0)' <<<"$pv_json" | tr '[:upper:]' '[:lower:]' | sort -u)

  # 2. Azure pvc-* disks in the node RG
  local disks_json
  disks_json=$(az disk list --subscription "$sub" -g "$node_rg" \
    --query "[?starts_with(name, 'pvc-')].{name:name, id:id, managedBy:managedBy, sizeGb:diskSizeGb, timeCreated:timeCreated}" \
    -o json)

  # 3. Evaluate candidates
  local -a orphans=()
  local disk name id size managed_by created created_epoch age_seconds age_hours
  while read -r disk; do
    [[ -z "$disk" ]] && continue

    name=$(jq -r '.name' <<<"$disk")
    id=$(jq -r '.id' <<<"$disk")
    size=$(jq -r '.sizeGb' <<<"$disk")
    managed_by=$(jq -r '.managedBy' <<<"$disk")
    created=$(jq -r '.timeCreated' <<<"$disk")

    # Rule 1: Must be unattached
    if [[ "$managed_by" != "null" && -n "$managed_by" ]]; then
      continue
    fi

    # Rule 2: Must NOT be referenced by any K8s PV
    if grep -Fxq "${name,,}" <<<"$k8s_pvs"; then
      continue
    fi

    # Rule 3: Must exceed MIN_AGE_HOURS
    created_epoch=$(date -d "$created" +%s 2>/dev/null || echo 0)
    age_seconds=$((NOW_EPOCH - created_epoch))
    age_hours=$((age_seconds / 3600))

    if ((age_seconds < MIN_AGE_SECONDS)); then
      echo "  [SKIPPED] Disk '$name' has no PV, but is only ${age_hours}h old (< ${MIN_AGE_HOURS}h threshold)."
      continue
    fi

    orphans+=("$name|$size|$age_hours|$id")
  done < <(jq -c '.[]' <<<"$disks_json")

  # 4. Report
  local total=${#orphans[@]}
  if [[ $total -eq 0 ]]; then
    echo "  Clean! No orphaned 'pvc-*' disks older than ${MIN_AGE_HOURS}h."
    SUMMARY+=("$ctx|0")
    return 0
  fi

  printf "  %-42s | %-10s | %-10s\n" "ORPHANED DISK NAME" "SIZE" "AGE"
  printf -- "  ----------------------------------------------------------------------\n"
  local item d_name d_size d_age d_id
  for item in "${orphans[@]}"; do
    IFS='|' read -r d_name d_size d_age d_id <<<"$item"
    printf "  %-42s | %-10s | %-10s\n" "$d_name" "${d_size} GiB" "${d_age} hours"
    printf "    https://portal.azure.com/#resource%s\n" "$d_id"
  done
  printf -- "  ----------------------------------------------------------------------\n"
  echo "  Orphaned disks eligible for cleanup: $total"
  SUMMARY+=("$ctx|$total")
  TOTAL_ALL=$((TOTAL_ALL + total))

  # 5. Execution (never on live contexts)
  if [[ "$DRY_RUN" == true ]]; then
    return 0
  fi
  if [[ "$ctx" == *live* ]]; then
    echo "  [REFUSED] '$ctx' is a live context: deletion is never applied to production. Report only."
    return 0
  fi

  echo "  >>> Executing cleanup..."
  for item in "${orphans[@]}"; do
    IFS='|' read -r d_name d_size d_age d_id <<<"$item"

    if [[ "$CREATE_SNAPSHOT" == true ]]; then
      local snapshot="snap-${d_name}-pre-deletion"
      echo "  Creating backup snapshot '$snapshot'..."
      az snapshot create --subscription "$sub" -g "$node_rg" -n "$snapshot" --source "$d_id" -o none
    fi

    echo "  Deleting disk '$d_name'..."
    az disk delete --subscription "$sub" -g "$node_rg" -n "$d_name" --yes --no-wait
  done
}

# --- Loop over every kubeconfig / context ---
for kubeconfig in "${KUBECONFIGS[@]}"; do
  while read -r ctx; do
    [[ -z "$ctx" ]] && continue

    # AKS contexts use the user 'clusterUser_<aks-rg>_<aks-name>'; anything else (aws, kubie, ...) is not scannable
    user=$(kubectl --kubeconfig "$kubeconfig" config view -o json |
      jq -r --arg c "$ctx" '.contexts[] | select(.name == $c) | .context.user')
    if [[ ! "$user" =~ ^clusterUser_(.+)_([^_]+)$ ]]; then
      SKIPPED+=("$ctx (user '$user' is not an AKS clusterUser)")
      continue
    fi

    scan_cluster "$kubeconfig" "$ctx" "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
    echo ""
  done < <(kubectl --kubeconfig "$kubeconfig" config get-contexts -o name)
done

# --- Final summary ---
echo "================================================================="
echo " SUMMARY"
echo "================================================================="
for line in "${SUMMARY[@]:-}"; do
  [[ -z "$line" ]] && continue
  IFS='|' read -r s_ctx s_count <<<"$line"
  printf "  %-40s %s orphaned disks\n" "$s_ctx" "$s_count"
done
echo "  Total orphaned disks: $TOTAL_ALL"

if [[ ${#UNREACHABLE[@]} -gt 0 ]]; then
  echo ""
  echo "WARNING: unreachable clusters (NOT scanned, their disks are unverified):"
  printf '  - %s\n' "${UNREACHABLE[@]}"
fi
if [[ ${#SKIPPED[@]} -gt 0 ]]; then
  echo ""
  echo "Skipped contexts:"
  printf '  - %s\n' "${SKIPPED[@]}"
fi

if [[ "$DRY_RUN" == true ]]; then
  echo ""
  echo "[DRY-RUN COMPLETE] To delete (non-live only), rerun with '--apply' (and optionally '-s' to create snapshots)."
fi
