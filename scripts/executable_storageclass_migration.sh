#!/usr/bin/env bash
set -eo pipefail

LOG_FILE="$HOME/Storageclass_Migration"
TAG_KEY="technosylva.io-data_criticality"
DEFAULT_GRACE_PERIOD="${GRACE_PERIOD_SECONDS:-60}"

# 1. Validar herramientas requeridas
for cmd in kubectl jq az; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "[ERROR] El comando '$cmd' no está instalado o no se encuentra en el PATH."
    exit 1
  fi
done

echo "=== Cargando configuración de entorno ==="

# 2. Azure Subscription & Tenant
AZ_SUB_ID="${AZURE_SUBSCRIPTION_ID:-${ARM_SUBSCRIPTION_ID:-${SUBSCRIPTION_ID:-}}}"
AZ_TENANT_ID="${AZURE_TENANT_ID:-${ARM_TENANT_ID:-${TENANT_ID:-}}}"

if [[ -z "$AZ_SUB_ID" || -z "$AZ_TENANT_ID" ]]; then
  if az account show &>/dev/null; then
    [[ -z "$AZ_SUB_ID" ]] && AZ_SUB_ID=$(az account show --query id -o tsv)
    [[ -z "$AZ_TENANT_ID" ]] && AZ_TENANT_ID=$(az account show --query tenantId -o tsv)
  else
    echo "[ERROR] Variables de Azure no encontradas y sesión CLI no activa."
    exit 1
  fi
fi

echo "  Tenant ID:       $AZ_TENANT_ID"
echo "  Subscription ID: $AZ_SUB_ID"

# 3. Detección del clúster AKS
AKS_CLUSTER_RESOURCE_ID="${AKS_CLUSTER_RESOURCE_ID:-${CLUSTER_RESOURCE_ID:-}}"
CLUSTER_NAME="${AKS_CLUSTER_NAME:-${CLUSTER_NAME:-${AKS_NAME:-}}}"
RESOURCE_GROUP="${AZURE_RESOURCE_GROUP:-${ARM_RESOURCE_GROUP:-${RESOURCE_GROUP:-${RG:-}}}}"

if [[ -z "$AKS_CLUSTER_RESOURCE_ID" && -n "$RESOURCE_GROUP" && -n "$CLUSTER_NAME" ]]; then
  AKS_CLUSTER_RESOURCE_ID="/subscriptions/${AZ_SUB_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ContainerService/managedClusters/${CLUSTER_NAME}"
fi

# Fallback si no está configurado por variables
if [[ -z "$AKS_CLUSTER_RESOURCE_ID" ]]; then
  API_FQDN=$(kubectl cluster-info 2>/dev/null | grep -Eo 'https://[^ :]+' | head -n 1 | sed -E 's|https://([^:/]+).*|\1|' || true)
  if [[ -n "$API_FQDN" ]]; then
    AKS_CLUSTER_RESOURCE_ID=$(az aks list --query "[?fqdn=='${API_FQDN}' || privateFqdn=='${API_FQDN}'].id | [0]" -o tsv 2>/dev/null || true)
  fi

  if [[ -z "$AKS_CLUSTER_RESOURCE_ID" || "$AKS_CLUSTER_RESOURCE_ID" == "null" ]]; then
    CTX_NAME=$(kubectl config current-context 2>/dev/null || true)
    if [[ -n "$CTX_NAME" ]]; then
      CLEAN_CTX=$(echo "$CTX_NAME" | sed -E 's/(_admin|-admin)$//')
      AKS_CLUSTER_RESOURCE_ID=$(az aks list --query "[?contains(name, '${CLEAN_CTX}')].id | [0]" -o tsv 2>/dev/null || true)
    fi
  fi
fi

if [[ -n "$AKS_CLUSTER_RESOURCE_ID" && "$AKS_CLUSTER_RESOURCE_ID" != "null" ]]; then
  echo "  AKS Cluster ID:  $AKS_CLUSTER_RESOURCE_ID"
fi

# 4. Resolver Namespace
NAMESPACE="${1:-${NAMESPACE:-${KUBE_NAMESPACE:-}}}"
if [[ -z "$NAMESPACE" ]]; then
  read -rp "Introduce el namespace de Kubernetes a procesar: " NAMESPACE
fi

