#!/bin/bash
################################################################################
# Filename: theScript.sh
# Date Created: 27/apr/19
# Date last update: 2021-01-31
# Author: Marco Tijbout
#
# Version 0.9s
#
#            _   _          ____            _       _         _
#           | |_| |__   ___/ ___|  ___ _ __(_)_ __ | |_   ___| |__
#           | __| '_ \ / _ \___ \ / __| '__| | '_ \| __| / __| '_ \
#           | |_| | | |  __/___) | (__| |  | | |_) | |_ _\__ \ | | |
#            \__|_| |_|\___|____/ \___|_|  |_| .__/ \__(_)___/_| |_|
#                                            |_|
#
# Description: Script to show menu to select what modifications need to be
#              made to the OS.
#
# Usage: Run with SUDO.
#        The script requires internet connectivity.
#
# Enhancement ideas:
#   -Making all the action in to functions so the order can easyly be adjusted.
#   -AlreadyRun: Log what actions are already run. Ask double check.
#   -Using arguments for pre-selection of menu items and unattended run.
#
# Version history:
# 0.9s Marco Tijbout:
#   MACDHCP consider more possible configurations for ubuntu
#   DISAUPD - New module to disable automatic updates on ubuntu
#   TZADAM - New module to set timezone to Amsterdam
#   Changed module activation to one-liner
# 0.9r Marco Tijbout:
#   LOCAL_MIRROR Added support for Ubuntu on RPi
#   Removal of VMware Pulse stuff
# 0.9q Marco Tijbout:
#   Updated CUSTOM_ALIAS
#       - with new update command incl reboot notification
#       - alias to run the script from online
# 0.9p Marco Tijbout:
#   Updated how variables are cleared with unset
#   Updated the aliases
#   Fix ownership of log file
#   Introduce functionality based on architecture
# 0.9o Marco Tijbout:
#   Fixed IP addressing for CentOS
#   LOCAL_MIRROR: New module to add the local (NL) mirror to apt
#   DATETIME: Introduced the date and time of script execution stored in a
#   variableto be repurposed in the script.
#   ADD_CSCRIPT: Fixed variables not gettign over.
#   VMware Pulse: Disabled the section by removing the entry to the menu. Modules
#   are still available.
# 0.9n Marco Tijbout:
#   ADD_CSCRIPT: New moddule to add cscript to .bashrc
# 0.9m Marco Tijbout:
#   Added some aliases.
#   Change ownership to executor of theScript and not root.
# 0.9l Marco Tijbout:
#   Adapting for Arch Linux support.
# 0.9k Marco Tijbout:
#   Making everything modular with functions.
#   MACDHCP: New module to configure MAC address usage for DHCP requests.
# 0.9i Marco Tijbout:
#   First adaptions required for Photon OS.
# 0.9h Marco Tijbout:
#   First adaptions required for Photon OS.
# 0.9g Marco Tijbout:
#   HOST_RENAME: Provided inputbox for manual input of new hostname.
# 0.9f Marco Tijbout:
#   Replacing ECHO with printl for logging purposes.
#   REGENERATE_SSH_KEYS: Updated how to regenerate keys so all OSses work.
#   AGENT_UNINSTALL: Uninstall Agent from Gateway.
# 0.9e Marco Tijbout:
#   Password input boxes for creating the system administrator account
#   Password unput box for enrolling a gateway to Pulse.
# 0.9d Marco Tijbout:
#   Added color scheme to menu.
#   Added THING_UNENROLL: Unenrolling a Thing Device.
#   Added GATEWAY_UNENROLL: Unenrolling a Gateway Device.
#   Added comments to the sub actions for readability.
#   Added CENTOS check and adaptions for package manager.
# 0.9c Marco Tijbout:
#   SHOW_IP: Issues, but found an easier way. Just show all IPv4 addresses.
# 0.9b Marco Tijbout:
#   PULSE_AGENT: Revamped Pulse Agent downloading.
#   CUSTOM_ALIAS: Aliases for ease of use of command line.
#   SHOW_IP: Build check for OS differences in NIC names.
# 0.8  Marco Tijbout:
#   Version for testing in the field.
# 0.7  Marco Tijbout:
#   Optimized Pulse related parts.
# 0.5  Marco Tijbout:
#   Added sub-menu functionality
# 0.1  Marco Tijbout:
#   Initial creation of the script.
################################################################################

################################################################################
#                            - INITIAL ROUTINES -                              #
################################################################################
clear

## Version of theScript.sh
SCRIPT_VERSION="0.9s"
LAST_MODIFICATION="20210304-1833"

## The user that executed the script.
USERID=$(logname)
# if [ "$EUID" == 0 ]; then
#     WORKDIR=/$USERID
# else
#     WORKDIR=/home/$USERID
# fi
WORKDIR=/home/$USERID

## Current date and time of script execution
DATETIME=`date +%Y%m%d_%H%M`
# `date +%Y-%m-%d_%Hh%Mm`
# ${DATETIME}

SCRIPT_NAME=`basename "$0"`
## Log file definition
LOGFILE=${WORKDIR}/${SCRIPT_NAME}-${DATETIME}.log
touch $LOGFILE
chown $USERID:$USERID $LOGFILE

## Logging and ECHO functionality combined.
printl() {
    printf "\n%s" "$1"
    echo -e "$1" >> $LOGFILE
}

# FILE_NAME='echo "$FILE"'
# printl "File name is: $FILE

## BEGIN CHECK SCRIPT RUNNING UNDER SUDO
if [ "$EUID" -ne 0 ]; then
    printl ""
    printl "Please run this script using sudo."
    printl ""
    exit
fi

## Get Operating System information.
. /etc/os-release
OPSYS=${ID^^}
# printl "OPSYS: $OPSYS"

## Get System Architecture
SYSARCH=$(uname -m)
SYSARCH=${SYSARCH^^}

## If the OS is exotic, exit.
if  [[ $OPSYS != *"ARCH"* ]] && \
    [[ $OPSYS != *"PHOTON"* ]] && \
    [[ $OPSYS != *"RASPBIAN"* ]] && \
    [[ $OPSYS != *"DEBIAN"* ]] && \
    [[ $OPSYS != *"UBUNTU"* ]] && \
    [[ $OPSYS != *"CENTOS"* ]] && \
    [[ $OPSYS != *"DIETPI"* ]]; then
    printl "${BIRed}By the look of it, not one of the supported operating systems - aborting${BIWhite}\r\n"; exit
fi

## Check for OS that uses other update mechanisms.
if [[ $OPSYS == *"CENTOS"* ]]; then
    PCKMGR="yum"
    PCK_INST="install -y"
    AQUIET="--quiet"
    NQUIET="-s"
    elif [[ $OPSYS == *"PHOTON"* ]]; then
    PCKMGR="tdnf"
    PCK_INST="install -y"
    AQUIET="--quiet"
    NQUIET=""
    elif [[ $OPSYS == *"ARCH"* ]]; then
    PCKMGR="pacman"
    PCK_INST="-S --noconfirm"
    AQUIET=""
    NQUIET=""
else
    PCKMGR="apt-get"
    PCK_INST="install -y"
    AQUIET="-qq"
    NQUIET="-s"
fi

