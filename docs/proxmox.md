
🚀 Proxmox Cloud-Init VM von A bis Z

Falls Du auch Proxmox nutzt, hier eine Kurzanleitung zum bereitstellen einer CLoud-Init VM

Mein System ist:

🖥️ Lenovo ThinkCentre Setup

CPU: Intel i7-6700T @ 2.80GHz
RAM: 64 GB
SSD: 2 TB
Hypervisor: Proxmox (VM-basiert)
👉 Du hast eine All-in-One VM für:

k3s Cluster (inkl. Helm)
MetalLB, Ingress-NGINX
Portainer & optional Rancher
Longhorn Storage
Monitoring Stack (Prometheus & Grafana)
Alles läuft in einer kompakten DevOps-VM auf deinem Proxmox.

⚙️ VM Specs:
Parameter	Empfehlung
vCPUs	6 Cores (von 8 Threads der CPU)
RAM	32 GB (flexibel, ggf. 48 GB)
Disk	100 GB (btrfs oder ext4, später erweiterbar)
Netzwerk	VirtIO (Bridge: vmbr0)
SCSI-Controller	VirtIO SCSI
Cloud-Init Drive	ja (für User + SSH + IP)
Boot	SCSI Disk + Cloud-Init (serial0 als Konsole)


🧰 Schritte:
1️⃣ Cloud-Image laden
Empfohlen: Ubuntu Cloud-Image (z.B. Ubuntu 24.04 LTS)

wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img -O ubuntu-24.04-cloud.img
2️⃣ Image nach Proxmox hochladen
Beispiel: Du hast deinen Proxmox-Storage unter /var/lib/vz

qm create 110 --name homelab-vm --memory 8192 --cores 4 --net0 virtio,bridge=vmbr0
qm importdisk 110 ubuntu-24.04-cloud.img local-lvm
3️⃣ Virtuelle Festplatte mit der VM verbinden
qm set 110 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-110-disk-0
4️⃣ Cloud-Init Drive hinzufügen
qm set 110 --ide2 local-lvm:cloudinit
qm set 110 --boot c --bootdisk scsi0 --serial0 socket --vga serial0
5️⃣ Cloud-Init vorbereiten
qm set 110 --ciuser ubuntu --sshkey ~/.ssh/id_rsa.pub --ipconfig0 ip=dhcp
🔄 Alternativ: Statische IP definieren:

qm set 110 --ipconfig0 ip=192.168.200.100/24,gw=192.168.200.1
6️⃣ Cloud-Init anwenden
qm resize 110 scsi0 +20G     # Optional: Festplattengröße anpassen
qm template 110              # Optional: als Vorlage speichern
oder direkt starten:

qm start 110
✅ Danach hast du:
Eine lauffähige Cloud-Init VM in Proxmox
SSH-Zugang via deinem hinterlegten Public Key
Automatische Netzwerk-Konfiguration (DHCP oder statisch)
📝 Proxmox Web-UI Tipp
Im Proxmox GUI kannst du unter Cloud-Init Tab dann auch „Regenerate Image“ klicken
Dort kannst du auch User, SSH-Key und IPs nachträglich anpassen
