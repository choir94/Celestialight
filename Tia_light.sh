#!/bin/bash

# ================================
# Instalasi Node Celestia Light
# Nama Screen: airdropnode_tia
# ================================

# Warna untuk tampilan
MERAH='\033[0;31m'
HIJAU_MUDA='\033[1;32m'
KUNING_MUDA='\033[1;33m'
BIRU='\033[1;34m'
PUTIH='\033[1;37m'
CYAN_MUDA='\033[1;36m'  # Warna cyan muda
MAGENTA_MUDA='\033[1;35m'  # Warna magenta muda
NC='\033[0m' # Reset warna

# Lokasi file log dan ukuran maksimum log
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
        log_message "File log diputar. Log sebelumnya diarsipkan sebagai $LOGFILE.bak"
    fi
}

# Pembersihan file sementara dan skrip
cleanup() {
    log_message "Membersihkan file sementara dan menghapus skrip..."
    rm -f "$0"
    log_message "Pembersihan selesai."
}

# ================================
# Ambil Versi Terbaru dari GitHub
# ================================

echo -e "${BIRU}Mengambil versi terbaru dari GitHub...${NC}"
VERSION=$(curl -s "https://api.github.com/repos/celestiaorg/celestia-node/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$VERSION" ]; then
    echo -e "${MERAH}Gagal mengambil versi terbaru. Keluar.${NC}"
    log_message "Gagal mengambil versi terbaru."
    cleanup
    exit 1
fi

echo -e "${HIJAU_MUDA}Versi terbaru diambil: ${PUTIH}$VERSION${NC}"
log_message "Versi terbaru diambil: $VERSION"

# ============================
# Cek Instalasi yang Sudah Ada
# ============================

check_existing_installation() {
    echo -e "\n${BIRU}Mengecek instalasi yang sudah ada...${NC}"
    if [ -d "$HOME/airdropnode_tia" ] || [ ! -z "$(sudo docker ps -q --filter ancestor=ghcr.io/celestiaorg/celestia-node:$VERSION)" ]; then
        echo -e "${KUNING_MUDA}Instalasi yang sudah ada terdeteksi. Instalasi dibatalkan.${NC}"
        log_message "Instalasi yang sudah ada terdeteksi. Membatalkan."
        cleanup
        exit 0
    fi
    echo -e "${HIJAU_MUDA}Instalasi tidak ditemukan. Melanjutkan...${NC}"
}

# ================================
# Fungsi Instalasi dan Konfigurasi
# ================================

install_dependencies() {
    echo -e "\n${BIRU}Memasang dependensi sistem...${NC}"
    log_message "Memasang dependensi sistem..."
    sudo apt update -y >/dev/null 2>&1 && sudo apt upgrade -y >/dev/null 2>&1
    sudo apt-get install -y curl tar wget aria2 clang pkg-config libssl-dev jq build-essential git make ncdu screen >/dev/null 2>&1
    echo -e "${HIJAU_MUDA}Dependensi sistem berhasil dipasang.${NC}"
    log_message "Dependensi sistem berhasil dipasang."
}

install_docker() {
    echo -e "\n${BIRU}Mengecek instalasi Docker...${NC}"
    if ! command -v docker &> /dev/null; then
        echo -e "${KUNING_MUDA}Docker tidak ditemukan. Memasang Docker...${NC}"
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update >/dev/null 2>&1
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io >/dev/null 2>&1
        echo -e "${HIJAU_MUDA}Docker berhasil dipasang.${NC}"
        log_message "Docker berhasil dipasang."
    else
        echo -e "${HIJAU_MUDA}Docker sudah terpasang.${NC}"
        log_message "Docker sudah terpasang."
    fi
}

install_nodejs() {
    echo -e "\n${BIRU}Mengecek instalasi Node.js...${NC}"
    if ! command -v node &> /dev/null; then
        echo -e "${KUNING_MUDA}Node.js tidak ditemukan. Memasang Node.js...${NC}"
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs >/dev/null 2>&1
        echo -e "${HIJAU_MUDA}Node.js berhasil dipasang.${NC}"
        log_message "Node.js berhasil dipasang."
    else
        echo -e "${HIJAU_MUDA}Node.js sudah terpasang.${NC}"
        log_message "Node.js sudah terpasang."
    fi
}

