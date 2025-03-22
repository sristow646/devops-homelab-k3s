#!/bin/bash
set +e

# Farbdefinitionen
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

# === ENV Variablen laden ===
if [ -f .env ]; then
  echo -e "${YELLOW}🔄 Lade Umgebungsvariablen aus .env...${RESET}"
  set -o allexport
  source .env
  set +o allexport
else
  echo -e "${RED}❌ .env Datei nicht gefunden! Bitte erstellen!${RESET}"
  exit 1
fi

# === Preflight Check für Ingress Hosts ===
REQUIRED_VARS=("PORTAINER_HOST" "LONGHORN_HOST" "GRAFANA_HOST" "PROMETHEUS_HOST")
MISSING=0

for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var}" ]; then
    echo -e "${RED}❌ Fehler: ${var} ist nicht gesetzt in .env${RESET}"
    MISSING=1
  fi
  if [[ ! ${!var} =~ ^[a-z0-9]([a-z0-9\-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9\-]*[a-z0-9])?)*$ ]]; then
    echo -e "${RED}❌ Fehler: ${var} hat keinen gültigen RFC 1123 Domain-Namen: '${!var}'${RESET}"
    MISSING=1
  fi
done

if [ $MISSING -eq 1 ]; then
  echo -e "${RED}❌ Abbruch wegen ungültiger oder fehlender Ingress Domains.${RESET}"
  exit 1
else
  echo -e "${GREEN}✅ Alle Ingress-Hosts valide!${RESET}"
fi

# === System vorbereiten ===
apt update && apt install -y curl open-iscsi nfs-common bash-completion gnupg2 ca-certificates software-properties-common jq dnsutils
systemctl enable --now iscsid

# === k3s installieren ===
if ! command -v k3s >/dev/null 2>&1; then
  echo -e "${YELLOW}🚀 Installiere k3s...${RESET}"
  curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik --write-kubeconfig-mode 644" sh -
fi
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# === TLS Ursprungs-Secret ===
kubectl get ns certs || kubectl create namespace certs
kubectl -n certs create secret tls wildcard-tls --cert="$TLS_CERT_PATH" --key="$TLS_KEY_PATH" --dry-run=client -o yaml | kubectl apply -f -

# === Namespace Preflight & TLS Distribution ===
for ns in ingress-nginx portainer longhorn-system monitoring; do
  kubectl get ns $ns >/dev/null 2>&1 || kubectl create namespace $ns
  kubectl get secret wildcard-tls -n certs -o yaml | sed "s/namespace: certs/namespace: $ns/" | kubectl apply -f -
done

# === Helm Deployments ===
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx || true
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --set controller.service.type=LoadBalancer \
  --set controller.extraArgs.default-ssl-certificate="ingress-nginx/wildcard-tls"

# === Warte auf Admission Webhook von Ingress-NGINX ===
echo "⏳ Warte auf ingress-nginx admission webhook..."
kubectl rollout status deployment ingress-nginx-controller -n ingress-nginx --timeout=120s
until kubectl get endpoints ingress-nginx-controller-admission -n ingress-nginx -o jsonpath='{.subsets[*].addresses[*].ip}' | grep -q .; do
  echo "⏳ Webhook Endpoint noch nicht bereit, warte 5s..."
  sleep 5
done

echo "✅ Admission Webhook bereit!"

helm upgrade --install portainer portainer/portainer \
  --namespace portainer \
  --set service.type="ClusterIP" \
  --set ingress.enabled="true" \
  --set ingress.ingressClassName="nginx" \
  --set ingress.hosts[0].host="${PORTAINER_HOST}" \
  --set ingress.hosts[0].paths[0].path="/" \
  --set ingress.hosts[0].paths[0].pathType="Prefix" \
  --set ingress.tls[0].hosts[0]="${PORTAINER_HOST}" \
  --set ingress.tls[0].secretName="wildcard-tls" \
  --set ingress.annotations."monitoring\.infranerd\.de/enabled"="\"true\"" \
  --set ingress.annotations."team"="devops" \
  --set ingress.annotations."environment"="homelab"

helm upgrade --install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --set defaultSettings.defaultReplicaCount="1" \
  --set ingress.enabled="true" \
  --set ingress.ingressClassName="nginx" \
  --set ingress.host="${LONGHORN_HOST}" \
  --set ingress.tls="true" \
  --set ingress.tlsSecret="wildcard-tls" \
  --set ingress.servicePort="80" \
  --set ingress.annotations."nginx\.ingress\.kubernetes\.io/backend-protocol"="HTTP" \
  --set ingress.annotations."monitoring\.infranerd\.de/enabled"="\"true\"" \
  --set ingress.annotations."team"="devops" \
  --set ingress.annotations."environment"="homelab" \
  --set ingress.path="/" \
  --set ingress.pathType="Prefix"

helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --set grafana.ingress.enabled="true" \
  --set grafana.ingress.ingressClassName="nginx" \
  --set grafana.ingress.hosts[0]="${GRAFANA_HOST}" \
  --set grafana.ingress.hosts[0].paths[0].path="/" \
  --set grafana.ingress.hosts[0].paths[0].pathType="Prefix" \
  --set grafana.ingress.tls[0].hosts[0]="${GRAFANA_HOST}" \
  --set grafana.ingress.tls[0].secretName="wildcard-tls" \
  --set grafana.ingress.annotations."monitoring\.infranerd\.de/enabled"="\"true\"" \
  --set grafana.ingress.annotations."team"="devops" \
  --set grafana.ingress.annotations."environment"="homelab" \
  --set grafana.adminPassword="${GRAFANA_ADMIN_PASS}" \
  --set prometheus.ingress.enabled="true" \
  --set prometheus.ingress.ingressClassName="nginx" \
  --set prometheus.ingress.hosts[0]="${PROMETHEUS_HOST}" \
  --set prometheus.ingress.hosts[0].paths[0].path="/" \
  --set prometheus.ingress.hosts[0].paths[0].pathType="Prefix" \
  --set prometheus.ingress.tls[0].hosts[0]="${PROMETHEUS_HOST}" \
  --set prometheus.ingress.tls[0].secretName="wildcard-tls" \
  --set prometheus.ingress.annotations."monitoring\.infranerd\.de/enabled"="\"true\"" \
  --set prometheus.ingress.annotations."team"="devops" \
  --set prometheus.ingress.annotations."environment"="homelab"
