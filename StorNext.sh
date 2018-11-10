#!/bin/bash

# This Script sets up the drive configurations for StorNext software from Quantum #



#######################################
# Requires that the script be run with the root user.
#######################################
USER=
requireRootUser() {
    USER="$(id -un 2>/dev/null || true)"
    if [ "$USER" != "root" ]; then
        echo >&2 "Error: This script requires admin privileges. Please re-run it as root."
        exit 1
    fi
}

requireRootUser


###############################
# Configures None 4k StorNext Drives.
###############################

none4kdrives () {
    mkdir -m 777 -p -v /mnt/fs{{02..06},{11..19}} /mnt/{hwy_fs05,bur-99002-sn00,bur-99002-sn02,bur-99003-sn00,encode03,prodstor11,HWY01}
}

#########################
# Configures 4K StorNext Drives
#########################

fourkdrives () {
    mkdir -m 777 -p -v /mnt/4kpod{18..24} /mnt/{bur_dl3_fs22,bur_dl3_fs23,hdprod01}
}

###################################
# Adds NONE 4K drive entries to /etc/fstab
###################################

none4kfstab () {
    echo "bur_dl3_fs02            /mnt/fs02               cvfs    rw              0 0" >> /etc/fstab
    echo "bur_dl3_fs03            /mnt/fs03               cvfs    rw              0 0" >> /etc/fstab
    echo "bur_dl3_fs04            /mnt/fs04               cvfs    rw              0 0" >> /etc/fstab
    echo "bur_dl3_fs05            /mnt/fs05               cvfs    rw              0 0" >> /etc/fstab
    echo "bur_dl3_fs06            /mnt/fs06               cvfs    rw              0 0" >> /etc/fstab
    echo "bur_dl3_fs10            /mnt/fs10               cvfs    rw              0 0" >> /etc/fstab
    echo "bur_dl3_fs11            /mnt/fs11               cvfs    rw              0 0" >> /etc/fstab
    echo "bur_dl3_fs12            /mnt/fs12               cvfs    rw              0 0" >> /etc/fstab
    echo "bur_dl3_fs13            /mnt/fs13               cvfs    rw              0 0" >> /etc/fstab
    echo "bur_dl3_fs14            /mnt/fs14               cvfs    rw              0 0" >> /etc/fstab
    echo "bur_dl3_fs15            /mnt/fs15               cvfs    rw              0 0" >> /etc/fstab
    echo "bur_dl3_fs16            /mnt/fs16               cvfs    rw              0 0" >> /etc/fstab
    echo "bur_dl3_fs17            /mnt/fs17               cvfs    rw              0 0" >> /etc/fstab
    echo "bur_dl3_fs18            /mnt/fs18               cvfs    rw              0 0" >> /etc/fstab
    echo "bur_dl3_fs19            /mnt/fs19               cvfs    rw              0 0" >> /etc/fstab
    echo "bur_hwy_fs05            /mnt/hwy_fs05           cvfs    rw              0 0" >> /etc/fstab
    echo "dl3t1-bur-99002-sn00    /mnt/bur-99002-sn00     cvfs    rw              0 0" >> /etc/fstab
    echo "dl3t1-bur-99002-sn02    /mnt/bur-99002-sn02     cvfs    rw              0 0" >> /etc/fstab
    echo "dl3t1-bur-99003-sn00    /mnt/bur-99003-sn00     cvfs    rw              0 0" >> /etc/fstab
    echo "encode03                /mnt/encode03           cvfs    rw              0 0" >> /etc/fstab
    echo "prodstor11              /mnt/prostor11          cvfs    rw              0 0" >> /etc/fstab
    echo "HWY01                   /mnt/HW01               cvfs    rw              0 0" >> /etc/fstab	
}   
################################
# Adds 4K drive entries to /etc/fstab
###############################

fourkfstab () {
    echo "4kpod18                 /mnt/4kpod18            cvfs    rw              0 0" >> /etc/fstab
    echo "4kpod19                 /mnt/4kpod19            cvfs    rw              0 0" >> /etc/fstab
    echo "4kpod20                 /mnt/4kpod20            cvfs    rw              0 0" >> /etc/fstab
    echo "4kpod21                 /mnt/4kpod21            cvfs    rw              0 0" >> /etc/fstab
    echo "4kpod22                 /mnt/4kpod22            cvfs    rw              0 0" >> /etc/fstab
    echo "4kpod23                 /mnt/4kpod23            cvfs    rw              0 0" >> /etc/fstab
    echo "4kpod24                 /mnt/4kpod24            cvfs    rw              0 0" >> /etc/fstab
    echo "bur_dl3_fs22            /mnt/fs22               cvfs    rw              0 0" >> /etc/fstab
    echo "bur_dl3_fs23            /mnt/fs23               cvfs    rw              0 0" >> /etc/fstab
    echo "hdrpod01                /mnt/hdrpod01           cvfs    rw              0 0" >> /etc/fstab
}

##################################
#Prompts for types of StoreNext drive configuration
###################################
driveinstalations () {
    echo "What type of drives do you want to configure?"
    echo ""
    echo "Press a for NONE 4K drives or press b for 4K drives."
    read SECONDINPUT
    case $SECONDINPUT in
        a) chkconfig --level 345 cvfs on 2>/dev/null
           none4kdrives
           none4kfstab   
           ;;
        b) chkconfig --level 345 cvfs on 2>/dev/null
           fourkdrives
           fourkfstab
           ;;
        *) echo "You did not choose a valid option."
           exit 1
    esac
}


#################################################
# Prompts User for input before running script
# Prompts User for type of StorNext drives to be installed
#################################################

prompt () {
echo "You are about to configure the StorNextDrives. Do you want to continue y/n ?"
read FIRSTINPUT
if [ $FIRSTINPUT == "n" ]; then
    echo "Goodbye"
    exit 1
    clear
elif [ $FIRSTINPUT == "y" ]; then
    echo ""
    driveinstalations
else
    echo "You did not choose a valid option."
    exit 1
fi


}

prompt
