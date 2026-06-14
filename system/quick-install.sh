#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${WHITE}$1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run this script as root"
    exit 1
fi

# Update system
print_header "Updating System Packages"
print_status "Updating package lists..."
sudo apt update && sudo apt upgrade -y
print_success "System packages updated"

# Install Docker + Docker Compose
print_header "Installing Docker + Docker Compose"
print_status "Installing Docker prerequisites..."
sudo apt install apt-transport-https ca-certificates curl software-properties-common -y

print_status "Adding Docker GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

print_status "Adding Docker repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

print_status "Installing Docker packages..."
sudo apt update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

print_status "Enabling and starting Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

print_status "Adding user to docker group..."
sudo usermod -aG docker $USER

# Check Docker installation
print_status "Checking Docker installation..."
sudo docker --version
docker compose version
print_success "Docker + Docker Compose installed successfully"

# Install curl (if not already installed)
print_header "Installing curl"
if command -v curl &> /dev/null; then
    print_success "curl is already installed"
else
    print_status "Installing curl..."
    sudo apt-get install curl -y
    print_success "curl installed successfully"
fi

# Install Speedtest
print_header "Installing Speedtest CLI"
print_status "Adding Ookla repository..."
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
print_status "Installing Speedtest CLI..."
sudo apt-get install speedtest -y
print_success "Speedtest CLI installed successfully"

# Install Go
print_header "Installing Go Programming Language"
print_status "Downloading and installing Go..."
GO_VERSION="1.21.5"
wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
rm go${GO_VERSION}.linux-amd64.tar.gz

# Add Go to PATH if not already there
if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    echo 'export GOPATH=$HOME/go' >> ~/.bashrc
    echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc
fi

export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# Check Go installation
/usr/local/go/bin/go version
print_success "Go installed successfully"

# Install Node.js + NPM
print_header "Installing Node.js + NPM"
print_status "Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs

# Check Node.js installation
node --version
npm --version
print_success "Node.js + NPM installed successfully"

# Install Python (usually comes with Ubuntu, but ensure pip is installed)
print_header "Installing Python and pip"
print_status "Installing Python3, pip, and development tools..."
sudo apt-get install python3 python3-pip python3-venv python3-dev build-essential -y

# Check Python installation
python3 --version
pip3 --version
print_success "Python and pip installed successfully"

# Install rclone
print_header "Installing rclone"
print_status "Installing rclone..."
sudo apt-get install rclone -y

# Check rclone installation
rclone version
print_success "rclone installed successfully"

# Install jq
print_header "Installing jq"
print_status "Installing jq JSON processor..."
sudo apt-get install jq -y

# Check jq installation
jq --version
print_success "jq installed successfully"

# Install iputils (ping, traceroute, etc.)
print_header "Installing iputils"
print_status "Installing iputils package..."
sudo apt-get install iputils-ping iputils-tracepath iputils-arping -y
print_success "iputils installed successfully"

# Additional useful tools
print_header "Installing Additional Useful Tools"
print_status "Installing git, vim, htop, tree, and other utilities..."
sudo apt-get install git vim htop tree wget unzip zip rsync ssh openssh-client net-tools -y
print_success "Additional tools installed successfully"

# Final status check
print_header "Installation Summary"
echo -e "${CYAN}Installed software versions:${NC}"
echo -e "${WHITE}Docker:${NC} $(docker --version 2>/dev/null || echo 'Not available in current session')"
echo -e "${WHITE}Docker Compose:${NC} $(docker compose version 2>/dev/null || echo 'Not available in current session')"
echo -e "${WHITE}curl:${NC} $(curl --version | head -n1)"
echo -e "${WHITE}Speedtest:${NC} $(speedtest --version 2>/dev/null || echo 'Installed')"
echo -e "${WHITE}Go:${NC} $(/usr/local/go/bin/go version 2>/dev/null || echo 'Installed - restart terminal to use')"
echo -e "${WHITE}Node.js:${NC} $(node --version)"
echo -e "${WHITE}NPM:${NC} $(npm --version)"
echo -e "${WHITE}Python3:${NC} $(python3 --version)"
echo -e "${WHITE}pip3:${NC} $(pip3 --version | cut -d' ' -f1-2)"
echo -e "${WHITE}rclone:${NC} $(rclone --version | head -n1 | cut -d' ' -f1-2)"
echo -e "${WHITE}jq:${NC} $(jq --version)"
echo -e "${WHITE}ping:${NC} Available"

print_success "All installations completed successfully!"
print_warning "Please log out and log back in (or restart your terminal) to use Docker without sudo and to have Go available in your PATH."

echo -e "\n${GREEN}🎉 Setup complete! Your Ubuntu 24 development environment is ready.${NC}"
