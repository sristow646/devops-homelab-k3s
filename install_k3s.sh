#!/bin/bash
set -e

# === ENV Variablen laden ===
if [ -f .env ]; then
  echo "🔄 Lade Umgebungsvariablen aus .env..."
  export $(grep -v '^#' .env | xargs)
else
  echo "❌ .env Datei nicht gefunden! Bitte erstellen!"
  exit 1
fi

# === System vorbereiten ===
apt update && apt install -y curl open-iscsi nfs-common bash-completion gnupg2 ca-certificates software-properties-common jq dnsutils
systemctl enable --now iscsid

# === k3s installieren ===
if ! command -v k3s >/dev/null 2>&1; then
  curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik --write-kubeconfig-mode 644" sh -
fi
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# === TLS Secret Handling ===
kubectl get ns certs || kubectl create namespace certs
kubectl -n certs create secret tls wildcard-tls --cert="$TLS_CERT_PATH" --key="$TLS_KEY_PATH" --dry-run=client -o yaml | kubectl apply -f -

for ns in portainer longhorn-system monitoring ingress-nginx; do
  kubectl get ns $ns || kubectl create namespace $ns
  kubectl get secret wildcard-tls -n certs -o yaml | sed "s/namespace: certs/namespace: $ns/" | kubectl apply -f -
done

# === MetalLB ===
helm repo add metallb https://metallb.github.io/metallb || true
helm repo update
helm upgrade --install metallb metallb/metallb --namespace metallb-system --create-namespace

until kubectl -n metallb-system get endpoints metallb-webhook-service -o jsonpath="{.subsets[*].addresses[*].ip}" | grep -q .; do
  sleep 5
done

kubectl apply -f - <<EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: pool
  namespace: metallb-system
spec:
  addresses:
  - ${METALLB_IP_RANGE}
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: advert
  namespace: metallb-system
EOF

# === Ingress Controller ===
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx || true
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --set controller.service.type=LoadBalancer \
  --set controller.extraArgs.default-ssl-certificate="ingress-nginx/wildcard-tls"

# === Portainer ===
helm repo add portainer https://portainer.github.io/k8s/ || true
helm upgrade --install portainer portainer/portainer \
  --namespace portainer \
  --set service.type="ClusterIP" \
  --set ingress.enabled="true" \
  --set ingress.ingressClassName="nginx" \
  --set ingress.hosts[0].host="${PORTAINER_HOST}" \
  --set ingress.tls[0].hosts[0]="${PORTAINER_HOST}" \
  --set ingress.tls[0].secretName="wildcard-tls"

# === Longhorn ===
helm repo add longhorn https://charts.longhorn.io || true
helm upgrade --install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --set defaultSettings.defaultReplicaCount="1" \
  --set ingress.enabled="true" \
  --set ingress.ingressClassName="nginx" \
  --set ingress.host="${LONGHORN_HOST}" \
  --set ingress.tls="true" \
  --set ingress.tlsSecret="wildcard-tls" \
  --set ingress.servicePort="80" \
  --set ingress.annotations."nginx\.ingress\.kubernetes\.io/backend-protocol"="HTTP"

# === Monitoring: Prometheus + Grafana ===
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
helm upgrade --install prometheus prometheus-community/prometheus \
  --namespace monitoring --create-namespace \
  --set server.ingress.enabled="true" \
  --set server.ingress.ingressClassName="nginx" \
  --set server.ingress.hosts[0]="${PROMETHEUS_HOST}" \
  --set server.ingress.tls[0].hosts[0]="${PROMETHEUS_HOST}" \
  --set server.ingress.tls[0].secretName="wildcard-tls"

helm repo add grafana https://grafana.github.io/helm-charts || true
helm upgrade --install grafana grafana/grafana \
  --namespace monitoring \
  --set ingress.enabled="true" \
  --set ingress.ingressClassName="nginx" \
  --set ingress.hosts[0]="${GRAFANA_HOST}" \
  --set ingress.tls[0].hosts[0]="${GRAFANA_HOST}" \
  --set ingress.tls[0].secretName="wildcard-tls" \
  --set adminPassword="${GRAFANA_ADMIN_PASS}" \
  --set datasources."datasources\.yaml".apiVersion=1 \
  --set datasources."datasources\.yaml".datasources[0].name="Prometheus" \
  --set datasources."datasources\.yaml".datasources[0].type="prometheus" \
  --set datasources."datasources\.yaml".datasources[0].url="http://prometheus-server.monitoring.svc.cluster.local" \
  --set datasources."datasources\.yaml".datasources[0].access="proxy" \
  --set datasources."datasources\.yaml".datasources[0].isDefault="true"

# === Abschluss-Info ===
echo ""
echo "🚀 === Setup abgeschlossen! ==="
echo ""
echo "🔗 Deine Services:"
echo "➡ Portainer:   https://${PORTAINER_HOST}"
echo "➡ Longhorn:    https://${LONGHORN_HOST}"
echo "➡ Grafana:     https://${GRAFANA_HOST} | User: admin | PW: ${GRAFANA_ADMIN_PASS}"
echo "➡ Prometheus:  https://${PROMETHEUS_HOST}"
echo "🔒 TLS Secret: wildcard-tls"
echo "💡 LoadBalancer IP Range: ${METALLB_IP_RANGE}"
echo ""
