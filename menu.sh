#!/bin/bash

# Colors
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

show_menu() {
    clear
    echo -e "${CYAN}==========================================${NC}"
    echo -e "${YELLOW}   Gurbani Search - Build & Deploy Menu   ${NC}"
    echo -e "${CYAN}==========================================${NC}"
    echo -e "${GREEN}1. Clean & Fetch Dependencies (flutter clean & pub get)${NC}"
    echo -e "${GREEN}2. Build Shareable Android APK (.apk)${NC}"
    echo -e "${GREEN}3. Build Web & Deploy to Firebase Hosting${NC}"
    echo -e "${GREEN}4. Build Play Store App Bundle (.aab)${NC}"
    echo -e "${RED}5. Exit${NC}"
    echo -e "${CYAN}==========================================${NC}"
}

run_clean_and_pub_get() {
    echo -e "\n${CYAN}[1/2] Running 'flutter clean'...${NC}"
    flutter clean
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to clean flutter project.${NC}"
        return 1
    fi

    echo -e "\n${CYAN}[2/2] Running 'flutter pub get'...${NC}"
    flutter pub get
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to get pub dependencies.${NC}"
        return 1
    fi

    echo -e "\n${GREEN}Successfully cleaned and fetched dependencies!${NC}"
    return 0
}

pause_console() {
    echo -e "\nPress Enter to return to menu..."
    read -r
}

while true; do
    show_menu
    read -p "Select an option (1-5): " choice

    case $choice in
        1)
            run_clean_and_pub_get
            pause_console
            ;;
        2)
            if run_clean_and_pub_get; then
                echo -e "\n${CYAN}Building Shareable Android Release APK (.apk)...${NC}"
                flutter build apk --release
                if [ $? -eq 0 ]; then
                    echo -e "\n${GREEN}Shareable APK built successfully!${NC}"
                    echo -e "${YELLOW}Location: build/app/outputs/flutter-apk/app-release.apk${NC}"
                else
                    echo -e "\n${RED}Failed to build APK.${NC}"
                fi
            fi
            pause_console
            ;;
        3)
            if run_clean_and_pub_get; then
                echo -e "\n${CYAN}Building Web App for Firebase Hosting...${NC}"
                flutter build web
                if [ $? -eq 0 ]; then
                    echo -e "\n${CYAN}Deploying to Firebase Hosting...${NC}"
                    firebase deploy --only hosting
                    if [ $? -eq 0 ]; then
                        echo -e "\n${GREEN}Successfully deployed to Firebase Hosting!${NC}"
                    else
                        echo -e "\n${RED}Firebase deployment failed.${NC}"
                    fi
                else
                    echo -e "\n${RED}Failed to build Web App.${NC}"
                fi
            fi
            pause_console
            ;;
        4)
            if run_clean_and_pub_get; then
                echo -e "\n${CYAN}Building Play Store Android App Bundle (.aab)...${NC}"
                flutter build appbundle --release
                if [ $? -eq 0 ]; then
                    echo -e "\n${GREEN}Play Store App Bundle (.aab) built successfully!${NC}"
                    echo -e "${YELLOW}Location: build/app/outputs/bundle/release/app-release.aab${NC}"
                else
                    echo -e "\n${RED}Failed to build App Bundle.${NC}"
                fi
            fi
            pause_console
            ;;
        5)
            echo -e "\n${YELLOW}Exiting menu. Waheguru Ji Ka Khalsa, Waheguru Ji Ki Fateh!${NC}\n"
            exit 0
            ;;
        *)
            echo -e "\n${RED}Invalid choice. Please select an option between 1 and 5.${NC}"
            sleep 1
            ;;
    esac
done
