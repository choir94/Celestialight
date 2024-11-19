#!/bin/bash
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5
# ================================
# Celestia Light Node Installer
# Screen Name: airdropnode_tia
# ================================

# Warna untuk tampilan
RED='\033[0;31m'
LIGHT_GREEN='\033[1;32m'
LIGHT_YELLOW='\033[1;33m'
BLUE='\033[1;34m'
WHITE='\033[1;37m'
LIGHT_CYAN='\033[1;36m'  # Warna cyan muda
LIGHT_MAGENTA='\033[1;35m'  # Warna magenta muda
NC='\033[0m' # Reset warna

# Log file path dan ukuran maksimum log
LOGFILE="$HOME/celestia-node.log"
MAX_LOG_SIZE=52428800  # 50MB

# Fungsi untuk log pesan ke file
log_message() {
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE"
}

# Rotasi file log jika ukurannya melebihi batas
rotate_log_file() {
    if [ -f "$LOGFILE" ] && [ $(stat -c%s "$LOGFILE") -ge $MAX_LOG_SIZE ]; then
        mv "$LOGFILE" "$LOGFILE.bak"
        touch "$LOGFILE"
        log_message "Log file rotated. Previous log archived as $LOGFILE.bak"
    fi
}

# Cleanup file sementara dan skrip
cleanup() {
    log_message "Cleaning up temporary files and removing script..."
    rm -f "$0"
    log_message "Cleanup completed."
}

# ================================
# Ambil Versi Terbaru dari GitHub
# ================================

echo -e "${BLUE}Fetching the latest version from GitHub...${NC}"
VERSION=$(curl -s "https://api.github.com/repos/celestiaorg/celestia-node/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$VERSION" ]; then
    echo -e "${RED}Failed to fetch the latest version. Exiting.${NC}"
    log_message "Failed to fetch the latest version."
    cleanup
    exit 1
fi

echo -e "${LIGHT_GREEN}Latest version fetched: ${WHITE}$VERSION${NC}"
log_message "Fetched latest version: $VERSION"

# ============================
# Cek Instalasi yang Sudah Ada
# ============================

check_existing_installation() {
    echo -e "\n${BLUE}Checking for existing installation...${NC}"
    if [ -d "$HOME/airdropnode_tia" ] || [ ! -z "$(sudo docker ps -q --filter ancestor=ghcr.io/celestiaorg/celestia-node:$VERSION)" ]; then
        echo -e "${LIGHT_YELLOW}Existing installation detected. Installation aborted.${NC}"
        log_message "Existing installation detected. Aborting."
        cleanup
        exit 0
    fi
    echo -e "${LIGHT_GREEN}No existing installation found. Proceeding...${NC}"
}

# ================================
# Fungsi Instalasi dan Konfigurasi
# ================================

install_dependencies() {
    echo -e "\n${BLUE}Installing system dependencies...${NC}"
    log_message "Installing system dependencies..."
    sudo apt update -y >/dev/null 2>&1 && sudo apt upgrade -y >/dev/null 2>&1
    sudo apt-get install -y curl tar wget aria2 clang pkg-config libssl-dev jq build-essential git make ncdu screen >/dev/null 2>&1
    echo -e "${LIGHT_GREEN}System dependencies installed successfully.${NC}"
    log_message "System dependencies installed."
}

install_docker() {
    echo -e "\n${BLUE}Checking Docker installation...${NC}"
    if ! command -v docker &> /dev/null; then
        echo -e "${LIGHT_YELLOW}Docker not found. Installing Docker...${NC}"
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update >/dev/null 2>&1
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io >/dev/null 2>&1
        echo -e "${LIGHT_GREEN}Docker installed successfully.${NC}"
        log_message "Docker installed."
    else
        echo -e "${LIGHT_GREEN}Docker is already installed.${NC}"
        log_message "Docker already installed."
    fi
}

install_nodejs() {
    echo -e "\n${BLUE}Checking Node.js installation...${NC}"
    if ! command -v node &> /dev/null; then
        echo -e "${LIGHT_YELLOW}Node.js not found. Installing Node.js...${NC}"
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs >/dev/null 2>&1
        echo -e "${LIGHT_GREEN}Node.js installed successfully.${NC}"
        log_message "Node.js installed."
    else
        echo -e "${LIGHT_GREEN}Node.js is already installed.${NC}"
        log_message "Node.js already installed."
    fi
}

