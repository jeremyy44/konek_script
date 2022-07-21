#!/bin/bash
#--Script to run on first boot of the server--#
#--Author: Jeremyy44--#
#--Version: 1.5--#

LG='\033[1;32m' # Light Green
RED='\033[0;31m' # Red
BLUE='\033[0;34m' # Blue
YEL='\033[1;33m' # Yellow
NC='\033[0m' # No Color


read -e -p "Enter the username of the user you created or press enter for deault [deleteme]: " username
username=${username:-deleteme}
read -e -p "Enter the ip of the server you are configuring: " ip

if scp -r ~/.repo/konek-linux-tools/firstboot $username@$ip:/home/$username/ ; then
    echo -e "${LG}Firstboot has been copied to the server at /home/$username${NC}"
else
    echo -e "${RED}Failed to copy firstboot to the server.${NC}"
    exit 1
fi

echo -e "${LG}Running the script...${NC}"

ssh -t $username@$ip "su - -c /home/$username/firstboot/firstboot.sh"
echo -e "${LG}The script was ran succesfully. You can now bootstrape the server.${NC}"