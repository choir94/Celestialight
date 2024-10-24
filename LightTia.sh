#!/bin/bash

# Define colors and styles
RED="\033[31m"
YELLOW="\033[33m"
GREEN="\033[32m"
NORMAL="\033[0m"
BOLD="\033[1m"
ITALIC="\033[3m"

# Logfile
LOGFILE="$HOME/celestia-node.log"
MAX_LOG_SIZE=52428800  # 50MB

log_message() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE"
}

# Rotate log file if it exceeds 50MB
rotate_log_file() {
    if [ -f "$LOGFILE" ] && [ $(stat -c%s "$LOGFILE") -ge $MAX_LOG_SIZE ]; then
        mv "$LOGFILE" "$LOGFILE.bak"
        touch "$LOGFILE"
        log_message "Log file rotated. Previous log archived as $LOGFILE.bak"
    fi
}

# Cleanup
cleanup() {
    log_message "Cleaning up temporary files and removing script..."
    rm -f "$0"  # Remove the script itself
    log_message "Cleanup completed."
}

# Wallet options: Import or create a new one
echo -e "${YELLOW}Choose an option:${NORMAL}"
echo -e "1) Import Wallet from Mnemonic"
echo -e "2) Create New Wallet"
read -p "Enter your choice (1/2): " wallet_choice

case $wallet_choice in
    1) 
        echo -e "${YELLOW}Enter your mnemonic phrase:${NORMAL}"
        read -p "Mnemonic: " mnemonic
        log_message "Wallet imported using mnemonic phrase."
        ;;
    2) 
        echo -e "${YELLOW}Creating a new wallet...${NORMAL}"
        OUTPUT=$(sudo docker run -e NODE_TYPE=light -e P2P_NETWORK=celestia \
            -v $HOME/my-node-store:/home/celestia \
            ghcr.io/celestiaorg/celestia-node:latest \
            celestia light init --p2p.network celestia)

        echo -e "${RED}Please save your wallet information and mnemonics securely.${NORMAL}"
        echo -e "${RED}NAME and ADDRESS:${NORMAL}"
        echo -e "${NORMAL}$(echo "$OUTPUT" | grep -E 'NAME|ADDRESS')${NORMAL}"
        echo -e "${RED}MNEMONIC (save this somewhere safe!!!):${NORMAL}"
        echo -e "${NORMAL}$(echo "$OUTPUT" | sed -n '/MNEMONIC (save this somewhere safe!!!):/,$p' | tail -n +2)${NORMAL}"
        log_message "New wallet created."
        ;;
    *) 
        echo -e "${RED}Invalid choice. Exiting.${NORMAL}"
        exit 1
        ;;
esac

# Continue with the setup process
log_message "Proceeding with Celestia node setup..."
