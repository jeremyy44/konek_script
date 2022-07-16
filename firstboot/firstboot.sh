#!/bin/bash

LG='\033[1;32m' # Light Green
RED='\033[0;31m' # Red
BLUE='\033[0;34m' # Blue
NC='\033[0m' # No Color

function config() {
    # Checks if the user is root
    if [ "$EUID" -ne 0 ]
    then echo -e "You are not root. Run 'su -' before running this script"
        exit
    fi

    # Updates the system
    echo -e "Updating..."
    if apt-get -qq update ; then
        echo -e "${LG}Updated succesfully!${NC}\n"
    else
        echo -e "${RED}Failed to update${NC}, deleting cdrom from /etc/apt/sources.list and retrying."
        echo -e "Retrying..."
        sed -i '5d' /etc/apt/sources.list
        if apt-get -qq update ; then
            echo -e "${LG}Updated succesfully!${NC}\n"
        else
            clear
            echo -e "${RED}Failed to update, please try again.${NC}"
            exit
        fi
    fi

    # Installs the necessary packages
    echo -e "Installing sudo..."
    apt-get -qq install sudo -y
    echo -e "${LG}Sudo installed succesfully!${NC}\n"

    # Adds the user to the sudo group
    echo -e "The user you created needs to be addes to the sudo group."
    username=$(who am i | awk '{print $1}')
    echo -e "Adding user ${BLUE}$username${NC} to sudoers..."
    if usermod -aG sudo $username ; then
        echo -e "${LG}Added succesfully!${NC}\n"
    else
        clear
        echo -e "${RED}Failed to add user to sudoers, please try again.${NC}"
        exit
    fi

    # Apends config to /etc/hosts
    echo -e "Adding config to /etc/hosts"
    echo -e "\n10.11.10.1      branch01\n10.11.10.2      branch02" >> /etc/hosts
    echo -e "${LG}Added succesfully!${NC}\n"
}

function interfaces_branch01() {
    # Apends config to /etc/network/interfaces
    echo -e "Adding config to /etc/network/interfaces"
    if cat interface-conf > /etc/network/interfaces ; then
        echo -e "${LG}Added succesfully!${NC}\n"
    else
        clear
        echo -e "${RED}Failed to add config to /etc/network/interfaces. The config file must be in the same directory as the script.${NC}"
        exit
    fi
    echo -e "Restarting the server. The IP might change.\n
    You can now go ahead and bootstrap the server once the server is done restarting."
    sudo reboot
}

function interfaces_branch02() {
    # Modifies the config file to the branch02 config
    echo -e "Modifying the ip adresses of branch02 in /etc/network/interfaces"
    sed -i 's/192.168.128.1/192.168.128.2/g' /etc/network/interfaces 
    sed -i 's/192.168.20.2/192.168.20.3/g' /etc/network/interfaces 
    sed -i 's/192.168.234.2/192.168.234.3/g' /etc/network/interfaces 
    sed -i 's/10.11.10.1/10.11.10.2/g' /etc/network/interfaces
    echo -e "${LG}Modified succesfully!${NC}\n"
    wait 1.2
    echo -e "Restarting the server. The IP might change.\n
    You can now go ahead and bootstrap the server once the server is done restarting."
    sudo reboot
}

# Starts the script
case $1 in
    [help] | -h | --help)
        echo -e "${BLUE}Usage:${NC}   ./firstboot.sh [OPTION]"
        echo -e "${BLUE}Options:${NC} --branch01\n         --branch02\n         --help"
        exit 0;;
    [branch01] | --branch01)
        echo -e "${LG}Starting configuration of branch01${NC}"
        config
        interfaces_branch01
        ;;
    [branch02] | --branch02)
        echo -e "${LG}Starting configuration of branch02${NC}"
        config
        interfaces_branch02
        ;;
    [Nothing] | "" | --Nothing)
        echo -e "${RED}You entered nothing${NC}. You need to specify a branch ex: ./firstboot.sh --branch01"
        exit 1;;
    *)
        echo -e "${RED}Invalid argument.${NC} You need to specify which branch you are configuring ex. --branch01 or --help"
        exit 1;;
esac