#!/bin/bash

LG='\033[1;32m' # Light Green
RED='\033[0;31m' # Red
BLUE='\033[0;34m' # Blue
NC='\033[0m' # No Color

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
    echo -e "Failed to update, deleting cdrom from /etc/apt/sources.list and reruning update."
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

# Apends config to /etc/hosts and /etc/network/interfaces
echo -e "Adding config to /etc/hosts"
echo -e "10.11.10.1      branch01\n10.11.10.2      branch02" >> /etc/hosts
echo -e "${LG}Added succesfully!${NC}\n"

echo -e "Adding config to /etc/network/interfaces"
cat interface-conf > /etc/network/interfaces
echo -e "${LG}Added succesfully!${NC}\n"
echo -e "Restarting networking.service and getting new ip..."
systemctl restart networking.service && dhclient enp3s0f0
echo -e "${LG}Restarted succesfully!${NC}\n"

echo -e "${LG}Now time to bootstrap!${NC}"