## Get time as a UNIX timestamp (seconds elapsed since Jan 1, 1970 0:00 UTC)
startTime="$(date +%s)"
columns=$(tput cols)
user_response=""
SECONDS=0
REBOOTREQUIRED=0

## Color settings
## High Intensity
IGreen='\e[0;92m'       # Green
IYellow='\e[0;93m'      # Yellow
IBlue='\e[0;94m'        # Blue
ICyan='\e[0;96m'        # Cyan
IWhite='\e[0;97m'       # White

## Bold High Intensity
BIRed='\e[1;91m'        # Red
BIGreen='\e[1;92m'      # Green
BIYellow='\e[1;93m'     # Yellow
BIPurple='\e[1;95m'     # Purple
BIMagenta='\e[1;95m'    # Purple
BICyan='\e[1;96m'       # Cyan
BIWhite='\e[1;97m'      # White

## Whiptail Color Settings
export NEWT_COLORS='
root=black,lightgray
title=yellow,blue
window=,blue
border=white,blue
textbox=white,blue
button=black,white
shadow=,gray
'

## Determine CPU Architecture:
CPUARCH=$(lscpu | grep Architecture | tr -d ":" | awk '{print $2}')
#printl "CPU Architecture: $CPUARCH"
#i686 - 32-bit OS

## Determine CPU Cores:
ACTIVECORES=$(grep -c processor /proc/cpuinfo)
#printl "CPU Cores: $ACTIVECORES"

## Determine current IP address:
MY_IP=$(hostname -I)

printstatus() {
    # h=$(($SECONDS/3600));
    # m=$((($SECONDS/60)%60));
    # s=$(($SECONDS%60));
    # printf "\r\n${BIGreen}==\r\n== ${BIYellow}$1"
    # printf "\r\n${BIGreen}== ${IBlue}Total: %02dh:%02dm:%02ds Cores: $ACTIVECORES \r\n${BIGreen}==${IWhite}\r\n\r\n"  $h $m $s;
    printl ""
    printl "############################################################"
    printl "$1"
    printl ""
}

## Test internet connection.
testInternetConnection() {
    chmod u+s /bin/ping
    if [[ "$(ping -c 1 23.1.68.60  | grep '100%' )" != "" ]]; then
        printl "${IRed} No internet connection available, aborting! ${IWhite}\r\n"
        exit 0
    fi
}

# Function to display success or failure of command
fnSucces() {
    if [ $EXITCODE -eq 0 ]; then
        printl "  - Succesful."
    else
        printl "  - Failed!"
        # Consider exiting.
        printl "  - Exitcode: $EXITCODE"
        # exit $EXITCODE
    fi
}

# Function to make backups of files
fnMakeBackup() {
    printl "- Make backup of $1"
    sudo cp "${1}" "${1}".bak-${DATETIME}
    EXITCODE=$?; fnSucces $EXITCODE
}

fnPackageCheck() {
    printl "  - Check if $1 is installed:"
    sudo dpkg -s $1 > /dev/null
    if [ $? -eq 0 ]; then
        printl "    - Package $1 is installed."
        PKG_INSTALLED="true"
    else
        printl "    - Package $1 is not installed. Install."
        PKG_INSTALLED="false"
        $PCKMGR $AQUIET $PCK_INST $1 2>&1 | tee -a $LOGFILE
        ## Check and log success.
        if [ $? -eq 0 ]; then
            printl "    - Package $1 installed sucessfully."
            PKG_INSTALL_SUCCES="true"
        else
            printl "    - Package $1 did not install sucessfully."
            PKG_INSTALL_SUCCES="false"
            return ## Exit function on failure.
        fi
    fi
}

################################################################################
## MAIN SECTION OF SCRIPT
################################################################################

printstatus "Welcome to THE SCRIPT!"

DISTRO=$(/usr/bin/lsb_release -rs)
CHECK64=$(uname -m)
printl ""
printl "Script version: ${SCRIPT_VERSION}"
printl "Last modification: ${LAST_MODIFICATION}"
printl ""
printl "DISTRO: $DISTRO"
printl "CHECK64: $CHECK64"
printl "OPSYS: $OPSYS"
printl ""

printstatus "Making sure THE SCRIPT works..."

## Test internet connection.
## Disable for offline testing purposes. E.g. in VMs and no internet connection.
#testInternetConnection

## Install required software for functional menu.
# $PCKMGR $AQUIET $PCK_INST whiptail ccze net-tools curl 2>&1 | tee -a $LOGFILE

fnCheckRequiedPackages() {
    printl "- Check for required packages:"
    REQ_PACKAGES=( whiptail ccze net-tools curl )
    REQ_PACKAGES_COS=( newt epel-release ccze net-tools curl ) # Specific to CentOS

    if [[ $OPSYS == *"CENTOS"* ]]; then
        printl "  - OS ${OPSYS} detected ..."
        for i in "${REQ_PACKAGES_COS[@]}"
        do
            printl "  - Checking package ${i}"
            rpm -qa | grep ${i} > /dev/null || $PCKMGR $AQUIET $PCK_INST ${i} 2>&1 | tee -a $LOGFILE
        done
    else
        printl "  - OS ${OPSYS} detected ..."
        for i in "${REQ_PACKAGES[@]}"
        do
            printl "  - Checking package ${i}"
            sudo dpkg -s ${i} > /dev/null || $PCKMGR $AQUIET $PCK_INST ${i} 2>&1 | tee -a $LOGFILE
        done
    fi
}
fnCheckRequiedPackages

# REQ_PACKAGES=( whiptail ccze net-tools curl )
# for i in "${REQ_PACKAGES[@]}"
# do
#     sudo dpkg -s ${i} > /dev/null || $PCKMGR $AQUIET $PCK_INST ${i} 2>&1 | tee -a $LOGFILE
# done

## Photon
# tdnf install rpm-build

install_lsb_release() {
    ## install lsb_release if not present.
    if [[ $OPSYS == *"CENTOS"* ]]; then
        LSB_PACKAGE="redhat-lsb-core"
    else
        LSB_PACKAGE="lsb-release"
    fi
    # [ ! -x /usr/bin/lsb_release ] && $PCKMGR $AQUIET -y update > /dev/null 2>&1 && $PCKMGR $AQUIET $PCK_INST $LSB_PACKAGE 2>&1 | tee -a $LOGFILE
    [ ! -x /usr/bin/lsb_release ] && $PCKMGR $AQUIET $PCK_INST $LSB_PACKAGE 2>&1 | tee -a $LOGFILE
}
install_lsb_release


################################################################################
## Main Menu Definition
################################################################################

main_menu1() {
    MMENU1=$(whiptail --title "Main Menu Selection" --checklist --notags \
        "\nSelect items as required then hit OK " 25 75 16 \
        "QUIET" "Quiet(er) install - untick for lots of info " OFF \
        "CUST_OPS" "Menu - Customization options " OFF \
        "SEC_OPS" "Menu - Options for securing the system " OFF \
        "log2ram" "Install Log2RAM with custom capacity " OFF \
        3>&1 1>&2 2>&3)
printl "Output MainMenu1: $MMENU1"
MYMENU="$MYMENU $MMENU1"
}

################################################################################
## Sub Menus Definition
################################################################################

