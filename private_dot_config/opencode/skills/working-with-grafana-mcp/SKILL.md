---
name: working-with-grafana-mcp
description: Use when querying Grafana dashboards, Prometheus metrics, Loki logs, alerting, or incidents - provides workflows and patterns for Grafana MCP tools including datasource discovery, efficient dashboard access, and query construction
---

# Working with Grafana MCP

## Overview

Grafana MCP provides tools for observability: dashboards, metrics (Prometheus), logs (Loki), alerting, and incident management. **Always start with datasource discovery** - most queries require a datasource UID.

## Core Workflow

```
1. list_datasources → Find datasource UID
2. Use datasource-specific tools with that UID
```

## Quick Reference

| Task | Tool(s) | Notes |
|------|---------|-------|
| Find datasources | `list_datasources` | Filter by type: 'prometheus', 'loki' |
| Search dashboards | `search_dashboards` | Returns UID, title, folder |
| Dashboard overview | `get_dashboard_summary` | Lightweight - use first |
| Specific dashboard data | `get_dashboard_property` | JSONPath: `$.panels[*].title` |
| Full dashboard JSON | `get_dashboard_by_uid` | Heavy - use sparingly |
| Query metrics | `query_prometheus` | Needs datasource UID |
| Query logs | `query_loki_logs` | LogQL syntax |
| List alerts | `list_alert_rules` | Grafana-managed by default |
| Current incidents | `list_incidents` | Filter by status |

## Datasource Discovery

**Always first step** - most operations need a datasource UID:

```
# Find all Prometheus datasources
grafana_list_datasources(type="prometheus")

# Find Loki datasources
grafana_list_datasources(type="loki")
```

Returns: `id`, `uid`, `name`, `type`, `isDefault`

## Dashboard Access (Context-Efficient)

**Prefer lightweight tools:**

| Need | Use | Avoid |
|------|-----|-------|
| Dashboard exists? | `search_dashboards` | - |
| Panel count, types | `get_dashboard_summary` | `get_dashboard_by_uid` |
| Panel titles | `get_dashboard_property` with `$.panels[*].title` | `get_dashboard_by_uid` |
| Single panel | `get_dashboard_property` with `$.panels[0]` | `get_dashboard_by_uid` |
| Panel queries | `get_dashboard_panel_queries` | `get_dashboard_by_uid` |
| Full JSON | `get_dashboard_by_uid` | - |

**JSONPath examples:**
- `$.title` - Dashboard title
- `$.panels[*].title` - All panel titles
- `$.panels[0].targets[0].expr` - First panel's query
- `$.templating.list` - Template variables

## Prometheus Queries

```python
# Instant query (single point)
grafana_query_prometheus(
    datasourceUid="PROM_UID",
    expr="up{job='myapp'}",
    startTime="now",
    queryType="instant"
)

# Range query (time series)
grafana_query_prometheus(
    datasourceUid="PROM_UID",
    expr="rate(http_requests_total[5m])",
    startTime="now-1h",
    endTime="now",
    stepSeconds=60,
    queryType="range"
)
```

**Time formats:** RFC3339 or relative (`now`, `now-1h`, `now-30m`)

**Discover metrics:**
```python
# List metric names
grafana_list_prometheus_metric_names(datasourceUid="UID", regex="http.*")

# List label names
grafana_list_prometheus_label_names(datasourceUid="UID")

# List label values
grafana_list_prometheus_label_values(datasourceUid="UID", labelName="job")
```

## Loki Log Queries

```python
# Simple label query
grafana_query_loki_logs(
    datasourceUid="LOKI_UID",
    logql='{app="myapp"}',
    limit=50
)

# With filter
grafana_query_loki_logs(
    datasourceUid="LOKI_UID",
    logql='{app="myapp"} |= "error"',
    startRfc3339="2025-01-01T00:00:00Z",
    endRfc3339="2025-01-01T01:00:00Z"
)
```

**LogQL patterns:**
- `{label="value"}` - Label selector
- `|= "text"` - Line contains
- `!= "text"` - Line does not contain
- `|~ "regex"` - Regex match
- `| json` - Parse JSON
- `| logfmt` - Parse logfmt

**Check stream size first:**
```python
grafana_query_loki_stats(datasourceUid="UID", logql='{app="myapp"}')
# Returns: streams, chunks, entries, bytes
```

## Alerting

**List alerts:**
```python
grafana_list_alert_rules()  # Grafana-managed

# With label filter
grafana_list_alert_rules(
    label_selectors=[{"filters": [
        {"name": "severity", "type": "=", "value": "critical"}
    ]}]
)
```

**Create alert rule:**
```python
grafana_create_alert_rule(
    title="High CPU Usage",
    ruleGroup="cpu-alerts",
    folderUID="alert-folder",
    condition="B",  # Reference to reducer
    data=[
        {
            "refId": "A",
            "datasourceUid": "PROM_UID",
            "model": {
                "expr": "avg(cpu_usage) > 80",
                "intervalMs": 1000,
                "maxDataPoints": 43200
            }
        },
        {
            "refId": "B",
            "datasourceUid": "__expr__",
            "model": {
                "type": "reduce",
                "expression": "A",
                "reducer": "last"
            }
        }
    ],
    noDataState="NoData",
    execErrState="Alerting",
    for_="5m",
    orgID=1
)
```

## Incidents & OnCall

```python
# List active incidents
grafana_list_incidents(status="active")

# Get incident details
grafana_get_incident(id="incident-id")

# Who's on call?
grafana_list_oncall_schedules()
grafana_get_current_oncall_users(scheduleId="schedule-id")
```

## Dashboard Updates

**Prefer patch operations for small changes:**
```python
grafana_update_dashboard(
    uid="dashboard-uid",
    operations=[
        {"op": "replace", "path": "$.title", "value": "New Title"},
        {"op": "replace", "path": "$.panels[0].title", "value": "Panel 1"}
    ],
    message="Updated titles"
)
```

**Append to arrays:**
- `$.panels/-` - Append to panels array
- `$.panels[2]/-` - Append to nested array

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Query without datasource UID | Always `list_datasources` first |
| `get_dashboard_by_uid` for simple info | Use `get_dashboard_summary` or `get_dashboard_property` |
| Loki query without checking size | Use `query_loki_stats` first for large ranges |
| Missing `queryType` in Prometheus | Specify `instant` or `range` |
| Alert without proper condition chain | Need query (A) → reducer (B) → condition references B |

## Investigation Tools

For troubleshooting, Grafana provides analysis tools:

```python
# Find error patterns in logs
grafana_find_error_pattern_logs(
    name="App Errors Investigation",
    labels={"app": "myapp"}
)

# Find slow requests
grafana_find_slow_requests(
    name="Slow API Investigation",
    labels={"service": "api"}
)
```