install_docker_compose() {
    echo -e "\n${BLUE}Checking Docker Compose installation...${NC}"
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${LIGHT_YELLOW}Docker Compose not found. Installing Docker Compose...${NC}"
        curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        echo -e "${LIGHT_GREEN}Docker Compose installed successfully.${NC}"
        log_message "Docker Compose installed."
    else
        echo -e "${LIGHT_GREEN}Docker Compose is already installed.${NC}"
        log_message "Docker Compose already installed."
    fi
}

# ================================
# Setup dan Jalankan Celestia Node
# ================================

setup_celestia_node() {
    echo -e "\n${BLUE}Setting up Celestia Light Node...${NC}"
    log_message "Setting up Celestia Light Node..."
    export NETWORK=celestia
    export NODE_TYPE=light
    export RPC_URL=http://public-celestia-consensus.numia.xyz

    mkdir -p $HOME/airdropnode_tia
    sudo chown 10001:10001 $HOME/airdropnode_tia

    OUTPUT=$(sudo docker run -e NODE_TYPE=$NODE_TYPE -e P2P_NETWORK=$NETWORK \
        -v $HOME/airdropnode_tia:/home/celestia \
        ghcr.io/celestiaorg/celestia-node:$VERSION \
        celestia light init --p2p.network $NETWORK)

    echo -e "\n${LIGHT_CYAN}==============  IMPORTANT  ==============${NC}"
    echo -e "${LIGHT_MAGENTA}Save your wallet information securely:${NC}"
    echo -e "${WHITE}==============================${NC}"
    echo -e "${LIGHT_CYAN}NAME and ADDRESS:${NC}"
    echo -e "$(echo "$OUTPUT" | grep -E 'NAME|ADDRESS')"
    echo -e "${RED}MNEMONIC (SAVE IT SECURELY):${NC}"
    echo -e "${LIGHT_GREEN}$(echo "$OUTPUT" | sed -n '/MNEMONIC (save this somewhere safe!!!):/,$p' | tail -n +2)${NC}"
    echo -e "\n${LIGHT_MAGENTA}==============================${NC}"

    while true; do
        echo -e "\n${WHITE}Did you save your mnemonic phrase? (yes/no): ${NC}"
        read -p "" yn
        case $yn in
            [Yy]*)
                echo -e "${LIGHT_GREEN}Thank you! Proceeding...${NC}"
                break
                ;;
            [Nn]*)
                echo -e "${RED}Please save your mnemonic phrase before proceeding.${NC}"
                ;;
            *)
                echo -e "${LIGHT_YELLOW}Please answer yes or no.${NC}"
                ;;
        esac
    done
}

start_celestia_node() {
    echo -e "\n${BLUE}Starting Celestia Light Node...${NC}"
    screen -S airdropnode_tia -dm bash -c "sudo docker run -e NODE_TYPE=$NODE_TYPE -e P2P_NETWORK=$NETWORK \
        -v $HOME/airdropnode_tia:/home/celestia \
        ghcr.io/celestiaorg/celestia-node:$VERSION \
        celestia light start --core.ip $RPC_URL --p2p.network $NETWORK"
    echo -e "${LIGHT_GREEN}Node Started!${NC}"
    echo -e "${LIGHT_GREEN}To view logs, use: screen -r airdropnode_tia${NC}"
}

# ================================
# Gabung ke Saluran Airdrop Node Telegram
# ================================

join_telegram_channel() {
    echo -e "\n${BLUE}Join the Airdrop Node Telegram channel for updates and support!${NC}"
    echo -e "${LIGHT_CYAN}Visit: ${WHITE}https://t.me/airdrop_node${NC}"
}

# ================================
# Main Program
# ================================

rotate_log_file
install_dependencies
install_docker
install_nodejs
install_docker_compose
check_existing_installation
setup_celestia_node
start_celestia_node
join_telegram_channel
cleanup
