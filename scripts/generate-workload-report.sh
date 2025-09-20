#!/bin/bash
# This script generates a Markdown report of all Deployments and StatefulSets.

set -e

echo "# Workload Inventory"
echo ""
echo "Generated on: $(date)"
echo ""

for ns in $(kubectl get ns -o jsonpath='{.items[*].metadata.name}'); do
  # Check for Deployments in the namespace
  deployments=$(kubectl get deploy -n "${ns}" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
  if [ -n "$deployments" ]; then
    echo "## Namespace: \`${ns}\`"
    echo ""
    echo "### Deployments"
    echo ""
    echo "| Deployment Name | Replicas (Ready/Desired) | Image(s) |"
    echo "|---|---|---|"
    kubectl get deploy -n "${ns}" -o json | jq -r '.items[] | "| `\(.metadata.name)` | \(.status.readyReplicas // 0)/\(.spec.replicas) | `\(.spec.template.spec.containers | map(.image) | join("<br>"))` |"'
    echo ""
  fi

  # Check for StatefulSets in the namespace
  statefulsets=$(kubectl get sts -n "${ns}" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
  if [ -n "$statefulsets" ]; then
    # Print namespace header only if not already printed
    if [ -z "$deployments" ]; then
      echo "## Namespace: \`${ns}\`"
      echo ""
    fi
    echo "### StatefulSets"
    echo ""
    echo "| StatefulSet Name | Replicas (Ready/Desired) | Image(s) |"
    echo "|---|---|---|"
    kubectl get sts -n "${ns}" -o json | jq -r '.items[] | "| `\(.metadata.name)` | \(.status.readyReplicas // 0)/\(.spec.replicas) | `\(.spec.template.spec.containers | map(.image) | join("<br>"))` |"'
    echo ""
  fi
done
