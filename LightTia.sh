#!/bin/bash

# Define colors and styles
RED="\033[31m"
YELLOW="\033[33m"
WHITE="\033[37m"
NORMAL="\033[0m"
BOLD="\033[1m"

# Logfile
LOGFILE="$HOME/celestia-node.log"
MAX_LOG_SIZE=52428800  # 50MB

# Display logo
display_logo() {
    curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
    sleep 5
}

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

# Start script in a screen session
start_in_screen() {
    SCREEN_SESSION_NAME="lightnode-celestia"

    # Check if the script is already running in a screen session
    if [ "$STY" ]; then
        echo -e "${YELLOW}Running inside a screen session...${NORMAL}"
    else
        # Start a new screen session
        echo -e "${YELLOW}Starting script in a new screen session: $SCREEN_SESSION_NAME${NORMAL}"
        screen -dmS "$SCREEN_SESSION_NAME" bash -c "$0 internal-run"
        echo -e "${WHITE}You can attach to the screen session using:${NORMAL} screen -r $SCREEN_SESSION_NAME"
        exit 0
    fi
}

# Main installation logic
main_installation() {
    echo -e "\n${YELLOW}Choose an option:${NORMAL}"
    echo -e "  ${WHITE}1)${NORMAL} Import Wallet from Mnemonic"
    echo -e "  ${WHITE}2)${NORMAL} Create New Wallet\n"
    read -p "Enter your choice (1/2): " wallet_choice

    case $wallet_choice in
        1) 
            echo -e "\n${YELLOW}Enter your mnemonic phrase:${NORMAL}"
            read -p "Mnemonic: " mnemonic
            log_message "Wallet imported using mnemonic phrase."
            ;;
        2) 
            echo -e "\n${YELLOW}Creating a new wallet...${NORMAL}\n"
            OUTPUT=$(sudo docker run -e NODE_TYPE=light -e P2P_NETWORK=celestia \
                -v $HOME/my-node-store:/home/celestia \
                ghcr.io/celestiaorg/celestia-node:latest \
                celestia light init --p2p.network celestia)

            echo -e "${RED}Please save your wallet information and mnemonics securely.${NORMAL}\n"
            echo -e "${BOLD}${WHITE}NAME and ADDRESS:${NORMAL}"
            echo -e "${WHITE}$(echo "$OUTPUT" | grep -E 'NAME|ADDRESS')${NORMAL}\n"
            echo -e "${BOLD}${RED}MNEMONIC (save this somewhere safe!!!):${NORMAL}"
            echo -e "${WHITE}$(echo "$OUTPUT" | sed -n '/MNEMONIC (save this somewhere safe!!!):/,$p' | tail -n +2)${NORMAL}\n"
            log_message "New wallet created."
            ;;
        *) 
            echo -e "\n${RED}Invalid choice. Exiting.${NORMAL}\n"
            exit 1
            ;;
    esac

    log_message "Proceeding with Celestia node setup..."
}

# Entry point
if [ "$1" == "internal-run" ]; then
    main_installation
else
    display_logo
    start_in_screen
fi
