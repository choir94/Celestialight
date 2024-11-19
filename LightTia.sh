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

# Ensure screen is installed
ensure_screen_installed() {
    if ! command -v screen &>/dev/null; then
        echo -e "${YELLOW}Installing screen...${NORMAL}"
        sudo apt update && sudo apt install screen -y
    fi
}

# Start or attach to a screen session
start_or_attach_screen() {
    SCREEN_SESSION_NAME="lightnode-celestia"

    # Check if inside a screen session
    if [ "$STY" ]; then
        echo -e "${YELLOW}Running inside screen session: $SCREEN_SESSION_NAME${NORMAL}"
    else
        # Check if the screen session already exists
        if screen -list | grep -q "$SCREEN_SESSION_NAME"; then
            echo -e "${YELLOW}Attaching to existing screen session: $SCREEN_SESSION_NAME${NORMAL}"
            screen -r "$SCREEN_SESSION_NAME"
        else
            echo -e "${YELLOW}Starting a new screen session: $SCREEN_SESSION_NAME${NORMAL}"
            screen -S "$SCREEN_SESSION_NAME" -dm bash -c "$0 internal-run"
            screen -r "$SCREEN_SESSION_NAME"
        fi
        exit 0
    fi
}

# Main installation logic
main_installation() {
    # Display logo inside screen
    display_logo

    echo -e "\n${YELLOW}Choose an option:${NORMAL}"
    echo -e "  ${WHITE}1)${NORMAL} Import Wallet from Mnemonic"
    echo -e "  ${WHITE}2)${NORMAL} Create New Wallet\n"
    read -p "Enter your choice (1/2): " wallet_choice

    case $wallet_choice in
        1) 
            echo -e "\n${YELLOW}Enter your mnemonic phrase:${NORMAL}"
            read -p "Mnemonic: " mnemonic

            echo -e "${YELLOW}Importing wallet...${NORMAL}"
            sudo docker run -e NODE_TYPE=light -e P2P_NETWORK=celestia \
                -v $HOME/my-node-store:/home/celestia \
                ghcr.io/celestiaorg/celestia-node:latest \
                celestia light init --p2p.network celestia --recover --mnemonic "$mnemonic"

            if [ $? -eq 0 ]; then
                echo -e "${YELLOW}Wallet imported successfully.${NORMAL}"
                log_message "Wallet imported using mnemonic phrase."
            else
                echo -e "${RED}Failed to import wallet. Please check your mnemonic.${NORMAL}"
                log_message "Failed to import wallet."
            fi
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
    ensure_screen_installed
    start_or_attach_screen
fi
