# 🚀 K3s Homelab Bootstrap Script

![License](https://img.shields.io/github/license/sristow646/devops-homelab-k3s)
![ShellCheck](https://github.com/sristow646/devops-homelab-k3s/actions/workflows/shellcheck.yml/badge.svg)
![Made With](https://img.shields.io/badge/Made%20with-Bash-blue)
![Built with AI-Assistance](https://img.shields.io/badge/Built%20with-AI--Assistance-blueviolet?style=flat-square)
[![Docs Available](https://img.shields.io/badge/Docs-Available-blue?style=flat-square)](docs/)


## 📦 Enthaltene Komponenten

- K3s – leichtgewichtiger Kubernetes Cluster
- MetalLB – Layer2 LoadBalancer für bare-metal Kubernetes
- Ingress-NGINX – Ingress-Controller
- Portainer – Kubernetes GUI & Verwaltung
- Longhorn – Distributed Block Storage für Kubernetes
- Prometheus – Metrics & Monitoring
- Grafana – Visualisierung & Dashboards
## 🏡 Homelab K3s Architekturübersicht

Dieses Homelab-Setup nutzt **k3s** als leichtgewichtige Kubernetes-Distribution und automatisiert die Bereitstellung von Ingress, Storage und Monitoring.

### 🔗 Netzwerk-Topologie:
- **Client PC** → **Fritz!Box Router** → **k3s Cluster (Ingress-NGINX LoadBalancer)**

### 🧩 Cluster-Komponenten:
- **k3s Server (Single Node)**  
  - Lightweight Kubernetes für Homelab-Umgebungen
  - Installiert ohne Traefik (custom Ingress-NGINX)

- **Ingress-NGINX**
  - LoadBalancer Service via MetalLB IP-Range
  - Verarbeitet externe Anfragen und TLS-Terminierung

- **Portainer (via Helm)**
  - Web-GUI für Kubernetes Management (Ingress abgesichert mit Wildcard-TLS)

- **Longhorn**
  - Distributed Block Storage für Kubernetes
  - Single-Replica Konfiguration für Homelab

- **Monitoring Stack**
  - **Prometheus**: Cluster- und Service-Metriken
  - **Grafana**: Visualisierung mit vorkonfiguriertem Prometheus-Datasource

### 🔐 Sicherheit & Automatisierung:
- Wildcard-Zertifikat wird in alle relevanten Namespaces repliziert
- Helm-Charts für alle Komponenten inkl. Ingress + TLS
- Admission Webhook Wait-Check für Ingress-NGINX
- Automatische DNS- und HTTPS-Checks nach der Installation

### 🌐 Externe Zugriffe:
- Services wie Portainer, Grafana & Prometheus sind über die Fritz!Box (Portforwarding o. DynDNS) erreichbar.

### 🏷️ Bonus: DNS & Domain
- Nutzung einer privaten Domain (z. B. `privat.de`) mit Wildcard-Zertifikat (*.privat.de) über einen günstigen Hoster: z.B. Ionus
- DNS (IONUS) leitet Subdomains wie `portainer.privat.de` direkt auf die MetalLB IP (z. B. 192.168.xxx.xxx)
- Ingress-NGINX übernimmt die TLS-Terminierung für alle Subdomains im Cluster
- Optional: DynDNS über Fritz!Box für externen Zugriff




## ⚙️ Voraussetzungen

- Ubuntu / Debian VM (min. 4 CPUs / 8GB RAM empfohlen)
- Wildcard TLS-Zertifikat & Private Key
- Internetzugang

## 🛠️ Benutzung

1. Repo klonen

```bash
git clone https://github.com/SRISTOW646/devops-homelab-k3s.git
cd devops-homelab-k3s
```

2. `.env` anlegen und die Werte entsprechend eintragen.

   Die METALLB_IP_RANGE muss ein Range aus eurem Heimnetz haben und außerhalb des DHCP Ranges liegen (falls ihr das nutzt)

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

3. Script starten

```bash
bash install_k3s.sh
```

## 🌐 Zugänge

| Service      | URL                         | Zugangsdaten                        |
|--------------|-----------------------------|-------------------------------------|
| Portainer    | https://portainer.example.com  | Admin-User wird bei Login erstellt  |
| Longhorn     | https://longhorn.example.com   | Zugriff über Web-UI                 |
| Grafana      | https://grafana.example.com    | admin / Passwort aus `.env`         |
| Prometheus   | https://prometheus.example.com | Kein Login (TLS-only)               |

DIe URL's verweisen jeweils auf eine private IP und sind somit nicht aus dem Internet erreichbar!
Da die Fritz.Box DNS anfragen aus dem öffentlichen Netz, welche auf eine private IP verweisen blockt,
muss eventuell dies in der DNS-Rebind-Schutz freigegeben werden.

## 🤖 About this Project

Dieses Projekt wurde mit Unterstützung von **AI-Assistance** (OpenAI / ShellCheck / CI Tools) entwickelt. Ziel ist es, effiziente DevOps-Automatisierung für Homelabs zu fördern.

## 📝 Hinweise
- Nutzung von Resourcen die man auch als Privatanwender bereit stellen kann.
- TLS-Zertifikate müssen vorhanden sein
- Optimiert für Homelab & Testumgebungen

## 🧑‍💻 Lizenz
MIT License – feel free to fork & contribute!