#!/bin/bash
#--Script to run on first boot of the server--#
#--Author: Jeremyy44--#
#--Version: 1.0--#

LG='\033[1;32m' # Light Green
RED='\033[0;31m' # Red
BLUE='\033[0;34m' # Blue
NC='\033[0m' # No Color

function config() {
    # Checks if the user is root
    if [ "$EUID" -ne 0 ]
    then echo -e "You are not root. Run 'su -' before running this script"
        exit 1
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
            echo -e "${RED}Failed to update, please try again.\n${NC}"
            exit 1
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
        exit 1
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
        exit 1
    fi
    echo -e "Restarting the server. The IP might change.\n
    You can now go ahead and bootstrap the server once the server is done restarting."
    sudo reboot
}

function interfaces_branch02() {
    # Modifies the config file to the branch02 config
    echo -e "Modifying the ip adresses of branch02 in /etc/network/interfaces"
    cat interface-conf > /etc/network/interfaces
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

function print_menu() { # selected_item, ...menu_items
	echo -e "${LG}Which branch are you configuring?\n${NC}"
	local function_arguments=($@)

	local selected_item="$1"
	local menu_items=(${function_arguments[@]:1})
	local menu_size="${#menu_items[@]}"

	for (( i = 0; i < $menu_size; ++i ))
	do
		if [ "$i" = "$selected_item" ]
		then
			echo "-> ${menu_items[i]}"
		else
			echo "   ${menu_items[i]}"
		fi
	done
}

function run_menu() { # selected_item, ...menu_items
	local function_arguments=($@)

	local selected_item="$1"
	local menu_items=(${function_arguments[@]:1})
	local menu_size="${#menu_items[@]}"
	local menu_limit=$((menu_size - 1))

	clear
	print_menu "$selected_item" "${menu_items[@]}"
	
	while read -rsn1 input
	do
		case "$input"
		in
			$'\x1B')  # ESC ASCII code (https://dirask.com/posts/ASCII-Table-pJ3Y0j)
				read -rsn1 -t 0.1 input
				if [ "$input" = "[" ]  # occurs before arrow code
				then
					read -rsn1 -t 0.1 input
					case "$input"
					in
						A)  # Up Arrow
							if [ "$selected_item" -ge 1 ]
							then
								selected_item=$((selected_item - 1))
								clear
								print_menu "$selected_item" "${menu_items[@]}"
							fi
							;;
						B)  # Down Arrow
							if [ "$selected_item" -lt "$menu_limit" ]
							then
								selected_item=$((selected_item + 1))
								clear
								print_menu "$selected_item" "${menu_items[@]}"
							fi
							;;
					esac
				fi
				read -rsn5 -t 0.1  # flushing stdin
				;;
			"")  # Enter key
				return "$selected_item"
				;;
		esac
	done
}

# Main script
selected_item=0
menu_items=('Branch01' 'Branch02' 'Cancel')

run_menu "$selected_item" "${menu_items[@]}"
menu_result="$?"

case "$menu_result" in
	0)
        clear
		echo -e "${LG}Starting configuration of branch01${NC}"
        config
        interfaces_branch01
        ;;
	1)
        clear
        echo -e "${LG}Starting configuration of branch02${NC}"
        config
        interfaces_branch02
        ;;
	2)
        clear
		echo 'Goodbye!'
		;;
esac
