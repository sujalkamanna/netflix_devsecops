#!/bin/bash
set -e

echo "🔄 Updating system..."
sudo apt update -y

echo "📦 Installing dependencies..."
sudo apt install -y apt-transport-https software-properties-common wget gnupg

echo "🔐 Adding Grafana key..."
sudo mkdir -p /etc/apt/keyrings

wget -q -O - https://apt.grafana.com/gpg.key | \
gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null

echo "📦 Adding repo..."
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | \
sudo tee /etc/apt/sources.list.d/grafana.list > /dev/null

sudo apt update -y
sudo apt install -y grafana

sudo systemctl daemon-reload
sudo systemctl enable grafana-server
sudo systemctl restart grafana-server

echo "✅ Grafana running on http://<EC2-IP>:3000"
echo "Login: admin / admin"