#!/usr/bin/env bash

WORKDIR=/home/$USERID

SCRIPT_NAME=`basename "$0"`
## Log file definition
LOGFILE=$WORKDIR/$SCRIPT_NAME-`date +%Y-%m-%d_%Hh%Mm`.log

## Logging and ECHO functionality combined.
printl() {
    printf "\n%s" "$1"
    echo -e "$1" >> $LOGFILE
}
## Get Operating System information.
. /etc/os-release
OPSYS=${ID^^}
# printl "OPSYS: $OPSYS"


printstatus() {
    h=$(($SECONDS/3600));
    m=$((($SECONDS/60)%60));
    s=$(($SECONDS%60));
    printf "\r\n${BIGreen}==\r\n== ${BIYellow}$1"
    printf "\r\n${BIGreen}== ${IBlue}Total: %02dh:%02dm:%02ds Cores: $ACTIVECORES \r\n${BIGreen}==${IWhite}\r\n\r\n"  $h $m $s;
    printl ""
    printl "############################################################"
    printl "$1"
    printl ""
}

################################################################################
# Configure to use the MAC address for DHCP.
################################################################################

## Module Functions
macDHCPOSCheck() {
    ## Check if the required OS is Raspbian.
    printl "  - $MODULE_NAME: Check OS is Ubuntu."
    if [[ $OPSYS == *"UBUNTU"* ]]; then
        printl "    - $MODULE_NAME: OS is $OPSYS."
        MACDHCP_OS_CHECK="true"
    else
        printl "    - $MODULE_NAME: Incorrect OS: $OPSYS."
        MACDHCP_OS_CHECK="false"
    fi
}

macDHCPFileCheck() {
    ## Check if the configuration file exists.
    if [ ! -f /etc/netplan/50-cloud-init.yaml ]; then
        printl "    - $MODULE_NAME: Configuration file does not exist."
        MACDHCP_CONFILE_INST="false"
    else
        printl "    - $MODULE_NAME: Configuration file exists."
        MACDHCP_CONFILE_INST="true"
    fi
}

macDHCPAlreadyInstalled() {
    printl "    - $MODULE_NAME: Check if already configured."
    ## Check if the macDHCP is already configured.
    grep -Fxq "$CONF_STRING_2" "$CONF_FILE"
    if [ $? -eq 0 ]; then
        printl "    - $MODULE_NAME: Already configured."
        MACDHCP_CONF="true"
    else
        printl "    - $MODULE_NAME: Not yet configured."
        MACDHCP_CONF="false"
    fi
}

macDHCPChangeConfig() {
    ## Insert line after match found
    # sed '/^anothervalue=.*/a after=me' test.txt
    ## Increase macDHCP capacity
    printl "    - $MODULE_NAME: Change capacity."

    ## Check for SIZE value in the config file and make the modifications.

    # printl "String 1: $CONF_STRING_1"
    # printl "String 2: $CONF_STRING_2"
    # printl "File    : $CONF_FILE"
    # read -p "Press ENTER to continue ..."

    if grep -Fq "$CONF_STRING_1" "$CONF_FILE"; then
        # Replace the line with the new value.
        sudo sed -i "/${CONF_STRING_1}/a\\$CONF_STRING_2" "$CONF_FILE"
        # cat $CONF_FILE
        # read -p "Press ENTER to continue ..."

        ## Check and log success.
        if [ $? -eq 0 ]; then
            printl "    - $MODULE_NAME: Configuration succesfully changed."
            CONF_CHANGE_SUCCES="true"
            #netplan apply
        else
            printl "    - $MODULE_NAME: Misconfiguration. No changes made to configuration."
            CONF_CHANGE_SUCCES="false"
            return ## Exit function on ERROR.
        fi
        ## Have the script reboot at the end.
        REBOOTREQUIRED=1
    else
        printl "    - $MODULE_NAME: ERROR - Size value not found in conf file."
    fi
}

################################################################################
## Module Logic

macDHCP() {
    printstatus "Configure DHCP with MAC address"
    MODULE_NAME=macDHCP
    CONF_FILE="/etc/netplan/50-cloud-init.yaml"
    CONF_STRING_1='            dhcp4: true'
    CONF_STRING_2='            dhcp-identifier: mac'
    macDHCPOSCheck ## Check if the required OS is Ubuntu.

    if [[ $MACDHCP_OS_CHECK == "true" ]]; then
        ## Correct OS to install on.
        macDHCPFileCheck ## Check if the required configuraiton file exists.
        if [[ $MACDHCP_CONFILE_INST == "true" ]]; then
            ## Configuration file exists.
            macDHCPAlreadyInstalled ## Check if the macDHCP is already installed.
            if [[ $MACDHCP_CONF == "false" ]]; then
                ## macDHCP is not yet configured.
                printl "    - $MODULE_NAME: Initiate config change"
                macDHCPChangeConfig ## Change macDHCP capacity.
            fi
        else
            printl "    - $MODULE_NAME: ERROR - No configuration file. Exit here."
            return ## Exit function on ERROR.
        fi
    else
        printl "    - $MODULE_NAME: ERROR - Incorrect OS. Exit here."
        return ## Exit function on ERROR.
    fi

    ## Cleanup variables
    CONF_FILE=""
    MODULE_NAME=""
    CONF_STRING_1=""
    CONF_STRING_2=""
    macDHCP_INSTALLED=""
    MACDHCP_OS_CHECK=""
    MACDHCP_CONF=""
    CONF_CHANGE_SUCCES=""
    MACDHCP_CONFILE_INST=""
}

MYMENU=MACDHCP

if [[ $MYMENU == *"MACDHCP"* ]]; then
    macDHCP
fi