sub_menu1() {
    SMENU1=$(whiptail --checklist --notags --title "Select customization options" \
        "\nSelect items as required then hit OK " 25 75 16 \
        "DISAUPD" "Disable automatic updates on Ubuntu" OFF \
        "TZADAM" "Set timezone to Europe/Amsterdam" OFF \
        "CHANGE_LANG" "Change Language to US-English " OFF \
        "SHOW_IP" "Show IP on logon screen " OFF \
        "MACDHCP" "Configure to use MAC for DHCP " OFF \
        "IP_FIX" "Configure IP networking " OFF \
        "CUSTOM_PROMPT" "Updated Prompt " OFF \
        "ADD_CSCRIPT" "Add cscript to .bashrc " OFF \
        "LOCAL_MIRROR" "Add local mirror for APT " OFF \
        "CUSTOM_ALIAS" "Aliases for ease of use " OFF \
        "VIMRC" "Fill .vimrc with settings" OFF \
        "RPI_CLONE" "Install RPI-Clone" OFF \
        3>&1 1>&2 2>&3)
printl "Output SubMenu1: $SMENU1"
MYMENU="$MYMENU $SMENU1"
}

sub_menu2() {
    SMENU2=$(whiptail --checklist --notags --title "Select securing options" \
        "\nSelect items as required then hit OK " 25 75 16 \
        "CREATE_SYSADMIN" "Create alternative sysadmin account " OFF \
        "UPDATE_HOST" "Apply latest updates available " OFF \
        "NO_PASS_SUDO" "Remove sudo password requirement (NOT SECURE!) " OFF \
        "REGENERATE_SSH_KEYS" "Regenerate the SSH host keys " OFF \
        "HOST_RENAME" "Rename the HOST " OFF \
        3>&1 1>&2 2>&3)
printl "Output SubMenu2: $SMENU2"
MYMENU="$MYMENU $SMENU2"
}

################################################################################
## Calling the Menus
################################################################################

## Call main menu
main_menu1

## Call Submenus
if [[ $MYMENU == *"CUST_OPS"* ]]; then
    sub_menu1
fi

if [[ $MYMENU == *"SEC_OPS"* ]]; then
    sub_menu2
fi

if [[ $MYMENU != *"QUIET"* ]]; then
    AQUIET=""
    NQUIET=""
fi

if [[ $MYMENU == "" ]]; then
    whiptail --title "Installation Aborted" --msgbox "Cancelled as requested." 8 78
    exit
fi

printl "Output Menu selections: ${MYMENU}"

################################################################################
##                  - Executing on the selected items -                       ##
################################################################################

################################################################################
# DCHP or Fixed IP addressing. @@@
################################################################################

## Module Functions
fixipCheckOS() {
    if  [[ $OPSYS != *"CENTOS"* ]] ; then
        printl "${BIRed}By the look of it, not one of the supported operating systems for this function.${BIWhite}\r\n"
        SUPPORTED_OS=false
    else
        SUPPORTED_OS=true
    fi
}

# fixipNewUUID() {
#     # Dialog to ask for UUID generation
#     # If yes, generate new UUID
# }

pruts01(){
    if [ $? -eq 0 ]; then
            printl "    - Pulse Agent: Successfully uninstalled the agent."
            UNINSTALL_AGENT_SUCCES=true
        else
            printl "   - Pulse Agent: Agent NOT uninstalled succesfully"
            UNINSTALL_AGENT_SUCCES=false
        fi

    if  [[ $OPSYS != *"ARCH"* ]] && \
        [[ $OPSYS != *"PHOTON"* ]] && \
        [[ $OPSYS != *"RASPBIAN"* ]] && \
        [[ $OPSYS != *"DEBIAN"* ]] && \
        [[ $OPSYS != *"UBUNTU"* ]] && \
        [[ $OPSYS != *"CENTOS"* ]] && \
        [[ $OPSYS != *"DIETPI"* ]]; then
        printl "${BIRed}By the look of it, not one of the supported operating systems - aborting${BIWhite}\r\n"; exit
    fi
}

## Module Logic
moduleIPFix() {
    printstatus "Configure network settings..."

    # Check if run on supported OS
    fixipCheckOS
    if [[ $SUPPORTED_OS == "true" ]]; then
        # Check if DHCP is enabled or Fixed IP
        fixipCheckDHCP
        if [[ $DHCP_ON == "true" ]]; then
            # Ask for new UUID generation
            fixipNewUUID
        fi
    fi
    ## Reboot required? 0=no 1=yes
    REBOOTREQUIRED=0

    ## Cleanup variables
    unset SUPPORTED_OS
}

# Start when module is selected
[[ $MYMENU == *"IP_FIX"* ]] && moduleIPFix


################################################################################
# Force the system to use en_US as the language.
################################################################################

moduleChangeLang() {
    printstatus "Change the systems language settings:"
    LANG_DEF=en_US.UTF8

    printl "- Check if ${LANG_DEF} is already active ..."
    if localectl | grep -q en_US.UTF8; then
        printl "  - Language already set to ${LANG_DEF}."
    else
        printl "  - Language needs to be set ..."
        localectl set-locale LANG=${LANG_DEF}
        EXITCODE=$?; fnSucces $EXITCODE
    fi

    # Modify the SSH service settings to avoid influence from ssh client
    printl "- Check the SSH server config not to accept settings from client."
    if grep -Fxq "#AcceptEnv LANG LC_*" /etc/ssh/sshd_config
    then
        printl "  - /etc/ssh/sshd_config already updated."
    elif grep -Fxq "AcceptEnv LANG LC_*" /etc/ssh/sshd_config
    then
        printl "  - Need to update /etc/ssh/sshd_config:"

        ## Define the new value
        NEWVALUE="#AcceptEnv LANG LC_*"

        ## Replace the current line with the new one in the
        sed -i "/AcceptEnv/c${NEWVALUE}" "/etc/ssh/sshd_config"
        printl "    - /etc/ssh/sshd_config is updated."

    else
        printl "  - Not found at all. Add."
        NEWVALUE="#AcceptEnv LANG LC_*"
        echo "${NEWVALUE}" >> /etc/ssh/sshd_config
        printl "    - The value: ${NEWVALUE} is added to sshd_config"
    fi

    ## Restart the sshd service.
    printl "  - Restart the sshd service ..."
    systemctl restart sshd
    if [ $? -eq 0 ]; then
        printl "    - sshd service is restarted."
    else
        printl "    - Could not restart sshd service."
    fi
    ## Have the script reboot at the end.
    REBOOTREQUIRED=1

    ## Cleanup variables
    unset NEWVALUE
    unset LANG_DEF
    unset EXITCODE
}

# Start when module is selected
[[ $MYMENU == *"CHANGE_LANG"* ]] && moduleChangeLang


################################################################################
# Installing RPI-Clone
################################################################################

## Module Functions

## Module Logic

fnInstallRpiclone() {
    printstatus "Installing RPI Clone"
    # check for git
    fnPackageCheck git

    printl "  - Clone repo"
    git clone https://github.com/billw2/rpi-clone.git
    EXITCODE=$?; fnSucces $EXITCODE

    printl "  - Copy binaries to /usr/local/sbin"
    sudo cp rpi-clone/rpi-clone rpi-clone/rpi-clone-setup /usr/local/sbin
    EXITCODE=$?; fnSucces $EXITCODE

}