# 5. Inicializar log
if [[ ! -f "$LOG_FILE" ]]; then
  echo "# StorageClass Migration & ReclaimPolicy Audit Log" >"$LOG_FILE"
  echo "# Fecha: $(date -u +"%Y-%m-%d %H:%M:%SZ") | Sub: $AZ_SUB_ID" >>"$LOG_FILE"
  echo "# ----------------------------------------------------------------" >>"$LOG_FILE"
fi

registrar_en_archivo() {
  local pv_name="$1" pvc_name="$2" ns="$3" orig_policy="$4" tag_value="$5"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%d %H:%M:%SZ")

  cat <<EOF >>"$LOG_FILE"

[${timestamp}]
PV:                ${pv_name}
PVC Original:      ${pvc_name}
Namespace:         ${ns}
Politica Anterior: ${orig_policy}
Politica Final:    ${orig_policy}
Data Criticality:  ${tag_value}
Azure Sub ID:      ${AZ_SUB_ID}
----------------------------------------------------------------
EOF
  echo "  [Auditoría] Registro añadido a: $LOG_FILE"
}

# 6. Iterar PVCs en el namespace
echo ""
echo "=== Obteniendo PVCs en namespace: $NAMESPACE ==="
PVC_LIST=$(kubectl get pvc -n "$NAMESPACE" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')

if [[ -z "$PVC_LIST" ]]; then
  echo "No se encontraron PVCs en '$NAMESPACE'."
  exit 0
fi

for PVC in $PVC_LIST; do
  echo "------------------------------------------------------------------"
  echo "Procesando PVC: $PVC (Namespace: $NAMESPACE)"

  PVC_JSON=$(kubectl get pvc "$PVC" -n "$NAMESPACE" -o json 2>/dev/null || true)
  if [[ -z "$PVC_JSON" ]]; then
    echo "  [SKIP] El PVC '$PVC' no existe o ya fue procesado."
    continue
  fi

  PV_NAME=$(echo "$PVC_JSON" | jq -r '.spec.volumeName // empty')
  if [[ -z "$PV_NAME" ]]; then
    echo "  [SKIP] El PVC '$PVC' no está vinculado a ningún PV."
    continue
  fi

  echo "  PV asociado: $PV_NAME"
  PV_JSON=$(kubectl get pv "$PV_NAME" -o json)

  # Enlace directo al recurso de Azure (Disco / Volumen) AL PRINCIPIO
  AZURE_VOLUME_HANDLE=$(echo "$PV_JSON" | jq -r '
    .spec.csi.volumeHandle // 
    .spec.azureDisk.diskURI // 
    empty
  ')

  AZURE_RESOURCE_ID=""
  if [[ "$AZURE_VOLUME_HANDLE" == /subscriptions/* ]]; then
    AZURE_RESOURCE_ID="$AZURE_VOLUME_HANDLE"
  elif [[ -n "$AZURE_VOLUME_HANDLE" ]]; then
    AZURE_RESOURCE_ID=$(az resource list --query "[?name=='${AZURE_VOLUME_HANDLE}'].id | [0]" -o tsv 2>/dev/null || true)
  fi

  if [[ -n "$AZURE_RESOURCE_ID" && "$AZURE_RESOURCE_ID" != "null" ]]; then
    echo "  🔗 Link Azure (Disco / Volumen en Azure Portal):"
    echo "     https://portal.azure.com/#@${AZ_TENANT_ID}/resource${AZURE_RESOURCE_ID}"
  else
    echo "  ℹ️  Identificador Azure nativo: ${AZURE_VOLUME_HANDLE:-No resuelto}"
  fi

  ORIGINAL_RECLAIM_POLICY=$(echo "$PV_JSON" | jq -r '.spec.persistentVolumeReclaimPolicy')
  echo "  Política de retención inicial: $ORIGINAL_RECLAIM_POLICY"

  CURRENT_SC=$(echo "$PV_JSON" | jq -r '.spec.storageClassName // "none"')
  echo "  StorageClass actual en PV: $CURRENT_SC"
  read -rp "  Introduce la NUEVA StorageClass para $PV_NAME: " NUEVA_SC

  if [[ -z "$NUEVA_SC" ]]; then
    echo "  [SKIP] No se indicó StorageClass. Omitiendo este PVC."
    continue
  fi

  # Derivar tag a partir del nombre de la StorageClass
  if [[ "$NUEVA_SC" =~ managed-csi-(.+) ]]; then
    CRITICALITY_TAG="${BASH_REMATCH[1]}"
  else
    CRITICALITY_TAG="${NUEVA_SC##*-}"
  fi
  echo "  Tag derivado: $TAG_KEY = $CRITICALITY_TAG"

  # Asegurar política Retain durante la operación
  POLICY_WAS_CHANGED=false
  if [[ "$ORIGINAL_RECLAIM_POLICY" != "Retain" ]]; then
    read -rp "  La política es '$ORIGINAL_RECLAIM_POLICY'. ¿Cambiar temporalmente a 'Retain' para proteger los datos? (s/n): " CAMBIAR_POLITICA
    if [[ "$CAMBIAR_POLITICA" =~ ^[sSyY]$ ]]; then
      kubectl patch pv "$PV_NAME" -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
      echo "  [OK] Política cambiada temporalmente a 'Retain'."
      POLICY_WAS_CHANGED=true
      registrar_en_archivo "$PV_NAME" "$PVC" "$NAMESPACE" "$ORIGINAL_RECLAIM_POLICY" "$CRITICALITY_TAG"
    else
      echo "  [SKIP] Omitiendo $PVC para evitar eliminación accidental de datos."
      continue
    fi
  else
    echo "  [OK] La política ya es 'Retain'."
  fi

  # Identificar si un Pod está montando este PVC
  TARGET_POD=$(kubectl get pods -n "$NAMESPACE" -o json | jq -r --arg pvc "$PVC" '.items[] | select(.spec.volumes[]?.persistentVolumeClaim.claimName == $pvc) | .metadata.name' | head -n 1)

  IS_STATEFULSET=false
  STS_NAME=""
  STS_BACKUP_FILE=""

  if [[ -n "$TARGET_POD" ]]; then
    echo "  Pod activo montando el volumen: $TARGET_POD"
    OWNER_KIND=$(kubectl get pod "$TARGET_POD" -n "$NAMESPACE" -o json | jq -r '.metadata.ownerReferences[0].kind // empty')
    OWNER_NAME=$(kubectl get pod "$TARGET_POD" -n "$NAMESPACE" -o json | jq -r '.metadata.ownerReferences[0].name // empty')

    if [[ "$OWNER_KIND" == "StatefulSet" ]]; then
      IS_STATEFULSET=true
      STS_NAME="$OWNER_NAME"
      STS_BACKUP_FILE="/tmp/sts_${NAMESPACE}_${STS_NAME}.json"

      POD_GRACE_PERIOD=$(kubectl get pod "$TARGET_POD" -n "$NAMESPACE" -o jsonpath='{.spec.terminationGracePeriodSeconds}' 2>/dev/null || true)
      if [[ -z "$POD_GRACE_PERIOD" || "$POD_GRACE_PERIOD" -le 0 ]]; then
        POD_GRACE_PERIOD="$DEFAULT_GRACE_PERIOD"
      fi

      echo "  [Zero-Downtime STS] Guardando definición del StatefulSet '$STS_NAME'..."
      kubectl get sts "$STS_NAME" -n "$NAMESPACE" -o json | jq '
        del(.status, 
            .metadata.resourceVersion, 
            .metadata.uid, 
            .metadata.creationTimestamp, 
            .metadata.generation,
            .metadata.managedFields)
      ' >"$STS_BACKUP_FILE"

      echo "  [Zero-Downtime STS] Orfanando StatefulSet '$STS_NAME' (los demás pods siguen activos)..."
      kubectl delete sts "$STS_NAME" -n "$NAMESPACE" --cascade=orphan

      echo "  [Zero-Downtime STS] Iniciando graceful shutdown de '$TARGET_POD' (período de gracia: ${POD_GRACE_PERIOD}s)..."
      echo "                      Permitiendo drenar llamadas y conexiones activas..."
      kubectl delete pod "$TARGET_POD" -n "$NAMESPACE" --grace-period="$POD_GRACE_PERIOD" --wait=true

      echo "  [Zero-Downtime STS] Pod terminado. Esperando 5s para el desmonte completo del volumen en Azure..."
      sleep 5
    fi
  fi

  ACCESS_MODES=$(echo "$PVC_JSON" | jq -c '.spec.accessModes')
  STORAGE_REQ=$(echo "$PVC_JSON" | jq -r '.spec.resources.requests.storage')

  echo "  Eliminando PVC original '$PVC' (datos físicos protegidos en el PV)..."
  kubectl delete pvc "$PVC" -n "$NAMESPACE"

  echo "  Desvinculando PV (limpiando claimRef)..."
  kubectl patch pv "$PV_NAME" -p '{"spec":{"claimRef": null}}'

  echo "  Actualizando StorageClass en el PV a '$NUEVA_SC'..."
  kubectl patch pv "$PV_NAME" -p "{\"spec\":{\"storageClassName\":\"$NUEVA_SC\"}}"

  echo "  Recreando PVC '$PVC' con enlace estático a $PV_NAME..."
  cat <<EOF | kubectl create -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: $PVC
  namespace: $NAMESPACE
spec:
  accessModes: $ACCESS_MODES
  storageClassName: $NUEVA_SC
  volumeName: $PV_NAME
  resources:
    requests:
      storage: $STORAGE_REQ
EOF

  # Restaurar la política de retención original del PV
  if [[ "$POLICY_WAS_CHANGED" = true ]]; then
    echo "  Restaurando política de retención original ('$ORIGINAL_RECLAIM_POLICY') en el PV..."
    kubectl patch pv "$PV_NAME" -p "{\"spec\":{\"persistentVolumeReclaimPolicy\":\"$ORIGINAL_RECLAIM_POLICY\"}}"
    echo "  [OK] ReclaimPolicy restaurada a: $ORIGINAL_RECLAIM_POLICY"
  fi

  # Restaurar el StatefulSet para volver a levantar únicamente el pod migrado
  if [[ "$IS_STATEFULSET" = true && -f "$STS_BACKUP_FILE" ]]; then
    echo "  [Zero-Downtime STS] Reaplicando StatefulSet '$STS_NAME'..."
    kubectl apply -f "$STS_BACKUP_FILE"

    echo "  [Zero-Downtime STS] Esperando a que '$TARGET_POD' vuelva a estar en estado 'Ready'..."
    kubectl wait --for=condition=Ready "pod/$TARGET_POD" -n "$NAMESPACE" --timeout=300s || {
      echo "  [AVISO] El pod '$TARGET_POD' aún no está en estado Ready tras 300s. Verifica con: kubectl describe pod $TARGET_POD -n $NAMESPACE"
    }
    rm -f "$STS_BACKUP_FILE"
  fi

  # Verificación final: comprobar que el pod recreado tiene asignado el mismo PVC
  if [[ -n "$TARGET_POD" ]]; then
    echo "  [Comprobación] Verificando asignación del PVC en '$TARGET_POD'..."
    ASSIGNED_PVCS=$(kubectl get pod "$TARGET_POD" -n "$NAMESPACE" -o json 2>/dev/null | jq -r '.spec.volumes[]?.persistentVolumeClaim.claimName // empty')

    if echo "$ASSIGNED_PVCS" | grep -qx "$PVC"; then
      echo "  ✅ [OK] El pod '$TARGET_POD' tiene montado y asignado el PVC correcto: $PVC"
    else
      echo "  ❌ [ERROR] El pod '$TARGET_POD' NO tiene asignado el PVC esperado ($PVC)."
      echo "     PVCs detectados en el pod: ${ASSIGNED_PVCS:-ninguno}"
    fi
  fi

  # Actualizar tags en el recurso subyacente de Azure
  if [[ -n "$AZURE_RESOURCE_ID" && "$AZURE_RESOURCE_ID" != "null" ]]; then
    echo "  Aplicando tag en Azure ($TAG_KEY = $CRITICALITY_TAG)..."
    az tag update \
      --resource-id "$AZURE_RESOURCE_ID" \
      --operation Merge \
      --tags "${TAG_KEY}=${CRITICALITY_TAG}" -o none 2>/dev/null || true
  fi

  # Enlaces finales tras completar el ciclo
  echo ""
  echo "=== Enlaces de seguimiento para $PVC / $PV_NAME ==="
  if [[ -n "$AZURE_RESOURCE_ID" && "$AZURE_RESOURCE_ID" != "null" ]]; then
    echo "  🔗 Azure Disk: https://portal.azure.com/#@${AZ_TENANT_ID}/resource${AZURE_RESOURCE_ID}"
  fi
  if [[ -n "$AKS_CLUSTER_RESOURCE_ID" && "$AKS_CLUSTER_RESOURCE_ID" != "null" ]]; then
    echo "  🔗 PVC en Portal: https://portal.azure.com/#@${AZ_TENANT_ID}/view/Microsoft_Azure_ContainerService/WorkloadResourceMenuBlade/~/overview/resourceId/${AKS_CLUSTER_RESOURCE_ID}/namespace/${NAMESPACE}/kind/PersistentVolumeClaim/name/${PVC}"
  fi
  echo ""
done

echo "Migración completada con éxito para el namespace '$NAMESPACE'."
