sudo apt install -y wget gnupg lsb-release

wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | \
gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] \
https://aquasecurity.github.io/trivy-repo/deb generic main" | \
sudo tee /etc/apt/sources.list.d/trivy.list

sudo apt update
sudo apt install -y trivy

# check all
echo "JAVA:" && java -version
echo "JENKINS:" && jenkins --version || dpkg -l | grep jenkins
echo "DOCKER:" && docker --version
echo "TRIVY:" && trivy --version
echo "KUBECTL:" && kubectl version --client
echo "AWS:" && aws --version
echo "TERRAFORM:" && terraform version
echo "EKSCTL:" && eksctl version