# Start when module is selected
[[ $MYMENU == *"RPI_CLONE"* ]] && fnInstallRpiclone


################################################################################
# Creating a system administrator account.
################################################################################

## Module Functions

## Module Logic
moduleCreateSysadmin() {
    printstatus "Creating alternative administrative account..."

    ADMINNAME=sysadmin
    ADMINNAME=$(whiptail --title "Administrative Account" --inputbox "\nEnter the name of the administrative account:\n" 8 60 $ADMINNAME 3>&1 1>&2 2>&3)

    if [ $USERID == $ADMINNAME ]; then
        whiptail --title "Administrative Account" --infobox "You are already using the $ADMINNAME account." 8 78
    else

    USERPASS=$(whiptail --passwordbox "Enter a user password" 8 60 3>&1 1>&2 2>&3)
    if [[ -z "${USERPASS// }" ]]; then
        printf "No user password given - aborting${BIWhite}\r\n"; exit
    fi

    USERPASS2=$(whiptail --passwordbox "Confirm user password" 8 60 3>&1 1>&2 2>&3)
    if  [ $USERPASS2 == "" ]; then
        printf "${BIRed}No password confirmation given - aborting${BIWhite}\r\n"; exit
    fi

    if  [ $USERPASS != $USERPASS2 ]
    then
        printf "${BIRed}Passwords don't match - aborting${BIWhite}\r\n"; exit
    fi

    SRC=$USERID
    DEST=$ADMINNAME

    SRC_GROUPS=$(groups ${SRC})
    SRC_SHELL=$(awk -F : -v name=${SRC} '(name == $1) { print $7 }' /etc/passwd)
    NEW_GROUPS=""
    i=0

    #skip first 3 entries this will be "username", ":", "defaultgroup"
    for gr in $SRC_GROUPS
    do
        if [ $i -gt 2 ]
        then
            if [ -z "$NEW_GROUPS" ]; then NEW_GROUPS=$gr; else NEW_GROUPS="$NEW_GROUPS,$gr"; fi
        fi
        (( i++ ))
    done

    printl "New user will be added to the following groups: $NEW_GROUPS"

    useradd --groups ${NEW_GROUPS} --shell ${SRC_SHELL} --create-home ${DEST}
    mkhomedir_helper ${DEST}
    #passwd ${DEST}

    ## Add the specified password to the account.
    echo $ADMINNAME:$USERPASS | chpasswd

    printstatus "The account $ADMINNAME is created..."

    ## Cleanup variables
    unset USERPASS
    unset USERPASS2
    unset ADMINNAME
    unset SRC
    unset DEST
    unset SRC_GROUPS
    unset SRC_SHELL
    unset NEW_GROUPS
    unset gr
    fi
}

# Start when module is selected
[[ $MYMENU == *"CREATE_SYSADMIN"* ]] && moduleCreateSysadmin

################################################################################
# Updating the Host.
################################################################################

## Module Functions

## Module Logic
moduleUpdateHost() {
    printstatus "Update the Host with the latest available updates..."

    if [[ $OPSYS == *"CENTOS"* ]]; then
        $PCKMGR $AQUIET check-update 2>&1 | tee -a $LOGFILE
        $PCKMGR $AQUIET update 2>&1 | tee -a $LOGFILE
        $PCKMGR $AQUIET -y autoremove 2>&1 | tee -a $LOGFILE
        #$PCKMGR $AQUIET -y clean 2>&1 | tee -a $LOGFILE
    elif [[ $OPSYS == *"ARCH"* ]]; then
        $PCKMGR -Syu 2>&1 | tee -a $LOGFILE
    else
        $PCKMGR $AQUIET update 2>&1 | tee -a $LOGFILE
        $PCKMGR $AQUIET list --upgradable 2>&1 | tee -a $LOGFILE
        $PCKMGR $AQUIET -y full-upgrade 2>&1 | tee -a $LOGFILE
        $PCKMGR $AQUIET -y dist-upgrade 2>&1 | tee -a $LOGFILE
        $PCKMGR $AQUIET -y autoremove 2>&1 | tee -a $LOGFILE
        $PCKMGR $AQUIET -y autoclean 2>&1 | tee -a $LOGFILE
    fi
    ## Have the script reboot at the end.
    REBOOTREQUIRED=1
}

# Start when module is selected
[[ $MYMENU == *"UPDATE_HOST"* ]] && moduleUpdateHost


################################################################################
# Regenerate the Host SSH keys.
################################################################################

## Module Functions

## Module Logic
moduleRegenerateSshKeys() {
    printstatus "Regenerate SSH Host keys..."

    ## Get the current public SSH key of the host.
    SSHFINGERPRINT=$(ssh-keygen -l -f /etc/ssh/ssh_host_ecdsa_key.pub | tr -d ":" | awk '{print $2}')
    ## log the value to syslog
    logger Old SSH fingerprint is: $SSHFINGERPRINT ## Add to syslog
    printl Old SSH fingerprint is: $SSHFINGERPRINT


    /bin/rm -v /etc/ssh/ssh_host_* 2>&1 | tee -a $LOGFILE
    ssh-keygen -t dsa -N "" -f /etc/ssh/ssh_host_dsa_key
    ssh-keygen -t rsa -N "" -f /etc/ssh/ssh_host_rsa_key
    #dpkg-reconfigure openssh-server 2>&1 | tee -a $LOGFILE

    systemctl restart sshd 2>&1 | tee -a $LOGFILE

    ## Get the new public SSH key of the host.
    SSHFINGERPRINT=$(ssh-keygen -l -f /etc/ssh/ssh_host_ecdsa_key.pub | tr -d ":" | awk '{print $2}')
    logger New SSH fingerprint is: $SSHFINGERPRINT ## Add to syslog
    printl New SSH fingerprint is: $SSHFINGERPRINT

    ## Have the script reboot at the end.
    REBOOTREQUIRED=1
}

# Start when module is selected
[[ $MYMENU == *"REGENERATE_SSH_KEYS"* ]] && moduleRegenerateSshKeys


################################################################################
# Show the IP address of the Host at the login screen.
################################################################################

## Module Functions

## Module Logic
moduleShowIp() {
    printstatus "Show the IP address at the logon screen..."

    TARGETFILE=/etc/issue
    if grep -Fq "IP Address" $TARGETFILE
    then
        printl "String found, $TARGETFILE does not need updating."
    else
        printl "String not found, settings will be added to $TARGETFILE"
        ## Backup issue file.
        cat /etc/issue >> /etc/issue.bak 2>&1 | tee -a $LOGFILE

        ## Get content and add info to issue file.
        cat $TARGETFILE > worker_file 2>&1 | tee -a $LOGFILE
        echo 'IP Address: \4' >> worker_file 2>&1 | tee -a $LOGFILE
        echo "" >> worker_file 2>&1 | tee -a $LOGFILE

        ## Replace the contend of the issue file.
        cat worker_file > $TARGETFILE 2>&1 | tee -a $LOGFILE

        ## Remove the worker file.
        rm worker_file 2>&1 | tee -a $LOGFILE

        ## Cleanup variables
        unset TARGETFILE
    fi
}

