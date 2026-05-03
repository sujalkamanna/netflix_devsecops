#!/bin/bash
set -e

echo "🔄 Updating system..."
sudo apt update -y
sudo apt upgrade -y

echo "📦 Installing base dependencies..."
sudo apt install -y \
    unzip curl wget gnupg software-properties-common \
    ca-certificates lsb-release apt-transport-https fontconfig

# =========================================================
# ☕ Install Java 21 (Required for Jenkins)
# =========================================================
echo "☕ Installing Java 21..."
sudo apt install -y openjdk-21-jre
java -version

# =========================================================
# 🛠 Install Jenkins (Latest - 2026 Key)
# =========================================================
echo "🛠 Installing Jenkins..."

sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key

echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/" | \
  sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update
sudo apt install -y jenkins

sudo systemctl start jenkins
sudo systemctl enable jenkins

# =========================================================
# ☁️ Install AWS CLI v2 (Official Method)
# =========================================================
echo "☁️ Installing AWS CLI..."

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -o awscliv2.zip
sudo ./aws/install
aws --version

# =========================================================
# 🏗 Install Terraform (Official Repo)
# =========================================================
echo "🏗 Installing Terraform..."

wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

echo "deb [arch=$(dpkg --print-architecture) \
signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com \
$(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update
sudo apt install -y terraform
terraform -version

# =========================================================
# ☸️ Install kubectl (Latest Stable)
# =========================================================
echo "☸️ Installing kubectl..."

KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)

curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"

chmod +x kubectl
sudo mv kubectl /usr/local/bin/

kubectl version --client

# =========================================================
# 🐳 Install Docker (Official Repo)
# =========================================================
echo "🐳 Installing Docker..."

sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
"deb [arch=$(dpkg --print-architecture) \
signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl start docker
sudo systemctl enable docker

# Add users to Docker group
sudo usermod -aG docker ubuntu
sudo usermod -aG docker jenkins

docker --version

# =========================================================
# 🔐 Install Trivy (Latest)
# =========================================================
echo "🔐 Installing Trivy..."

curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | \
sudo sh -s -- -b /usr/local/bin

trivy --version

# =========================================================
# 🧹 Cleanup
# =========================================================
rm -rf aws awscliv2.zip kubectl

# =========================================================
# 🎉 Final Output
# =========================================================
echo "✅ FULL DEVOPS SETUP COMPLETE!"

echo "👉 Jenkins: http://<your-ec2-public-ip>:8080"
echo "👉 Jenkins Password:"
echo "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"

echo "👉 Verify tools:"
echo "aws --version"
echo "terraform -version"
echo "kubectl version --client"
echo "docker --version"
echo "trivy --version"