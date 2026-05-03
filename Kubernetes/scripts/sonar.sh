#!/bin/bash
set -e

echo "🔄 Updating system..."
sudo apt update -y

# =========================================================
# 🔧 Kernel Settings (REQUIRED FOR SONARQUBE)
# =========================================================
echo "🔧 Configuring kernel settings..."

sudo tee /etc/sysctl.d/99-sonarqube.conf > /dev/null <<EOF
vm.max_map_count=524288
fs.file-max=131072
EOF

# Apply settings (modern way)
sudo sysctl --system

echo "🔍 Verifying kernel params..."
sysctl vm.max_map_count
sysctl fs.file-max

# =========================================================
# 🐳 Ensure Docker is running
# =========================================================
echo "🐳 Checking Docker..."

if ! command -v docker &> /dev/null
then
    echo "❌ Docker not found. Please install Docker first."
    exit 1
fi

sudo systemctl enable docker
sudo systemctl start docker

docker --version

# Fix docker permissions (no newgrp in script)
sudo usermod -aG docker $USER
echo "⚠️ Logout/Login required for Docker group changes to take effect"

# =========================================================
# 🧹 Cleanup old container
# =========================================================
echo "🧹 Cleaning old SonarQube container..."
docker rm -f sonar 2>/dev/null || true

# =========================================================
# 📦 Pull SonarQube Image
# =========================================================
echo "⬇️ Pulling SonarQube image..."
docker pull sonarqube:lts-community

# =========================================================
# 🚀 Run SonarQube
# =========================================================
echo "🚀 Starting SonarQube container..."

docker run -d \
  --name sonar \
  -p 9000:9000 \
  --restart unless-stopped \
  --memory=3g \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  sonarqube:lts-community

# =========================================================
# ⏳ Wait for startup
# =========================================================
echo "⏳ Waiting for SonarQube to start (60 sec)..."
sleep 60

# =========================================================
# 🔍 Verify container
# =========================================================
echo "📊 Container Status:"
docker ps

echo "📜 Last logs:"
docker logs sonar --tail 30

# =========================================================
# 🎉 DONE
# =========================================================
echo "-----------------------------------"
echo "✅ SonarQube Setup Completed"
echo "👉 URL: http://<EC2-IP>:9000"
echo "👉 Default Login: admin / admin"
echo "-----------------------------------"


# to run 
# chmod +x sonar.sh
# ./sonar.sh

# or

# bash sonar.sh