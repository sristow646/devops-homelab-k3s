# 🧹 Cluster Cleanup Anleitung

## 📋 Zweck
Dieses Script bereinigt dein k3s-Cluster inkl. aller Helm-Releases und zugehörigen Ressourcen. Ideal für einen sauberen Neuaufbau deines Homelabs.

## 🚀 Nutzung

1️⃣ **Repo klonen**

```bash
git clone https://github.com/sristow646/devops-homelab-k3s.git
cd devops-homelab-k3s
```

2️⃣ **Cluster bereinigen**

```bash
bash cleanup.sh
```

Das Script erkennt automatisch:
- ob k3s noch läuft
- ob Helm-Releases existieren
- ob Namespaces & CRDs vorhanden sind

3️⃣ **Neustart des Setups**

```bash
bash smart-cluster-cleanup.sh
```

---

## 🔄 Was wird entfernt?
- Alle Helm Releases (z.B. metallb, ingress-nginx, portainer, longhorn, grafana, prometheus)
- k3s Artefakte (Hinweis zur Deinstallation via `/usr/local/bin/k3s-uninstall.sh`)
- Namespaces wie `longhorn-system`, `portainer`, `monitoring` etc.
- Longhorn CRDs
- Lokale Verzeichnisse wie `/etc/rancher/`, `/var/lib/longhorn/`, `/var/lib/kubelet/`

## ⚠️ Hinweise
- Systemtools wie Helm & kubectl bleiben installiert
- TLS-Zertifikate im Filesystem bleiben erhalten
- **Nur für Dev/Test-Umgebungen geeignet**

---

