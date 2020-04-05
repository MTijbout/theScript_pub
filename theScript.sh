#!/bin/bash
################################################################################
# Filename: theScript.sh
# Date Created: 04/27/19
# Date last update: 17/jan/20
# Author: Marco Tijbout
#
# Version 0.9na
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
# 0.9na  Marco Tijbout:
#   Removed VMware Pulse stuff.
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

## Version of theScript.sh
SCRIPT_VERSION="0.9na"

## The user that executed the script.
USERID=$(logname)
# if [ "$EUID" == 0 ]; then
#     WORKDIR=/$USERID
# else
#     WORKDIR=/home/$USERID
# fi
WORKDIR=/home/$USERID

SCRIPT_NAME=`basename "$0"`
## Log file definition
LOGFILE=$WORKDIR/$SCRIPT_NAME-`date +%Y-%m-%d_%Hh%Mm`.log

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
    printl "For use with $OPSYS the package manager is set to $PCKMGR"
    PCK_INST="install -y"
    AQUIET="--quiet"
    NQUIET="-s"
    elif [[ $OPSYS == *"PHOTON"* ]]; then
    PCKMGR="tdnf"
    printl "For use with $OPSYS the package manager is set to $PCKMGR"
    PCK_INST="install -y"
    AQUIET="--quiet"
    NQUIET=""
    elif [[ $OPSYS == *"ARCH"* ]]; then
    PCKMGR="pacman"
    printl "For use with $OPSYS the package manager is set to $PCKMGR"
    PCK_INST="-S --noconfirm"
    AQUIET=""
    NQUIET=""
else
    PCKMGR="apt-get"
    printl "For use with $OPSYS the package manager is set to $PCKMGR"
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

testInternetConnection() {
## Test internet connection.
    chmod u+s /bin/ping
    if [[ "$(ping -c 1 23.1.68.60  | grep '100%' )" != "" ]]; then
        printl "${IRed} No internet connection available, aborting! ${IWhite}\r\n"
        exit 0
    fi
}

################################################################################
## MAIN SECTION OF SCRIPT
################################################################################

printstatus "Welcome to THE SCRIPT!"

printstatus "Making sure THE SCRIPT works..."

## Test internet connection.
## Disable for offline testing purposes. E.g. in VMs and no internet connection.
#testInternetConnection

## Install required software for functional menu.
$PCKMGR $AQUIET $PCK_INST whiptail ccze net-tools curl 2>&1 | tee -a $LOGFILE

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

DISTRO=$(/usr/bin/lsb_release -rs)
CHECK64=$(uname -m)
printl "DISTRO: $DISTRO"
printl "CHECK64: $CHECK64"
printl "OPSYS: $OPSYS"

#if [ ! -f /etc/AlreadyRun ]; then
#    printl "${BIRed}Script has already run - aborting${BIWhite}\r\n"; exit
#fi


## Create anchor to see if script already run.
touch /etc/AlreadyRun

################################################################################
## Main Menu Definition
################################################################################

main_menu1() {
    MMENU1=$(whiptail --title "Main Menu Selection" --checklist --notags \
        "\nSelect items as required then hit OK " 25 75 16 \
        "QUIET" "Quiet(er) install - untick for lots of info " OFF \
        "CUST_OPS" "Menu - Customization options " ON \
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
        "SHOW_IP" "Show IP on logon screen " OFF \
        "MACDHCP" "Configure to use MAC for DHCP " ON \
        "CUSTOM_PROMPT" "Updated Prompt " OFF \
        "ADD_CSCRIPT" "Add cscript to .bashrc " OFF \
        "CUSTOM_ALIAS" "Aliases for ease of use " OFF \
        "CHANGE_LANG" "Change Language to US-English " OFF \
        "NO_PASS_SUDO" "Remove sudo password requirement (NOT SECURE!) " OFF \
        3>&1 1>&2 2>&3)
printl "Output SubMenu1: $SMENU1"
MYMENU="$MYMENU $SMENU1"
}

