#!/bin/bash
set -e

echo "🔄 Updating system..."
sudo apt update -y

echo "👤 Creating Prometheus user..."
sudo useradd --system --no-create-home --shell /bin/false prometheus || true

cd /tmp

echo "⬇️ Downloading Prometheus..."
wget https://github.com/prometheus/prometheus/releases/download/v3.11.1/prometheus-3.11.1.linux-amd64.tar.gz

tar -xvf prometheus-3.11.1.linux-amd64.tar.gz
cd prometheus-3.11.1.linux-amd64

echo "📁 Creating directories..."
sudo mkdir -p /etc/prometheus
sudo mkdir -p /var/lib/prometheus

echo "📦 Moving files..."
sudo mv prometheus /usr/local/bin/
sudo mv promtool /usr/local/bin/
sudo mv prometheus.yml /etc/prometheus/

echo "🔐 Setting permissions..."
sudo chown -R prometheus:prometheus /etc/prometheus
sudo chown -R prometheus:prometheus /var/lib/prometheus
sudo chown prometheus:prometheus /usr/local/bin/prometheus

cd /tmp
rm -rf prometheus-3.11.1.linux-amd64*

echo "⚙️ Creating service..."
sudo tee /etc/systemd/system/prometheus.service > /dev/null <<EOF
[Unit]
Description=Prometheus
After=network.target

[Service]
User=prometheus
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --web.listen-address=:9090

Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl restart prometheus

echo "✅ Prometheus running on http://<EC2-IP>:9090"