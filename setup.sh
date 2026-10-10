#!/usr/bin/env bash
# =============================================================
# BADASS - environment setup for an Ubuntu VM (22.04 / 24.04)
# Installs Docker, GNS3 (server + GUI), Wireshark, sets the
# user permissions and builds the two project images.
#
# Usage (from the repo root, as your normal user, NOT root):
#   chmod +x setup.sh && ./setup.sh
# Then log out and back in (or reboot) so the new groups apply.
# =============================================================
set -euo pipefail

if [ "$(id -u)" -eq 0 ]; then
  echo "Run as your normal user (the script calls sudo itself)." >&2
  exit 1
fi

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
export DEBIAN_FRONTEND=noninteractive

echo "==> Pre-answering install questions"
# Allow non-root users to capture packets (Wireshark)
echo "wireshark-common wireshark-common/install-setuid boolean true" | sudo debconf-set-selections
# Allow GNS3 to create links without running as root (ubridge)
echo "ubridge ubridge/install-setuid boolean true" | sudo debconf-set-selections

echo "==> Base packages"
sudo apt-get update
sudo apt-get install -y software-properties-common ca-certificates curl git

echo "==> Docker"
sudo apt-get install -y docker.io
sudo systemctl enable --now docker

echo "==> GNS3 (official PPA) + Wireshark"
sudo add-apt-repository -y ppa:gns3/ppa
sudo apt-get update
sudo apt-get install -y gns3-server gns3-gui wireshark

echo "==> User permissions"
for g in docker ubridge wireshark kvm libvirt; do
  if getent group "$g" >/dev/null; then
    sudo usermod -aG "$g" "$USER"
    echo "   added $USER to $g"
  fi
done

echo "==> Building project images"
if [ -f "$REPO_DIR/Shared/router.Dockerfile" ]; then
  sudo docker build -t badass-router -f "$REPO_DIR/Shared/router.Dockerfile" "$REPO_DIR/Shared"
  sudo docker build -t badass-host   -f "$REPO_DIR/Shared/host.Dockerfile"   "$REPO_DIR/Shared"
  sudo docker images | grep -E "badass-(router|host)"
else
  echo "   Shared/ not found next to setup.sh - skipping image build."
fi

cat <<'EOF'

==> Done.
Next steps:
  1. Log out and log back in (or reboot) so the docker/ubridge/wireshark
     groups take effect. Check with: groups
  2. Open GNS3 -> choose "Run appliances on my local computer".
  3. Recreate the Docker templates (Edit -> Preferences -> Docker):
       - badass-router:latest  (3 adapters, persistent dir: /etc/frr)
       - badass-host:latest    (1 adapter)
  4. File -> Import portable project -> P1/P2/P3 .gns3project
EOF