#!/bin/bash
set -euo pipefail

echo "🔄 Updating system..."
sudo apt update -y

echo "📦 Installing dependencies..."
sudo apt install -y apt-transport-https software-properties-common wget gnupg

# =========================================================
# 🔐 Add Grafana GPG Key
# =========================================================
echo "🔐 Adding Grafana key..."

sudo mkdir -p /etc/apt/keyrings

if [ ! -f /etc/apt/keyrings/grafana.gpg ]; then
  wget -q -O - https://apt.grafana.com/gpg.key | \
  gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
else
  echo "⚠️ Grafana key already exists, skipping..."
fi

# =========================================================
# 📦 Add Grafana Repo
# =========================================================
echo "📦 Adding Grafana repo..."

echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | \
sudo tee /etc/apt/sources.list.d/grafana.list > /dev/null

sudo apt update -y

# =========================================================
# 📦 Install Grafana
# =========================================================
if dpkg -l | grep -q grafana; then
  echo "⚠️ Grafana already installed, skipping install..."
else
  sudo apt install -y grafana
fi

# =========================================================
# 🚀 Start Grafana
# =========================================================
echo "🚀 Starting Grafana..."

sudo systemctl daemon-reload
sudo systemctl enable grafana-server
sudo systemctl restart grafana-server

# =========================================================
# 🔍 Verify
# =========================================================
echo "🔍 Checking service..."

if systemctl is-active --quiet grafana-server; then
  echo "✅ Grafana is running"
else
  echo "❌ Grafana failed to start"
  sudo journalctl -u grafana-server --no-pager -n 20
  exit 1
fi

# =========================================================
# 🎉 Done
# =========================================================
echo "-----------------------------------"
echo "✅ Grafana Setup Completed"
echo "🌐 URL: http://<EC2-IP>:3000"
echo "🔑 Login: admin / admin"
echo "⚠️ Open port 3000 in Security Group"
echo "-----------------------------------"