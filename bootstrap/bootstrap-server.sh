#!/bin/bash

read -p "Did you create the hotel's recipe and its dialplan before running this script? (y/n): " -n 1 -r REPLY
if [ "$REPLY" == "y" ]; then
    read -p "Which branch are you configuring? (ex branch01): " branch
    read -p "Enter the IP address of the bootstrap server: " bootstrap_ip
    read -p "Enter server's hostname without branch0x: " hostname
    read -p "Enter the user of the server: " user

    echo -e "\nknife bootstrap -N $branch-$hostname -r "role[NOC1],noc1,konek-reversessh::client,konek-branch::branch-$hostname" --ssh-user $user $bootstrap_ip --sudo -p22\n"
    read -p "Does the command above look correct? (y/n):" -n 1 -r REPLY
    if [ "$REPLY" == "y" ]; then
        clear
        knife bootstrap -N $branch-$hostname -r "role[NOC1],noc1,konek-reversessh::client,konek-branch::branch-$hostname" --ssh-user $user $bootstrap_ip --sudo -p22
    else if [ "$REPLY" == "n" ]; then
            echo "Please try again."
            exit 1
        else
            echo "Please try again."
            exit 1
        fi
    fi
else if [ "$REPLY" == "n" ]; then
        echo "Please do so if you want to run this script."
        exit 1
    else
        echo "Optin not recognized. Please try again."
        exit 1
    fi
fi




