#!/usr/bin/env bash
set -euo pipefail

echo "🔍 Audit Kubernetes : Deployments + StatefulSets"
echo "Namespace, Kind, Name, Container, MissingRequests, MissingLimits, RunAsRoot, PrivEscAllowed, NoCapsDrop, SA_AutoMount" 

RESOURCES=$(kubectl get deploy,statefulset --all-namespaces -o json)

# Parse with jq
echo "$RESOURCES" | jq -r '
  .items[] |
  {
    ns: .metadata.namespace,
    kind: .kind,
    name: .metadata.name,
    saAuto: (if (.spec.template.spec.automountServiceAccountToken == false) then "OK" else "YES" end),
    containers: .spec.template.spec.containers
  }
  | .containers[] as $c
  | {
      ns: .ns,
      kind: .kind,
      name: .name,
      container: $c.name,
      requests: ($c.resources.requests // {}),
      limits: ($c.resources.limits // {}),
      sc: ($c.securityContext // {}),
      saAuto: .saAuto
    }
  | {
      ns,
      kind,
      name,
      container,
      missReq: (if (.requests.cpu == null or .requests.memory == null) then "YES" else "OK" end),
      missLim: (if (.limits.cpu == null or .limits.memory == null) then "YES" else "OK" end),
      runAsRoot: (
        if (.sc.runAsNonRoot == true) then "OK"
        else "ROOT"
        end
      ),
      privEsc: (
        if (.sc.allowPrivilegeEscalation == false) then "OK"
        else "YES"
        end
      ),
      noCaps: (
        if (.sc.capabilities.drop // [] | index("ALL")) then "OK"
        else "NO"
        end
      ),
      saAuto: .saAuto
    }
  | "\(.ns),\(.kind),\(.name),\(.container),\(.missReq),\(.missLim),\(.runAsRoot),\(.privEsc),\(.noCaps),\(.saAuto)"
'
