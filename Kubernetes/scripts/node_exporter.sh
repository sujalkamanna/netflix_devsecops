#!/bin/bash
set -e

echo "🔄 Updating system..."
sudo apt update -y

# =========================================================
# 👤 Create user
# =========================================================
echo "👤 Creating node_exporter user..."
sudo useradd --system --no-create-home --shell /bin/false node_exporter || true

# =========================================================
# 📦 Install Node Exporter
# =========================================================
if command -v node_exporter >/dev/null 2>&1; then
  echo "⚠️ Node Exporter already installed. Exiting."
  exit 0
fi

NODE_VERSION="1.11.0"
INSTALL_DIR="/tmp"
ARCHIVE="node_exporter.tar.gz"
NODE_DIR="node_exporter-${NODE_VERSION}.linux-amd64"

cd $INSTALL_DIR

echo "⬇️ Downloading Node Exporter..."
wget -q --show-progress -O $ARCHIVE \
https://github.com/prometheus/node_exporter/releases/download/v${NODE_VERSION}/${NODE_DIR}.tar.gz

echo "📦 Extracting..."
tar -xvf $ARCHIVE

cd ${NODE_DIR}

echo "📦 Installing binary..."
sudo mv node_exporter /usr/local/bin/

echo "🔐 Setting permissions..."
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

# Cleanup
cd /tmp
rm -rf ${NODE_DIR}*
rm -f $ARCHIVE

# =========================================================
# ⚙️ Create systemd service
# =========================================================
echo "⚙️ Creating service..."

sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter \\
  --web.listen-address=0.0.0.0:9100 \\
  --log.level=info
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# =========================================================
# 🚀 Start service
# =========================================================
sudo systemctl daemon-reload
sudo systemctl stop node_exporter 2>/dev/null || true
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

# =========================================================
# 🔍 Verification
# =========================================================
echo "🔍 Checking service..."

if systemctl is-active --quiet node_exporter; then
  echo "✅ Node Exporter is running"
else
  echo "❌ Node Exporter failed"
  sudo journalctl -u node_exporter --no-pager -n 20
  exit 1
fi

echo "🌐 Test locally:"
echo "curl http://localhost:9100/metrics"

echo "🌍 Access:"
echo "http://<EC2-IP>:9100/metrics"

echo "⚠️ Make sure port 9100 is open in Security Group"

echo "-----------------------------------"
echo "✅ Node Exporter Setup Completed"
echo "-----------------------------------"