sub_menu2() {
    SMENU2=$(whiptail --checklist --notags --title "Select securing options" \
        "\nSelect items as required then hit OK " 25 75 16 \
        "CREATE_SYSADMIN" "Create alternative sysadmin account " OFF \
        "UPDATE_HOST" "Apply latest updates available " OFF \
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

################################################################################
##                  - Executing on the selected items -                       ##
################################################################################

################################################################################
# Force the system to use en_US as the language.
################################################################################
if [[ $MYMENU == *"CHANGE_LANG"* ]]; then
    printstatus "Change the systems language settings to en_US ..."

    printl "Check if language settings exists in system environments settings. If notadd them."
    if grep -Fxq "LANGUAGE = en_US" /etc/environment
    then
        printl "String found, /etc/environment does not need updating."
        break
    else
        printl "String not found, settings will be added to /etc/environment"

    ## Add language settings to the system environments settings.
    ## Added .utf-8 for error on CentOS
cat > /etc/environment << EOF
LANGUAGE = en_US.utf-8
LC_ALL = en_US.utf-8
LANG = en_US.utf-8
LC_TYPE = en_US.utf-8
EOF
    fi

    if [[ $OPSYS == *"CENTOS"* ]]; then
        localedef -i en_US -f UTF-8 en_US.UTF-8
    fi

    printl "Check the SSH server config not to accept settings from client."
    if grep -Fxq "#AcceptEnv LANG LC_*" /etc/ssh/sshd_config
    then
        printl "/etc/ssh/sshd_config already updated."
    elif grep -Fxq "AcceptEnv LANG LC_*" /etc/ssh/sshd_config
    then
        printl "/etc/ssh/sshd_config does need updating."

        ## Define the new value
        NEWVALUE="#AcceptEnv LANG LC_*"

        ## Replace the current line with the new one in the
        sed -i "/AcceptEnv/c$NEWVALUE" "/etc/ssh/sshd_config"
        printl "/etc/ssh/sshd_config is updated."

    else
        printl "Not found at all. Add."
        NEWVALUE="#AcceptEnv LANG LC_*"
        echo "$NEWVALUE" >> /etc/ssh/sshd_config
        printl "The value: $NEWVALUE is added to sshd_config"
    fi
    ## Restart the sshd service.
    systemctl restart sshd
    if [ $? -eq 0 ]; then
        printl "sshd service is restarted."
    else 
        printl "Could not restart sshd service."
    fi
    ## Have the script reboot at the end.
    REBOOTREQUIRED=1

    ## Cleanup variables
    NEWVALUE=""
fi

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
    USERPASS=""
    USERPASS2=""
    ADMINNAME=""
    SRC=""
    DEST=""
    SRC_GROUPS=""
    SRC_SHELL=""
    NEW_GROUPS=""
    gr=""
    fi
}

if [[ $MYMENU == *"CREATE_SYSADMIN"* ]]; then
    moduleCreateSysadmin
fi

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
        $PCKMGR $AQUIET -y upgrade 2>&1 | tee -a $LOGFILE
        $PCKMGR $AQUIET -y dist-upgrade 2>&1 | tee -a $LOGFILE
        $PCKMGR $AQUIET -y autoremove 2>&1 | tee -a $LOGFILE
        $PCKMGR $AQUIET -y autoclean 2>&1 | tee -a $LOGFILE
    fi
    ## Have the script reboot at the end.
    REBOOTREQUIRED=1
}

if [[ $MYMENU == *"UPDATE_HOST"* ]]; then
    moduleUpdateHost
fi

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

if [[ $MYMENU == *"REGENERATE_SSH_KEYS"* ]]; then
    moduleRegenerateSshKeys
fi

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
        TARGETFILE=""
    fi
}
if [[ $MYMENU == *"SHOW_IP"* ]]; then
    moduleShowIp
fi

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
    RDM=""
    MAC=""
    OLDHOSTNAME=""
    GENHOSTNAME=""
    NEWHOSTNAME=""
    cloudFile=""
}

if [[ $MYMENU == *"HOST_RENAME"* ]]; then
    moduleHostRename
fi

################################################################################
# Apply a more convenient Prompt for the user.
################################################################################

## Module Functions

## Module Logic
moduleCustomPrompt () {
    printstatus "Change the prompt to a more user friendly one..."

    TARGETFILE="$WORKDIR/.bashrc"
    NEWPROMPT="export PS1='\${debian_chroot:+(\$debian_chroot)}\[\033[00;33m\]\n   \u \[\033[01;34m\] at \[\033[00;33m\] \h\[\033[00m\] \[\033[01;34m\]in \[\033[00;33m\]\w\[\033[00m\]\n\\$ '"

    if grep -Fxq "## Custom prompt settings added ..." $TARGETFILE
    then
        printl "String found, $TARGETFILE does not need updating."
        break
    else
        printl "String not found, settings will be added to $TARGETFILE"
        echo "" >> $TARGETFILE
        echo "## Custom prompt settings added ..." >> $TARGETFILE
        echo "$NEWPROMPT" >> $TARGETFILE
    fi
    ## Cleanup variables
    TARGETFILE=""
    NEWPROMPT=""
}

if [[ $MYMENU == *"CUSTOM_PROMPT"* ]]; then
    moduleCustomPrompt
fi

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
    touch "$@";
    chmod +x "$@";
    echo '#!/usr/bin/env bash' > "$@";
    nano "$@";
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
    TARGETFILE=""
    WORKFILE3=""
}

if [[ $MYMENU == *"ADD_CSCRIPT"* ]]; then
    moduleAddCscript
fi

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
alias update='sudo apt update && sudo apt upgrade -y && sudo apt autoremove && sudo apt autoclean'
EOF
    fi
    chown ${USERID}:${USERID} $TARGETFILE
    ## Cleanup variables
    TARGETFILE=""
    WORKFILE2=""
}

if [[ $MYMENU == *"CUSTOM_ALIAS"* ]]; then
    moduleCustomAlias
fi

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

if [[ $MYMENU == *"NO_PASS_SUDO"* ]]; then
    moduleNoPassSudo
fi

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
    L2RDEFVAL=""
    MODULE_NAME=""
    Log2RAM_INSTALLED=""
    Log2RAM_OS_CHECK=""
    GIT_INSTALL_SUCCES=""
}

if [[ $MYMENU == *"log2ram"* ]]; then
    moduleLog2RAM
fi

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

if [[ $MYMENU == *"MACDHCP"* ]]; then
    macDHCP
fi


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
        printl "Script is Finished. Changes made require a reboot. Pleae REBOOT asap!"
        echo ""
    fi
else
    echo ""
    printl "ALL DONE - No reboot required. But will not harm by doing."
    echo ""
fi
