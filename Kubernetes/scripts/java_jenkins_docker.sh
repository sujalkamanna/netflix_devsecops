#!/bin/bash
set -e

echo "🔄 Updating system..."
sudo apt update -y

echo "📦 Installing dependencies..."
sudo apt install -y curl wget gnupg ca-certificates software-properties-common

# =========================================================
# ☕ Install Java (RECOMMENDED FOR JENKINS)
# =========================================================
echo "☕ Installing OpenJDK 21 (LTS)..."

sudo apt install -y openjdk-21-jdk

echo "✅ Java Installed:"
java -version

# Jenkins requires Java to run and supports Java 17/21 LTS :contentReference[oaicite:0]{index=0}

# =========================================================
# 🛠 Install Jenkins (LATEST FIXED METHOD)
# =========================================================
echo "🛠 Installing Jenkins..."

# Create keyring directory
sudo mkdir -p /etc/apt/keyrings

# Add Jenkins GPG key (NEW signing system)
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key | \
sudo tee /etc/apt/keyrings/jenkins-keyring.asc > /dev/null

# Add Jenkins repository
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] \
https://pkg.jenkins.io/debian-stable binary/" | \
sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Update & install Jenkins
sudo apt update
sudo apt install -y jenkins

# Start & enable Jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins

echo "✅ Jenkins Installed:"
sudo systemctl status jenkins --no-pager

# Jenkins runs as a service on port 8080 by default :contentReference[oaicite:1]{index=1}

# =========================================================
# 🐳 Install Docker (OFFICIAL METHOD)
# =========================================================
echo "🐳 Installing Docker..."

# Remove old versions (if any)
sudo apt remove -y docker docker-engine docker.io containerd runc || true

# Add Docker GPG key
sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker repository (FIXED for your system)
echo "deb [arch=$(dpkg --print-architecture) \
signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu jammy stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start Docker
sudo systemctl enable docker
sudo systemctl start docker

# Add user to Docker group
sudo usermod -aG docker $USER

echo "✅ Docker Installed:"
docker --version

# =========================================================
# 🎉 FINAL OUTPUT
# =========================================================
echo "-----------------------------------"
echo "✅ ALL INSTALLATIONS COMPLETED"
echo "-----------------------------------"

echo "Java:"
java -version

echo "Jenkins:"
sudo systemctl status jenkins --no-pager | head -n 5

echo "Docker:"
docker --version

echo "-----------------------------------"

echo "👉 Jenkins URL: http://<EC2-IP>:8080"
echo "👉 Get Admin Password:"
echo "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"