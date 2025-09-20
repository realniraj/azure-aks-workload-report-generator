#!/bin/bash
# This script generates a Markdown report of all NetworkPolicy resources.

set -e

echo "# Network Policy Inventory"
echo ""
echo "This report documents the intra-cluster network security rules."
echo ""
echo "Generated on: $(date)"
echo ""

for ns in $(kubectl get ns -o jsonpath='{.items[*].metadata.name}'); do
  policies=$(kubectl get netpol -n "${ns}" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
  if [ -n "$policies" ]; then
    echo "## Namespace: \`${ns}\`"
    echo ""
    
    for policy in $policies; do
      echo "### Policy: \`${policy}\`"
      echo ""
      
      # Get the raw YAML for detailed parsing
      policy_yaml=$(kubectl get netpol "${policy}" -n "${ns}" -o yaml)
      
      # Pod Selector
      pod_selector_json=$(echo "${policy_yaml}" | yq -r '.spec.podSelector | to_json')
      if [ "$pod_selector_json" == "null" ] || [ "$pod_selector_json" == "{}" ]; then
        pod_selector="All Pods in Namespace"
      else
        pod_selector="$pod_selector_json"
      fi
      echo "**Applies to Pods:** \`$pod_selector\`"
      echo ""
      
      # Ingress Rules
      echo "**Ingress Rules (Allow Incoming From):**"
      ingress_ip=$(echo "${policy_yaml}" | yq -r '.spec.ingress[]?.from[]? | .ipBlock | select(.!=null) | "- IP Block: " + to_json')
      ingress_ns=$(echo "${policy_yaml}" | yq -r '.spec.ingress[]?.from[]? | .namespaceSelector | select(.!=null) | "- Namespace Selector: " + to_json')
      ingress_pod=$(echo "${policy_yaml}" | yq -r '.spec.ingress[]?.from[]? | .podSelector | select(.!=null) | "- Pod Selector: " + to_json')
      ingress_rules=$(printf "%s\n%s\n%s" "$ingress_ip" "$ingress_ns" "$ingress_pod" | sed '/^[[:space:]]*$/d' | sed 's/^/  /')
      if [ -z "$ingress_rules" ]; then
        echo "  - No ingress rules defined (or default deny if policyType is Ingress)."
      else
        echo "${ingress_rules}"
      fi
      echo ""

      # Egress Rules
      echo "**Egress Rules (Allow Outgoing To):**"
      egress_ip=$(echo "${policy_yaml}" | yq -r '.spec.egress[]?.to[]? | .ipBlock | select(.!=null) | "- IP Block: " + to_json')
      egress_ns=$(echo "${policy_yaml}" | yq -r '.spec.egress[]?.to[]? | .namespaceSelector | select(.!=null) | "- Namespace Selector: " + to_json')
      egress_pod=$(echo "${policy_yaml}" | yq -r '.spec.egress[]?.to[]? | .podSelector | select(.!=null) | "- Pod Selector: " + to_json')
      egress_rules=$(printf "%s\n%s\n%s" "$egress_ip" "$egress_ns" "$egress_pod" | sed '/^[[:space:]]*$/d' | sed 's/^/  /')
      if [ -z "$egress_rules" ]; then
        echo "  - No egress rules defined (or default deny if policyType is Egress)."
      else
        echo "${egress_rules}"
      fi
      echo "---"
    done
  fi
done