# Start when module is selected
[[ $MYMENU == *"SHOW_IP"* ]] && moduleShowIp


################################################################################
# Rename the Host.
################################################################################

## Module Functions

## Module Logic
moduleHostRename() {
    printstatus "Rename the Host..."

    ## Format the date and time strings 
    current_time=$(date "+%Y%m%d-%H%M%S")
    RDM="$(date +"%3N")"

    ## Get the last 4 characters of the MAC Address
    MAC=$(ifconfig | grep ether | tr -d ":" | awk '{print $2}' | tail -c 5)
    #printl "MAC: $MAC"

    ## The current and to be old name:
    OLDHOSTNAME="$(uname -n)"
    GENHOSTNAME=$OPSYS$RDM${MAC^^}

    NEWHOSTNAME=$(whiptail --title "Rename Host" --inputbox "\nEnter the new name for the Host:\n" 8 60 $GENHOSTNAME 3>&1 1>&2 2>&3)

    printl "The old hostname: $OLDHOSTNAME"
    printl "The generated hostname: $GENHOSTNAME"
    printl "The chosen hostname: $NEWHOSTNAME"

    ## Set the new hostname.
    hostnamectl set-hostname $NEWHOSTNAME

    ## Update the /etc/hosts file.
    if grep -Fq "127.0.1.1" /etc/hosts
    then
        ## If found, replace the line
        sed -i "/127.0.1.1/c\127.0.1.1    $NEWHOSTNAME" /etc/hosts
    else
        ## If not found, add the line
        echo '127.0.1.1    '$NEWHOSTNAME &>> /etc/hosts
    fi

    ## Check if Ubuntu Cloud config is used
    cloudFile="/etc/cloud/cloud.cfg"
    if [ -f "$cloudFile" ]
    then
        sed -i "/preserve_hostname/c\preserve_hostname: true" $cloudFile
    fi

    ## Have the script reboot at the end.
    REBOOTREQUIRED=1

    ## Cleanup variables
    unset RDM
    unset MAC
    unset OLDHOSTNAME
    unset GENHOSTNAME
    unset NEWHOSTNAME
    unset cloudFile
}

# Start when module is selected
[[ $MYMENU == *"HOST_RENAME"* ]] && moduleHostRename


################################################################################
# Apply a more convenient Prompt for the user.
################################################################################

## Module Functions

## Module Logic
moduleCustomPrompt () {
    printstatus "Change the prompt to a more user friendly one..."

    TARGETFILE="$WORKDIR/.bashrc"

    OPSYS=${ID^}            # First letter uppercase
    OPVER=${VERSION_ID^}    # First letter uppercase
    # Original modification:
    # NEWPROMPT="export PS1='\${debian_chroot:+(\$debian_chroot)}\[\033[00;33m\]\n   \u \[\033[01;34m\] at \[\033[00;33m\] \h\[\033[00m\] \[\033[01;34m\]in \[\033[00;33m\]\w\[\033[00m\]\n\\$ '"
    # New modification:
    NEWPROMPT="export PS1='\${debian_chroot:+(\$debian_chroot)}\n\$OPSYS \$OPVER:\[\033[00;33m\] \u\[\033[01;34m\] at \[\033[00;33m\]\h\[\033[00m\] \[\033[01;34m\]in \[\033[00;33m\]\w\[\033[00m\]\n\\$ '"

    if grep -Fxq "## Custom prompt settings added ..." $TARGETFILE
    then
        printl "String found, $TARGETFILE does not need updating."
        break
    else
        printl "String not found, settings will be added to $TARGETFILE"
        echo "" >> $TARGETFILE
        echo "## Custom prompt settings added ..." >> $TARGETFILE
        echo ". /etc/os-release" >> $TARGETFILE
        echo "OPSYS=\${ID^}" >> $TARGETFILE
        echo "OPVER=\${VERSION_ID^}" >> $TARGETFILE
        echo "$NEWPROMPT" >> $TARGETFILE
    fi
    ## Cleanup variables
    unset TARGETFILE
    unset NEWPROMPT
}

# Start when module is selected
[[ $MYMENU == *"CUSTOM_PROMPT"* ]] && moduleCustomPrompt


################################################################################
# Add convenience in creating scripts.
################################################################################

## Module Functions

## Module Logic
moduleAddCscript () {
    printstatus "Change the prompt to a more user friendly one..."

    TARGETFILE="$WORKDIR/.bashrc"
    WORKFILE3="$WORKDIR/cscript"
    cat > $WORKFILE3 <<EOF

## Create script with header. Usage: cscript scriptname.sh
cscript(){
    touch "\$@";
    chmod +x "\$@";
    echo '#!/usr/bin/env bash' > "\$@";
    nano "\$@";
}

EOF
    if grep -Fxq "## Create script with header. Usage: cscript scriptname.sh" $TARGETFILE
    then
        printl "String found, $TARGETFILE does not need updating."
    else
        printl "String not found, settings will be added to $TARGETFILE"
        echo "" >> $TARGETFILE
        cat "$WORKFILE3" >> $TARGETFILE
        rm $WORKFILE3
    fi
    ## Cleanup variables
    unset TARGETFILE
    unset WORKFILE3
}

# Start when module is selected
[[ $MYMENU == *"ADD_CSCRIPT"* ]] && moduleAddCscript


################################################################################
# Add local mirror (NL).
################################################################################

## Module Functions
fnFindStringInFile() {
    if grep -Fxq "${PATTERN_OUT}" "${TARGETFILE}"
    then
        # code if found
        printl "- Target pattern found. Nothing else to do ..."
    elif grep -Fxq "${PATTERN_IN}" "${TARGETFILE}"; then
        # code if not found
        printl "- Search pattern found. Replace with new one ..."
        fnDoReplace
    else
        printl "- No matches for search and target pattern."
        printl "- Maybe and error in this stript."
    fi
}

fnDoReplace() {
    # Make backup first ...
    fnMakeBackup ${TARGETFILE}

    ## Search for input pattern and replace by output pattern
    printl "Make changes to ${TARGETFILE} ..."
    printl "New mirror: ${PATTERN_OUT}"
    sed -i 's|'${PATTERN_IN}'|'${PATTERN_OUT}'|g' ${TARGETFILE}
    EXITCODE=$?; fnSucces $EXITCODE
}

## Module Logic
moduleLocalMirror () {
    printstatus "Change the apt mirror to a local one..."

    ## Check if this is Raspbian
    if [[ $OPSYS == *"RASPBIAN"* ]]; then
        printl "Raspberry Pi OS detected..."
        ## Prepare settings as variables
        TARGETFILE="/etc/apt/sources.list"
        PATTERN_IN="http://raspbian.raspberrypi.org/raspbian/"
        PATTERN_OUT="http://mirror.nl.leaseweb.net/raspbian/raspbian"

        # Check if already has the configuration
        fnFindStringInFile

    elif  [[ $OPSYS == *"UBUNTU"* ]] && [[ $SYSARCH == *"AARCH64"* ]]; then
        printl "Ubuntu on ARM64 detected..."

        ## Prepare settings as variables
        TARGETFILE="/etc/apt/sources.list"
        PATTERN_IN="http://ports.ubuntu.com/ubuntu-ports"
        PATTERN_OUT="http://ftp.tu-chemnitz.de/pub/linux/ubuntu-ports"

        # Check if already has the configuration
        fnFindStringInFile

    else
        printl "Nothing changed. No options available yet for this OS and hardware combination."
    fi

    ## Cleanup variables
    unset TARGETFILE
    unset PATTERN_IN
    unset PATTERN_OUT
}

