# 🚀 Setup Anleitung für DevOps Homelab K3s

## 📋 Zweck
Dieses Script automatisiert die komplette Bereitstellung eines Kubernetes-Clusters inkl. MetalLB, Ingress, Portainer, Longhorn und einem Monitoring-Stack (Prometheus + Grafana).

---

## ⚙️ Voraussetzungen
- Ubuntu/Debian VM oder Bare-Metal (mind. 4 CPUs / 8GB RAM empfohlen)
- Internetzugang (für Helm Repos & Container Pulls)
- Ein gültiges Wildcard TLS-Zertifikat & Private Key
- Helm und kubectl sind im Script inkludiert (via k3s Setup)

---

## 🚀 Nutzung

1️⃣ **Repo klonen**

```bash
git clone https://github.com/your-username/devops-homelab-k3s.git
cd devops-homelab-k3s
```

2️⃣ **.env anpassen**

```ini
TLS_CERT_PATH=/pfad/zu/deinem/cert.crt
TLS_KEY_PATH=/pfad/zu/deinem/key.key
METALLB_IP_RANGE=192.168.x.x-192.168.x.x

PORTAINER_HOST=portainer.example.com
LONGHORN_HOST=longhorn.example.com
GRAFANA_HOST=grafana.example.com
PROMETHEUS_HOST=prometheus.example.com

GRAFANA_ADMIN_PASS=DEINPASSWORT
```

3️⃣ **Setup starten**

```bash
bash setup.sh
```

---

## 🧩 Was wird deployt?

- K3s Kubernetes Cluster
- MetalLB IP-Pool (Layer 2 LoadBalancer)
- Ingress-NGINX Controller (LoadBalancer inkl. TLS)
- Portainer mit Ingress
- Longhorn inkl. Ingress
- Prometheus inkl. Ingress
- Grafana inkl. Auto-Dashboard + Prometheus Datasource
- TLS Wildcard-Secret wird automatisch in alle relevanten Namespaces kopiert

---

## 📌 Hinweis:
Nach Abschluss werden alle Service-URLs und Standard-Zugänge direkt ausgegeben (Portainer, Grafana, etc.)

---

