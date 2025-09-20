#!/bin/bash
# This script generates a Markdown report of all Ingress resources.

set -e

echo "# Ingress Inventory"
echo ""
echo "This report documents how services are exposed to the internet via Ingress."
echo ""
echo "Generated on: $(date)"
echo ""

for ns in $(kubectl get ns -o jsonpath='{.items[*].metadata.name}'); do
  ingresses=$(kubectl get ingress -n "${ns}" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
  if [ -n "$ingresses" ]; then
    echo "## Namespace: \`${ns}\`"
    echo ""
    echo "| Ingress Name | Host | Path | Backend Service | Port |"
    echo "|---|---|---|---|---|"
    kubectl get ingress -n "${ns}" -o json | jq -r '.items[] | . as $parent | .spec.rules[] | . as $rule | .http.paths[] | "| `\($parent.metadata.name)` | `\($rule.host)` | `\(.path // "/")` | `\((.backend.service.name) // "N/A")` | `\((.backend.service.port.number) // "N/A")` |"'
    echo ""
  fi
done