# Start when module is selected
[[ $MYMENU == *"LOCAL_MIRROR"* ]] && moduleLocalMirror


################################################################################
# Add additional aliases to the profile of the user.
################################################################################

## Module Functions

## Module Logic
moduleCustomAlias() {
    printstatus "Add some aliases for ease of use..."

    TARGETFILE="$WORKDIR/.bash_aliases"
    WORKFILE2="$WORKDIR/.bashrc"
    ## Check if .bash_aliases will be loaded.
    if grep -Fq "bash_aliases" $WORKFILE2
    then
        ## If found, replace the line
        printl ".bashrc calls .bash_aliases. All good here."
    else
        ## If not found, add the line
        printl ".bashrc does not call .bash_aliases. Making sure it does."
cat >> $WORKFILE2 <<EOF
## Call the .bash_aliases file during logon.
if [ -f ~/.bash_aliases ]; then
. ~/.bash_aliases
fi
EOF
        source $WORKFILE2
    fi

    if grep -Fxq "## Custom aliases added ..." $TARGETFILE
    then
        printl "String found, $TARGETFILE does not need updating."
        break
    else
        printl "String not found, settings will be added to $TARGETFILE"
        echo "" >> $TARGETFILE
        echo "## Custom aliases added ..." >> $TARGETFILE
        echo "$NEWPROMPT" >> $TARGETFILE
cat > $TARGETFILE << EOF
## Enable color
export CLICOLOR=true

## Own creations:
alias la='ls -la'   # list all
alias ll='ls -lhF'  # list all
alias dir='lla'     # List all in columns
alias lh='ll -h'    # list all
alias lx='ls -X'    # sort by extension
alias lt='ls -tr'   # sort by mod time, reverse order
alias lS='ls -S'    # sort by size
alias lL='ll -S'    # sort by size
alias lr='ls -R'    # recursive
alias ..='cd ..'    # up
alias watch='watch -d -n 1' # update every 1 second, showing changes
alias cls='clear'
alias br='source ~/.bash_profile'
alias bashrc="nano ~/.bashrc && source ~/.bashrc"
alias bash_aliases="nano ~/.bash_aliases && source ~/.bash_aliases"
alias nocomment="grep -Ev '^(#|$)'"
alias catnc="grep -Ev '^(#|$)'"
alias monit='sudo tail -f /var/log/daemon.log'
alias div='echo -e "\n=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n"'
alias update='sudo apt update && div && sudo apt list --upgradable && div && sudo apt full-upgrade -y && sudo apt autoremove -y && sudo apt autoclean -y && div && [ -f /var/run/reboot-required ] && echo -e "- Reboot is required ..." || echo -e "- No reboot required ..."'
alias fix127='sudo mv /var/lib/dpkg/info/install-info.postinst /var/lib/dpkg/info/install-info.postinst.bad'
alias thescript='curl -s https://raw.githubusercontent.com/MTijbout/theScript_pub/master/theScript.sh | sudo bash'
EOF
    fi
    chown ${USERID}:${USERID} $TARGETFILE
    ## Cleanup variables
    unset TARGETFILE
    unset WORKFILE2
}

# Start when module is selected
[[ $MYMENU == *"CUSTOM_ALIAS"* ]] && moduleCustomAlias


################################################################################
# Fill .vimrc with settings
################################################################################

## Module Functions

## Module Logic
moduleVimrc() {
    printstatus "Fill .vimrc with settings ..."
    curl https://raw.githubusercontent.com/MTijbout/theScript_pub/master/vimrc -o "/home/${USERID}/.vimrc"
    EXITCODE=$?; fnSucces $EXITCODE
}
#     TARGETFILE="$WORKDIR/.vimrc"
#     cat > $TARGETFILE << EOF
# set list
# set number
# syntax on
# colorscheme desert
# EOF


# Start when module is selected
[[ $MYMENU == *"VIMRC"* ]] && moduleVimrc


################################################################################
# Remove the need to type a password when using sudo.
################################################################################

## Module Functions

