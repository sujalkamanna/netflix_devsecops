#!/bin/bash
set -e

echo "🔄 Updating system..."
sudo apt update -y

# =========================================================
# 👤 Create Blackbox Exporter User
# =========================================================
echo "👤 Creating blackbox_exporter user..."
sudo useradd --system --no-create-home --shell /bin/false blackbox_exporter || true

# =========================================================
# 📦 Variables
# =========================================================
BLACKBOX_VERSION="0.27.0"
INSTALL_DIR="/tmp"
EXTRACTED_DIR="blackbox_exporter-${BLACKBOX_VERSION}.linux-amd64"

cd $INSTALL_DIR

# =========================================================
# 📦 Download Blackbox Exporter
# =========================================================
echo "⬇️ Downloading Blackbox Exporter v${BLACKBOX_VERSION}..."
wget https://github.com/prometheus/blackbox_exporter/releases/download/v${BLACKBOX_VERSION}/${EXTRACTED_DIR}.tar.gz

# =========================================================
# 📂 Extract Files
# =========================================================
echo "📂 Extracting..."
tar -xvf ${EXTRACTED_DIR}.tar.gz
cd ${EXTRACTED_DIR}

# =========================================================
# 📁 Create Config Directory
# =========================================================
echo "📁 Creating config directory..."
sudo mkdir -p /etc/blackbox_exporter

# =========================================================
# 📦 Move Files
# =========================================================
echo "📦 Installing binaries and config..."
sudo mv blackbox_exporter /usr/local/bin/
sudo mv blackbox.yml /etc/blackbox_exporter/

# =========================================================
# 🔐 Set Permissions
# =========================================================
echo "🔐 Setting permissions..."
sudo chown -R blackbox_exporter:blackbox_exporter /etc/blackbox_exporter
sudo chown blackbox_exporter:blackbox_exporter /usr/local/bin/blackbox_exporter

# =========================================================
# 🧹 Cleanup
# =========================================================
cd /tmp
rm -rf ${EXTRACTED_DIR}*

# =========================================================
# ⚙️ Create systemd Service
# =========================================================
echo "⚙️ Creating Blackbox Exporter service..."

sudo tee /etc/systemd/system/blackbox_exporter.service > /dev/null <<EOF
[Unit]
Description=Blackbox Exporter
After=network.target

[Service]
User=blackbox_exporter
ExecStart=/usr/local/bin/blackbox_exporter \
  --config.file=/etc/blackbox_exporter/blackbox.yml \
  --web.listen-address=:9115 \
  --log.level=info

Restart=always

[Install]
WantedBy=multi-user.target
EOF

# =========================================================
# ▶️ Start Service
# =========================================================
echo "🚀 Starting Blackbox Exporter..."

sudo systemctl daemon-reload
sudo systemctl enable blackbox_exporter
sudo systemctl restart blackbox_exporter

# =========================================================
# 🔍 Verify Service
# =========================================================
echo "📊 Checking status..."
sudo systemctl status blackbox_exporter --no-pager

echo "📜 Logs (live):"
echo "journalctl -u blackbox_exporter -f --no-pager"

# =========================================================
# 🌐 Test Endpoints
# =========================================================
echo "🌐 Test endpoints:"
echo "👉 UI: http://<MONITORING-IP>:9115"
echo "👉 Probe Test:"
echo "curl 'http://localhost:9115/probe?target=http://example.com&module=http_2xx'"

echo "✅ Blackbox Exporter Installed Successfully!"