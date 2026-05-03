#!/bin/bash
set -euo pipefail

echo "🔄 Updating system..."
sudo apt update -y

# =========================================================
# 👤 Create user
# =========================================================
echo "👤 Creating blackbox_exporter user..."
sudo useradd --system --no-create-home --shell /bin/false blackbox_exporter || true

# =========================================================
# 📦 Install check
# =========================================================
if command -v blackbox_exporter >/dev/null 2>&1; then
  echo "⚠️ Blackbox Exporter already installed. Exiting."
  exit 0
fi

# =========================================================
# 📦 Variables
# =========================================================
VERSION="0.27.0"
INSTALL_DIR="/tmp"
ARCHIVE="blackbox.tar.gz"
DIR="blackbox_exporter-${VERSION}.linux-amd64"

cd $INSTALL_DIR

# =========================================================
# ⬇️ Download
# =========================================================
echo "⬇️ Downloading Blackbox Exporter..."
wget -q --show-progress -O $ARCHIVE \
https://github.com/prometheus/blackbox_exporter/releases/download/v${VERSION}/${DIR}.tar.gz

# =========================================================
# 📂 Extract
# =========================================================
echo "📂 Extracting..."
tar -xvf $ARCHIVE
cd $DIR

# =========================================================
# 📁 Config dir
# =========================================================
sudo mkdir -p /etc/blackbox_exporter

# =========================================================
# 📦 Install
# =========================================================
echo "📦 Installing..."

sudo mv blackbox_exporter /usr/local/bin/

if [ ! -f /etc/blackbox_exporter/blackbox.yml ]; then
  sudo mv blackbox.yml /etc/blackbox_exporter/
else
  echo "⚠️ Existing config found, keeping it"
fi

# =========================================================
# 🔐 Permissions
# =========================================================
sudo chown -R blackbox_exporter:blackbox_exporter /etc/blackbox_exporter
sudo chown blackbox_exporter:blackbox_exporter /usr/local/bin/blackbox_exporter

# =========================================================
# 🧹 Cleanup
# =========================================================
cd /tmp
rm -rf ${DIR}*
rm -f $ARCHIVE

# =========================================================
# ⚙️ Service
# =========================================================
echo "⚙️ Creating service..."

sudo tee /etc/systemd/system/blackbox_exporter.service > /dev/null <<EOF
[Unit]
Description=Blackbox Exporter
After=network.target

[Service]
User=blackbox_exporter
ExecStart=/usr/local/bin/blackbox_exporter \\
  --config.file=/etc/blackbox_exporter/blackbox.yml \\
  --web.listen-address=:9115 \\
  --log.level=info
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# =========================================================
# 🚀 Start
# =========================================================
echo "🚀 Starting service..."

sudo systemctl daemon-reload
sudo systemctl enable blackbox_exporter
sudo systemctl restart blackbox_exporter

# =========================================================
# 🔍 Verify
# =========================================================
echo "🔍 Checking service..."

if systemctl is-active --quiet blackbox_exporter; then
  echo "✅ Blackbox Exporter is running"
else
  echo "❌ Service failed"
  sudo journalctl -u blackbox_exporter --no-pager -n 20
  exit 1
fi

# =========================================================
# 🌐 Test
# =========================================================
echo "🌐 Test endpoints:"
echo "👉 UI: http://<SERVER-IP>:9115"
echo "👉 Probe:"
echo "curl 'http://localhost:9115/probe?target=http://example.com&module=http_2xx'"

echo "⚠️ Ensure port 9115 is open"

echo "-----------------------------------"
echo "✅ Blackbox Exporter Setup Complete"
echo "-----------------------------------"