# 🚀 K3s Homelab Bootstrap Script

![License](https://img.shields.io/github/license/sristow646/devops-homelab-k3s)
![ShellCheck](https://github.com/sristow646/devops-homelab-k3s/actions/workflows/shellcheck.yml/badge.svg)
![Made With](https://img.shields.io/badge/Made%20with-Bash-blue)
![Built with AI-Assistance](https://img.shields.io/badge/Built%20with-AI--Assistance-blueviolet?style=flat-square)
[![Docs Available](https://img.shields.io/badge/Docs-Available-blue?style=flat-square)](docs/)


# 🚀 DevOps Homelab K3s

Willkommen zu meinem DevOps Homelab Setup – einem vollständig automatisierten Kubernetes-Cluster basierend auf [K3s](https://k3s.io), das moderne Self-Hosting-Tools wie Portainer, Longhorn und Grafana integriert. Ziel dieses Projekts ist es, eine modulare, wartbare und CI/CD-fähige Infrastruktur für Self-Hosted-Anwendungen aufzubauen – ganz im Sinne von Infrastructure-as-Code.

---

## 🔍 Projektüberblick

Dieses Projekt richtet sich an alle, die Kubernetes im Homelab automatisiert betreiben möchten. Die gesamte Konfiguration erfolgt über Shell-Skripte, Helm-Charts und ENV-Variablen – vollständig reproduzierbar und anpassbar.
Nach durchlauf des Scriptes habt ihr ein eigenes Kubernetes Cluster wo ihr eure Container laufen lassen könnt.

┌────────────────────┐
│     Proxmox-Host   │
│  ThinkCentre Tiny  │
│      2TB SSD       │
│     64GB RAM       │
│  ───────────────── │
│  📦 VM: Ubuntu 22  │
│  🧠 k3s + Helm     │
│  📦 Apps:          │
│    - Ingress-NGINX │
│    - Portainer     │
│    - Longhorn      │
│    - Monitoring    │
└────────┬───────────┘
         │
         ▼
┌─────────────────────────────┐
│    MetalLB (192.168.200.X)  │◄──── Ingress Services
└─────────────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│      Fritz!Box (LAN DNS)    │
│  🔁 Lokale DNS-Auflösung     │
└────────┬────────────┬───────┘
         │            │
         ▼            ▼
  🧑‍💻 Client       🌍 IONOS DNS
 (Browser)        (*.privat.de)
                  → WAN IP → Fritz!Box



### Was dieses Setup bietet:

- ⚙️ Automatisiertes **K3s-Cluster Setup** (derzeitig nur Single Node )
- 🧱 Integration von Tools wie **Portainer**, **Longhorn**, **Ingress-NGINX** und **Monitoring**
- 🔐 **TLS-Handling mit Wildcard-Zertifikaten** (zentrale Verteilung in alle relevanten Namespaces)
- 🔄 **Auto-Restart Hooks** für wichtige Deployments (Portainer, Longhorn, Grafana)
- 📈 **Monitoring** via Prometheus, Grafana und optionalen Alerts
- 🧪 **GitHub Actions CI** zur Code-Qualitätssicherung (ShellCheck, Manifest Checks)
- 🧩 Modulares Design durch ENV-Dateien und Helm-Values

---

## 🧰 Verwendete Technologien

| Bereich            | Tools / Technologien                       |
|--------------------|--------------------------------------------|
| Kubernetes         | [K3s](https://k3s.io), Helm, kubectl       |
| Netzwerk & TLS     | Ingress-NGINX, MetalLB, IONOS Wildcard-Zertifikat |
| Self-Hosting Tools | Portainer CE, Longhorn                     |
| Monitoring         | Prometheus, Grafana                        |
| Automation         | Bash, GitHub Actions, ENV-Vorlagen         |

---

## 📦 Projektstruktur

```bash
.
├── install_k3s.sh                # Haupt-Setup-Script für das Cluster
├── bilder/                       # Screenshoots für README
├── env/                          # Beispielhafte ENV-Dateien
├── .gitlab/                      # GitHub Actions Workflows (CI)
├── scripts/                      # optionale hilfreiche scripte
└── README.md                     # Dieses Dokument
```

---

## 🚀 Schnellstart

1. 🔧 Passe deine `.env`-Dateien an (siehe `env/`).
2. 🔐 Hinterlege dein Wildcard-Zertifikat in `certs/`.
3. ▶️ Starte das Setup:
   ```bash
   chmod +x install_k3s.sh
   ./Install_k3s.sh
   ```
   oder einfach
   ```
   bash install_k3s.sh
   ```
---

## 📸 Vorschau

Ein paar Eindrücke aus dem Setup – inklusive Portainer UI, Longhorn Dashboard und Grafana Monitoring.
  <img src="bilder/shell.png" alt="Installation" width="400"/>
<p float="left">
  <img src="bilder/portainer.png" alt="Portainer UI" width="600"/>
  <img src="bilder/prometheus.png" alt="Prometheus" width="600"/>
  <img src="bilder/grafana.png" alt="Grafana" width="600"/>
  <img src="bilder/loki.png" alt="Loki Dashboard" width="600"/>
</p>

---

## 📖 Doku & Weiteres

- [K3s Offizielle Doku](https://docs.k3s.io/)
- [Helm Charts Doku](https://helm.sh/docs/)
- [Longhorn](https://longhorn.io/)
- [Portainer](https://www.portainer.io/)

---

## 👤 Über den Autor

Dieses Projekt entstand im Rahmen meines privaten Homelabs, um meine Fähigkeiten im Bereich Kubernetes, Automatisierung und Infrastructure-as-Code kontinuierlich zu verbessern. Als DevOps Engineer liegt mein Fokus auf effizienten, wartbaren und sicheren Deployments – sowohl im professionellen Umfeld als auch privat.

- 🧑 GitHub: [github.com/sristow646](https://github.com/sristow646)
- 💼 LinkedIn: www.linkedin.com/in/stephan-ristow


---

## 🪪 Lizenz

MIT License – feel free to use, adapt, improve & share 🚀
