#!/bin/bash
set +e

# Farbdefinitionen
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

# === ENV Variablen laden ===
if [ -f env/.env ]; then
  echo -e "${YELLOW}🔄 Lade Umgebungsvariablen aus .env...${RESET}"
  set -o allexport
  # shellcheck disable=SC1091
  source env/.env
  set +o allexport
else
  echo -e "${RED}❌ env/.env Datei nicht gefunden! Bitte erstellen!${RESET}"
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
############################################BIS Hierher alles Easy############################################

Alle benötigten Helm Repos hinzufügen
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx || true
helm repo add metallb https://metallb.github.io/metallb || true
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
helm repo add grafana https://grafana.github.io/helm-charts || true
helm repo update

# === Ingress NGINX Deployment ===


helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --set controller.service.type=LoadBalancer \
  --set controller.service.loadBalancerIP="${METALLB_IP%%-*}" \
  --set controller.extraArgs.default-ssl-certificate="ingress-nginx/wildcard-tls"

kubectl rollout status deployment ingress-nginx-controller -n ingress-nginx --timeout=120s

# === MetalLB Setup ===
helm upgrade --install metallb metallb/metallb --namespace metallb-system --create-namespace
kubectl wait --namespace metallb-system --for=condition=available --timeout=120s deployment/controller

# Warte auf MetalLB Webhook Service
until kubectl -n metallb-system get endpoints metallb-webhook-service -o jsonpath="{.subsets[*].addresses[*].ip}" | grep -q .; do
  echo "⏳ Warte auf MetalLB Webhook Service..."
  sleep 5
done

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/crd/bases/metallb.io_ipaddresspools.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/crd/bases/metallb.io_l2advertisements.yaml

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

# === Portainer Deployment ===
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

# === Longhorn Deployment ===
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

# === Monitoring Deployment ===
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --set grafana.ingress.enabled="true" \
  --set grafana.ingress.ingressClassName="nginx" \
  --set grafana.ingress.hosts[0]="${GRAFANA_HOST}" \
  --set grafana.ingress.path="/" \
  --set grafana.ingress.pathType="Prefix" \
  --set grafana.ingress.tls[0].hosts[0]="${GRAFANA_HOST}" \
  --set grafana.ingress.tls[0].secretName="wildcard-tls" \
  --set grafana.ingress.annotations."monitoring\.infranerd\.de/enabled"="\"true\"" \
  --set grafana.ingress.annotations."team"="devops" \
  --set grafana.ingress.annotations."environment"="homelab" \
  --set grafana.adminPassword="${GRAFANA_ADMIN_PASS}" \
  --set prometheus.ingress.enabled="true" \
  --set prometheus.ingress.ingressClassName="nginx" \
  --set prometheus.ingress.hosts[0]="${PROMETHEUS_HOST}" \
  --set prometheus.ingress.path="/" \
  --set prometheus.ingress.pathType="Prefix" \
  --set prometheus.ingress.tls[0].hosts[0]="${PROMETHEUS_HOST}" \
  --set prometheus.ingress.tls[0].secretName="wildcard-tls" \
  --set prometheus.ingress.annotations."monitoring\.infranerd\.de/enabled"="\"true\"" \
  --set prometheus.ingress.annotations."team"="devops" \
  --set prometheus.ingress.annotations."environment"="homelab"

# === Loki + Tempo Stack ===
helm upgrade --install loki grafana/loki-stack \
  --namespace monitoring \
  --set grafana.enabled=false \
  --set promtail.enabled=true \
  --set loki.persistence.enabled=true \
  --set loki.persistence.size="5Gi"

helm upgrade --install tempo grafana/tempo \
  --namespace monitoring \
  --set ingress.enabled=false

# === Datasources Auto-Provision via ConfigMap (jetzt nach Loki & Tempo) ===
kubectl apply -n monitoring -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-datasources
  labels:
    grafana_datasource: "1"
data:
  datasources.yaml: |
    apiVersion: 1
    datasources:
      - name: Prometheus
        type: prometheus
        url: http://monitoring-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090
        access: proxy
        isDefault: true
      - name: Loki
        type: loki
        url: http://loki.monitoring.svc.cluster.local:3100
        access: proxy
      - name: Tempo
        type: tempo
        url: http://tempo.monitoring.svc.cluster.local:3100
        access: proxy
EOF


# === Health-Checks zusammengefasst ===
NAMESPACES=("portainer" "longhorn-system" "monitoring")
SECRET_NAME="wildcard-tls"

for ns in "${NAMESPACES[@]}"; do
  echo "➡ Prüfe Namespace: $ns"
  kubectl -n "$ns" get ingress -o json | jq -r '
    .items[] |
    "Ingress: \(.metadata.name) | Host: \(.spec.rules[].host) | TLS: \(.spec.tls[].secretName)"' | \
    grep "$SECRET_NAME" || echo -e "${RED}❌ Fehlendes TLS-Secret in Namespace $ns!${RESET}"
done

SUCCESSFUL_HOSTS=()
FAILED_HOSTS=()

HOSTS=("${PORTAINER_HOST}" "${LONGHORN_HOST}" "${GRAFANA_HOST}" "${PROMETHEUS_HOST}")
for h in "${HOSTS[@]}"; do
  echo "🔍 Prüfe DNS A-Record für $h ..."
  dig +short "$h" @8.8.8.8 | grep "${METALLB_IP%%-*}" || echo -e "${RED}❌ WARNUNG: $h zeigt nicht auf ${METALLB_IP%%-*}${RESET}"
  echo "🌐 Health-Check https://$h ..."
  success=0
  for i in {1..5}; do
    if curl -k --silent --fail "https://$h" >/dev/null; then
      echo -e "${GREEN}✅ HTTPS erreichbar (Versuch $i)${RESET}"
      success=1
      break
    else
      echo -e "${YELLOW}⏳ Versuch $i fehlgeschlagen, warte 5s...${RESET}"
      sleep 5
    fi
  done
  if [ $success -eq 0 ]; then
    echo -e "${RED}⚠️ Soft-Fail: $h nach 5 Versuchen nicht erreichbar, Setup läuft weiter.${RESET}"
    FAILED_HOSTS+=("$h")
  else
    SUCCESSFUL_HOSTS+=("$h")
  fi
  echo ""
done

# === Abschluss-Info ===
echo ""
echo -e "🚀 === ${GREEN}Setup abgeschlossen!${RESET} ==="
echo ""
echo "🔗 Deine Services:"
echo "➡ Portainer:   https://${PORTAINER_HOST}"
echo "➡ Longhorn:    https://${LONGHORN_HOST}"
echo "➡ Grafana:     https://${GRAFANA_HOST} | User: admin | PW: \${GRAFANA_ADMIN_PASS}"
echo "➡ Prometheus:  https://${PROMETHEUS_HOST}"
echo "🔒 TLS Secret: wildcard-tls"
echo "💡 LoadBalancer IP Range: ${METALLB_IP_RANGE}"
echo ""
echo -e "=== ${GREEN}Erfolgreich erreichbar:${RESET} ${SUCCESSFUL_HOSTS[*]}"
echo -e "=== ${RED}Probleme bei:${RESET} ${FAILED_HOSTS[*]}"
echo ""