install_docker_compose() {
    echo -e "\n${BIRU}Mengecek instalasi Docker Compose...${NC}"
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${KUNING_MUDA}Docker Compose tidak ditemukan. Memasang Docker Compose...${NC}"
        curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        echo -e "${HIJAU_MUDA}Docker Compose berhasil dipasang.${NC}"
        log_message "Docker Compose berhasil dipasang."
    else
        echo -e "${HIJAU_MUDA}Docker Compose sudah terpasang.${NC}"
        log_message "Docker Compose sudah terpasang."
    fi
}

# ================================
# Setup dan Jalankan Celestia Node
# ================================

setup_celestia_node() {
    echo -e "\n${BIRU}Menyetel Node Celestia Light...${NC}"
    log_message "Menyetel Node Celestia Light..."
    export NETWORK=celestia
    export NODE_TYPE=light
    export RPC_URL=http://public-celestia-consensus.numia.xyz

    mkdir -p $HOME/airdropnode_tia
    sudo chown 10001:10001 $HOME/airdropnode_tia

    OUTPUT=$(sudo docker run -e NODE_TYPE=$NODE_TYPE -e P2P_NETWORK=$NETWORK \
        -v $HOME/airdropnode_tia:/home/celestia \
        ghcr.io/celestiaorg/celestia-node:$VERSION \
        celestia light init --p2p.network $NETWORK)

    echo -e "\n${CYAN_MUDA}==============  PENTING  ==============${NC}"
    echo -e "${MAGENTA_MUDA}Simpan informasi dompet Anda dengan aman:${NC}"
    echo -e "${PUTIH}==============================${NC}"
    echo -e "${CYAN_MUDA}NAMA dan ALAMAT:${NC}"
    echo -e "$(echo "$OUTPUT" | grep -E 'NAME|ADDRESS')"
    echo -e "${MERAH}MNEMONIC (SIMPAN DENGAN AMAN):${NC}"
    echo -e "${HIJAU_MUDA}$(echo "$OUTPUT" | sed -n '/MNEMONIC (save this somewhere safe!!!):/,$p' | tail -n +2)${NC}"
    echo -e "\n${MAGENTA_MUDA}==============================${NC}"

    while true; do
        echo -e "\n${PUTIH}Apakah Anda sudah menyimpan mnemonic phrase Anda? (ya/tidak): ${NC}"
        read -p "" yn
        case $yn in
            [Yy]*)
                echo -e "${HIJAU_MUDA}Terima kasih! Melanjutkan...${NC}"
                break
                ;;
            [Nn]*)
                echo -e "${MERAH}Simpan mnemonic phrase Anda sebelum melanjutkan.${NC}"
                ;;
            *)
                echo -e "${KUNING_MUDA}Harap jawab ya atau tidak.${NC}"
                ;;
        esac
    done
}

start_celestia_node() {
    echo -e "\n${BIRU}Menjalankan Node Celestia...${NC}"
    log_message "Menjalankan Node Celestia..."
    sudo docker run -d --name airdropnode_tia --restart always \
        -v $HOME/airdropnode_tia:/home/celestia \
        -p 26656:26656 -p 26657:26657 \
        ghcr.io/celestiaorg/celestia-node:$VERSION node
    echo -e "${HIJAU_MUDA}Node Celestia telah dijalankan.${NC}"
}

join_airdrop_node_channel() {
    echo -e "\n${CYAN_MUDA}Silakan bergabung dengan channel Airdrop Node untuk pembaruan dan dukungan:${NC}"
    echo -e "${HIJAU_MUDA}https://t.me/airdrop_node${NC}"
}

# ================================
# Instalasi dan Setup Proses
# ================================

check_existing_installation
install_dependencies
install_docker
install_nodejs
install_docker_compose
setup_celestia_node
start_celestia_node
join_airdrop_node_channel
log_message "Instalasi dan setup Node Celestia selesai."

cleanup

