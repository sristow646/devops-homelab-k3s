#!/bin/bash
set -e

echo "🔍 Starte Cluster-Aware Cleanup..."

# === 1) Prüfen ob k3s Service noch existiert ===
if systemctl list-units --type=service | grep -q k3s; then
  echo "⚠️ k3s läuft noch! Bitte zuerst mit /usr/local/bin/k3s-uninstall.sh deinstallieren."
  exit 1
else
  echo "✅ k3s wurde bereits entfernt."
fi

# === 2) Cluster-API verfügbar? ===
if kubectl version --short >/dev/null 2>&1; then
  CLUSTER_ONLINE=true
  echo "🟢 Cluster API erreichbar."
else
  CLUSTER_ONLINE=false
  echo "🔴 Cluster API nicht erreichbar, arbeite im „offline mode“ (nur Verzeichnisse + Helm-Cache)."
fi

# === 3) Verzeichnisse bereinigen ===
for dir in /etc/rancher /var/lib/rancher /var/lib/kubelet /var/lib/longhorn /var/log/containers /var/log/pods; do
  if [ -d "$dir" ]; then
    echo "🗑️ Entferne Verzeichnis: $dir"
    rm -rf "$dir"
  else
    echo "✅ Kein Verzeichnis gefunden: $dir"
  fi
done

# === 4) Helm Releases deinstallieren ===
echo "🔄 Helm Releases deinstallieren..."

RELEASES=("metallb" "ingress-nginx" "portainer" "longhorn" "prometheus" "grafana")
for rel in "${RELEASES[@]}"; do
  ns=$(helm list -A | grep "$rel" | awk '{print $2}' | head -n1)
  if [ -n "$ns" ]; then
    echo "🗑️ Helm uninstall: $rel (Namespace: $ns)"
    if [ "$CLUSTER_ONLINE" = true ]; then
      helm uninstall "$rel" -n "$ns" || true
    else
      echo "⚠️ Cluster offline, überspringe Helm uninstall für $rel."
    fi
  else
    echo "✅ Helm Release $rel nicht vorhanden."
  fi
done

# === 5) Kubernetes-Ressourcen nur wenn Cluster online ===
if [ "$CLUSTER_ONLINE" = true ]; then
  echo "🔄 Entferne Cluster-Namespaces..."
  NAMESPACES=("metallb-system" "ingress-nginx" "portainer" "longhorn-system" "cattle-monitoring-system" "certs")
  for ns in "${NAMESPACES[@]}"; do
    if kubectl get ns "$ns" >/dev/null 2>&1; then
      echo "🗑️ Lösche Namespace: $ns"
      kubectl delete ns "$ns" --ignore-not-found
    else
      echo "✅ Namespace $ns existiert nicht mehr."
    fi
  done

  echo "🔄 Prüfe auf Longhorn CRDs..."
  kubectl get crd | grep -E "longhorn" | awk '{print $1}' | while read crd; do
    echo "🗑️ Lösche CRD: $crd"
    kubectl delete crd "$crd" --ignore-not-found
  done
else
  echo "⚠️ Cluster offline: Namespace- und CRD-Löschung übersprungen."
fi

# === 6) Helm Cache anzeigen ===
echo "📦 Lokale Helm Releases im Cache:"
helm list -A || echo "Keine lokalen Releases."

echo "✅ Cleanup abgeschlossen!"