## Module Logic
moduleNoPassSudo() {
    printstatus "Remove for need of password performing sudo..."

    if ls /etc/sudoers.d/*$USERID*; then
        printl "Using password for sudo is not required for this user."
    else
        printl "Removed for need of password performing sudo for this user."
        echo "$USERID ALL=(ALL) NOPASSWD: ALL" >/etc/sudoers.d/010_$USERID-nopasswd
        chmod 0440 /etc/sudoers.d/010_$USERID-nopasswd
    fi
}

# Start when module is selected
[[ $MYMENU == *"NO_PASS_SUDO"* ]] && moduleNoPassSudo


################################################################################
# Install Log2RAM to extend the life SD cards.
################################################################################

## Module Functions
Log2RAMAlreadyInstalled() {
    printl "    - $MODULE_NAME: Check if already installed."
    ## Check if the Log2RAM is already installed.
    if [ ! -f /etc/log2ram.conf ]; then
        printl "    - $MODULE_NAME: Not installed."
        Log2RAM_INSTALLED="false"
    else
        printl "    - $MODULE_NAME: Is installed."
        Log2RAM_INSTALLED="true"
    fi
}

Log2RAMOSCheck() {
    ## Check if the required OS is Raspbian.
    printl "  - $MODULE_NAME: Check OS is Raspbian."
    if [[ $OPSYS == *"RASPBIAN"* ]]; then
        printl "    - $MODULE_NAME: OS is $OPSYS."
        Log2RAM_OS_CHECK="true"
    else
        printl "    - $MODULE_NAME: Incorrect OS: $OPSYS."
        Log2RAM_OS_CHECK="false"
    fi
}

Log2RAMgitPreReqs() {
    ## Check if the required OS is Raspbian.
    printl "  - $MODULE_NAME: Check if git is already installed."
    which git
    if [ $? -eq 0 ]; then
        printl "    - $MODULE_NAME: git is installed."
        GIT_INSTALLED="true"
    else
        printl "    - $MODULE_NAME: git is not installed. Install."
        GIT_INSTALLED="false"
        $PCKMGR $AQUIET $PCK_INST git 2>&1 | tee -a $LOGFILE
        ## Check and log success.
        if [ $? -eq 0 ]; then
            printl "    - $MODULE_NAME: git installed sucessfully."
            GIT_INSTALL_SUCCES="true"
        else 
            printl "    - $MODULE_NAME: git did not install sucessfully."
            GIT_INSTALL_SUCCES="false"
            return ## Exit function on failure.
        fi
    fi
}

Log2RAMDownloadInstall() {
    ## Download and Install Log2RAM.
    printl "    - $MODULE_NAME: Download binaries."

    ## Download Log2RAM
    cd $WORKDIR
    git clone https://github.com/azlux/log2ram.git 2>&1 | tee -a $LOGFILE
    if [ $? -eq 0 ]; then
        printl "    - $MODULE_NAME: git clone sucessful."
        APP_DOWNLOAD_SUCCES="true"
    else
        printl "    - $MODULE_NAME: git clone not sucessful."
        APP_DOWNLOAD_SUCCES="false"
        return ## Exit function on failure.
    fi

    ## Install Log2RAM
    cd log2ram
    chmod +x install.sh
    ./install.sh 2>&1 | tee -a $LOGFILE
    if [ $? -eq 0 ]; then
        printl "    - $MODULE_NAME: Installation sucessful."
        APP_INSTALL_SUCCES="true"
    else
        printl "    - $MODULE_NAME: Installation not sucessful."
        APP_INSTALL_SUCCES="false"
        return ## Exit function on failure.
    fi
    cd $WORKDIR
}

Log2RAMChangeCapacity() {
    ## Increase Log2RAM capacity
    printl "    - $MODULE_NAME: Change capacity."

    ## Ask the user for input.
    L2RDEFVAL_I=40M
    printl "    - $MODULE_NAME: Default capacity is: $L2RDEFVAL_I"
    L2RDEFVAL_O=$(whiptail --inputbox "\nProvide new capacity (for example 192M)):\n" --title "Log2RAM Capacity" 8 60 $L2RDEFVAL_I 3>&1 1>&2 2>&3)
    printl "    - $MODULE_NAME: Custom capacity is: $L2RDEFVAL_O"

    ## Check for SIZE value in the config file and make the modifications.
    if grep -Fq "SIZE" /etc/log2ram.conf; then
        # Replace the line with the new value.
        sed -i "/SIZE/c\SIZE=$L2RDEFVAL_O" /etc/log2ram.conf
        ## Check and log success.
        if [ $? -eq 0 ]; then
            printl "    - $MODULE_NAME: Capacity succesfully changed."
            CONF_CHANGE_SUCCES="true"
        else
            printl "    - $MODULE_NAME: Capacity is not changed sucessfully."
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

moduleLog2RAM() {
    printstatus "Installing Log2RAM"
    MODULE_NAME=Log2RAM
    Log2RAMOSCheck ## Check if the required OS is Raspbian.
    if [[ $Log2RAM_OS_CHECK == "true" ]]; then
        ## Correct OS to install on.
        Log2RAMAlreadyInstalled ## Check if the Log2RAM is already installed.
        if [[ $Log2RAM_INSTALLED == "true" ]]; then
            ## Log2RAM is already installed.
            printl "    - $MODULE_NAME: Already installed. Initiate config change"
            Log2RAMChangeCapacity ## Change Log2RAM capacity.
        else
            ## Log2RAM is not installed. Install.
            Log2RAMgitPreReqs ## Check if git is installed.
            Log2RAMDownloadInstall ## Download and Install Log2RAM.
            if [[ $APP_INSTALL_SUCCES == "true" ]]; then
                printl "    - $MODULE_NAME: Already installed. Initiate config change"
                Log2RAMChangeCapacity ## Change Log2RAM capacity.
            fi
        fi
    else
        printl "    - $MODULE_NAME: ERROR - Incorrect OS. Exit here."
            return ## Exit function on ERROR.
    fi

    ## Cleanup variables
    unset L2RDEFVAL
    unset MODULE_NAME
    unset Log2RAM_INSTALLED
    unset Log2RAM_OS_CHECK
    unset GIT_INSTALL_SUCCES
}

# Start when module is selected
[[ $MYMENU == *"log2ram"* ]] && moduleLog2RAM


################################################################################
# Configure to use the MAC address for DHCP.
################################################################################

## Module Functions
fnMacDHCPOSCheck() {
    ## Check if the required OS is supported.
    printl "  - Check if OS is supported:"
    if [[ $OPSYS == *"UBUNTU"* ]]; then
        printl "    - Supported. Detected OS is $OPSYS."
        MACDHCP_OS_CHECK="true"
    elif [[ $OPSYS == *"RASPBIAN"* ]]; then
        printl "    - Supported. Detected OS is $OPSYS."
        MACDHCP_OS_CHECK="true"
    elif [[ $OPSYS == *"DEBIAN"* ]]; then
        printl "    - Supported. Detected OS is $OPSYS."
        MACDHCP_OS_CHECK="true"
    else
        printl "    - Unsupported OS: $OPSYS."
        MACDHCP_OS_CHECK="false"
    fi
}

fnMacDHCPCheckFiles() {
    printl "  - Check what config files are used:"

    # Define variables
    CONF_FILE_LOC="/etc/netplan"
    CONF_FILE_1="01-netcfg.yaml"
    CONF_FILE_2="50-cloud-init.yaml"

    if [ -f ${CONF_FILE_LOC}/${CONF_FILE_1} ]; then
        CONF_WORK_FILE=${CONF_FILE_LOC}/${CONF_FILE_1}
        printl "    - Config file to work with: ${CONF_WORK_FILE}."
        MACDHCP_CONFILE_INST="true"
    elif [ -f ${CONF_FILE_LOC}/${CONF_FILE_2} ]; then
        CONF_WORK_FILE=${CONF_FILE_LOC}/${CONF_FILE_2}
        printl "    - Config file to work with: ${CONF_WORK_FILE}."
        MACDHCP_CONFILE_INST="true"
    else
        printl "    - Known config files not found. Exit here."
        MACDHCP_CONFILE_INST="false"
        # return
    fi
}

fnMacDHCPEnabled() {
    printl "  - Check if DHCP is enabled:"
    if grep -Fxq "${CONF_STRING_1a}" "${CONF_WORK_FILE}"; then
        printl "    - DHCP is enabled."
        MACDHCP_EN="1"
    elif grep -Fxq "${CONF_STRING_1b}" "${CONF_WORK_FILE}"; then
        printl "    - DHCP is enabled."
        MACDHCP_EN="2"
    else
        printl "    - DHCP is NOT enabled."
        MACDHCP_EN="false"
   fi
}

fnMacDHCPUseMac() {
    printl "  - Check if the DHCP is already configured to use mac address:"
    if grep -Fxq "${CONF_STRING_2a}" "${CONF_WORK_FILE}"; then
        printl "    - Using mac address for DHCP is already enabled."
        MACDHCP_CONF="true"
    elif grep -Fxq "${CONF_STRING_2b}" "${CONF_WORK_FILE}"; then
        printl "    - Using mac address for DHCP is already enabled."
        MACDHCP_CONF="true"
    else
        printl "    - Using mac address for DHCP is not (yet) enabled."
        MACDHCP_CONF="false"
    fi
}

fnMacDHCPChangeConfig() {
    # Add the configuration line to the config file
    printl "  - Make changes to configuration:"
    if [[ ${MACDHCP_EN} = 1 ]]; then
        sudo sed -i "/${CONF_STRING_1a}/a\\${CONF_STRING_2a}" "${CONF_WORK_FILE}"
        ## Check and log success.
        if [ $? -eq 0 ]; then
            printl "    - Configuration succesfully changed."
            REBOOTREQUIRED=1
        else
            printl "    - ERROR: No changes made to configuration."
            return ## Exit function on ERROR.
        fi
    elif [[ ${MACDHCP_EN} = 2 ]]; then
        sudo sed -i "/${CONF_STRING_1b}/a\\${CONF_STRING_2b}" "${CONF_WORK_FILE}"
        ## Check and log success.
        if [ $? -eq 0 ]; then
            printl "    - Configuration succesfully changed."
            REBOOTREQUIRED=1
        else
            printl "    - ERROR: No changes made to configuration."
            return ## Exit function on ERROR.
        fi
    else
        printl "    - ${MODULE_NAME}: ERROR - Size value not found in conf file."
    fi
}

################################################################################
## Module Logic

fnMacDHCP() {
    printstatus "Configure DHCP with MAC address"
    MODULE_NAME=MACDHCP

    # Check for supported OS
    fnMacDHCPOSCheck
    [[ ${MACDHCP_OS_CHECK} = false ]] && return

    # Check what config file to use
    fnMacDHCPCheckFiles
    [[ ${MACDHCP_CONFILE_INST} = false ]] && return

    # Strings of settings
    CONF_STRING_1a='            dhcp4: true'
    CONF_STRING_2a='            dhcp-identifier: mac'
    CONF_STRING_1b='      dhcp4: yes'
    CONF_STRING_2b='      dhcp-identifier: mac'

    # Check if DHCP is enabled
    fnMacDHCPEnabled
    [[ ${MACDHCP_EN} = false ]] && return

    # Check if DHCP is already set to use mac address
    fnMacDHCPUseMac
    [[ ${MACDHCP_CONF} = true ]] && return

    # Add configuration to the file
    fnMacDHCPChangeConfig

    ## Cleanup variables
    unset CONF_FILE
    unset MODULE_NAME
    unset CONF_STRING_1a
    unset CONF_STRING_2a
    unset CONF_STRING_1b
    unset CONF_STRING_2b
    unset MACDHCP_OS_CHECK
    unset MACDHCP_CONFILE_INST
    unset MACDHCP_EN
    unset CONF_CHANGE_SUCCES
}

# Start when module is selected
[[ $MYMENU == *"MACDHCP"* ]] && fnMacDHCP


################################################################################
# Disable automatic updates
################################################################################

## Module Functions

fnDisableAutoUpdates() {
    printstatus "- Disable automatic updates in Ubuntu:"
    printl "  - Get Operating System information ..."
    . /etc/os-release
    OPSYS=${ID^^}

    printl "  - Check if OS is Ubuntu. Skip if not ..."
    if  [[ $OPSYS != *"UBUNTU"* ]]; then
        printl "    - OS is not Ubuntu. Skipping ..."
        return
    fi
    printl "    - Operating system: ${OPSYS}"

    # Config file where the auto update feature is managed
    CONF_FILE="/etc/apt/apt.conf.d/20auto-upgrades"

    printl "  - Check for config file: "
    if [ ! -f ${CONF_FILE} ]; then
        printl "    - Config file does not exist, return."
        return
    else
        printl "    - Config file found ..."
    fi

    printl "  - Changing auto update settings:"

    printl "    - Change 1/2 ..."
    OLDVAL='APT::Periodic::Update-Package-Lists "1";'
    NEWVAL='APT::Periodic::Update-Package-Lists "0";'
    # Replace the old line for the new line
    sudo sed -i '+s+'"${OLDVAL}"'+'"${NEWVAL}"'+' ${CONF_FILE}

    printl "    - Change 2/2 ..."
    OLDVAL='APT::Periodic::Unattended-Upgrade "1";'
    NEWVAL='APT::Periodic::Unattended-Upgrade "0";'
    # Replace the old line for the new line
    sudo sed -i '+s+'"${OLDVAL}"'+'"${NEWVAL}"'+' ${CONF_FILE}
}

# Start when module is selected
[[ $MYMENU == *"DISAUPD"* ]] && fnDisableAutoUpdates


################################################################################
# Set timezone to Europe/Amsterdam
################################################################################

## Module Functions

# Functions for a modular approach
fnSetTimezone() {
    printstatus "Set the timezone to Europe/Amsterdam:"
    TIMEZONE="Europe/Amsterdam"

    printl "  - Set the timezone to ${TIMEZONE}"
    sudo timedatectl set-timezone ${TIMEZONE}
}

# Start when module is selected
[[ $MYMENU == *"TZADAM"* ]] && fnSetTimezone


################################################################################
## Testing with Case to evaluate and order activity
################################################################################

IFS='" "' read -r -a array <<< "${MYMENU}"
for element in "${array[@]}"
do
    echo "$element"
    case ${element} in
    *"CHANGE_LANG"*)
        printl "Option CHANGE_LANG was selected"
        ;;
    *"CUST_OPS"*)
        printl "Option CUST_OPS was selected"
        ;;
    1)
        echo "Hello"
        ;;

    2)
        echo "call"
        ;;

    3)
        echo "bye"
        ;;

    *)
        echo "Unknown - ${MYMENU}"
        ;;
    esac
done

# echo -e "\nWorking on element ${MYMENU}"
# case ${MYMENU} in
# *"CHANGE_LANG"*)
#     printl "Option CHANGE_LANG was selected"
#     ;;
# *"CUST_OPS"*)
#     printl "Option CUST_OPS was selected"
#     ;;
# 1)
#     echo "Hello"
#     ;;

# 2)
#     echo "call"
#     ;;

# 3)
#     echo "bye"
#     ;;

# *)
#     echo "Unknown - ${MYMENU}"
#     ;;
# esac



# for element in "${MYMENU[@]}"; do
#     echo -e "\nWorking on element ${element}"
#     case ${element} in
#     CHANGE_LANG)
#         printl "Option CHANGE_LANG was selected"
#         ;;
#     1)
#         echo "Hello"
#         ;;

#     2)
#         echo "call"
#         ;;

#     3)
#         echo "bye"
#         ;;

#     *)
#         echo "Unknown - ${element}"
#         ;;
#     esac
# done


################################################################################
## Some cleanup at the end...
################################################################################
#rm -rf /var/cache/apt/archives/apt-fast
#$PCKMGR $AQUIET -y clean 2>&1 | tee -a $LOGFILE

printstatus "All done."
printf "${BIGreen}== ${BIYELLOW}When complete, remove the script from the /home/$USERID directory.\r\n" >> $LOGFILE
printf "${BIGreen}==\r\n" >> $LOGFILE
printf "${BIGreen}== ${BIPurple}Current IP: %s${BIWhite}\r\n" "$MY_IP" >> $LOGFILE
# printl ""
# printl "Current IP: $MY_IP"
# printl "Changed Hostname: $NEWHOSTNAME"

if [[ $REBOOTREQUIRED == *"1"* ]]; then
    if (whiptail --title "Script Finished" --yesno "Changes made require a REBOOT.\nOK?" 8 78); then
        printl "Script is Finished. Rebooting now."
        shutdown -r now
    else
        whiptail --title "Script Finished" --msgbox "Changes made require a REBOOT.\nPlease reboot ASAP." 8 78
        echo ""
        printl "Script is Finished. Changes made require a reboot. Please REBOOT asap!"
        echo ""
    fi
else
    echo ""
    printl "ALL DONE - No reboot required. But will not harm by doing."
    echo ""
fi
