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

## ⚙️ Voraussetzungen

- Ubuntu / Debian VM (min. 4 CPUs / 8GB RAM empfohlen)
- Wildcard TLS-Zertifikat & Private Key
- Internetzugang

## 🛠️ Benutzung

1. Repo klonen

```bash
git clone https://github.com/your-username/devops-homelab-k3s.git
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

## 🤖 About this Project

Dieses Projekt wurde mit Unterstützung von **AI-Assistance** (OpenAI / ShellCheck / CI Tools) entwickelt. Ziel ist es, effiziente DevOps-Automatisierung für Homelabs zu fördern.

## 📝 Hinweise
- Rancher-freies Setup
- TLS-Zertifikate müssen vorhanden sein
- Optimiert für Homelab & Testumgebungen

## 🧑‍💻 Lizenz
MIT License – feel free to fork & contribute!