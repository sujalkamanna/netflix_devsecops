#!/bin/bash
set -e

echo "🔄 Updating system..."
sudo apt update -y

echo "👤 Creating node_exporter user..."
sudo useradd --system --no-create-home --shell /bin/false node_exporter || true

NODE_VERSION="1.11.0"
INSTALL_DIR="/tmp"
NODE_DIR="node_exporter-${NODE_VERSION}.linux-amd64"

cd $INSTALL_DIR

echo "⬇️ Downloading Node Exporter..."
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_VERSION}/${NODE_DIR}.tar.gz

tar -xvf ${NODE_DIR}.tar.gz
cd ${NODE_DIR}

echo "📦 Installing binary..."
sudo mv node_exporter /usr/local/bin/

echo "🔐 Setting permissions..."
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

cd /tmp
rm -rf ${NODE_DIR}*

echo "⚙️ Creating service..."
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter \
  --web.listen-address=0.0.0.0:9100 \
  --log.level=info

Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl restart node_exporter

echo "🔍 Verifying..."
sudo systemctl status node_exporter --no-pager

echo "🌐 Test:"
echo "curl http://localhost:9100/metrics"

echo "✅ Node Exporter running on http://<APP-IP>:9100/metrics"