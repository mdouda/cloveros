if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Colors, bb
normal=$'\e[0m'; red=$'\e[31;01m'; green=$'\e[32;01m'; yellow=$'\e[33;01m';

read -p "Automatic partitioning (a) or manual partitioning? (m) [a/m] " -n 1 partitioning
echo
if [[ $partitioning = "a" ]]; then
    read -e -p "Enter drive for CloverOS installation: " -i "/dev/sda" drive
    partition=${drive}1
elif [[ $partitioning = "m" ]]; then
    echo "Make sure you've mounted your partitions to gentoo/*!!"
    read -e -p "Enter partition for CloverOS installation: " -i "/dev/sda1" partition
    drive=${partition%"${partition##*[!0-9]}"}
else
    echo "Invalid option."
    exit 1
fi
drive=${drive#*/dev/}
partition=${partition#*/dev/}
read -p "Partitioning: $partitioning
Drive: /dev/$drive
Partition: /dev/$partition
Is this correct? [y/n] " -n 1 yn
if [[ $yn != "y" ]]; then
    exit 1
fi
echo

read -p "Enter preferred root password " rootpassword
read -p "Enter preferred username " user
read -p "Enter preferred user password " userpassword

mkdir gentoo

if [[ $partitioning = "a" ]]; then
    echo -e "o\nn\np\n1\n\n\nw" | fdisk /dev/$drive
fi
mkfs.ext4 -F /dev/$partition
tune2fs -O ^metadata_csum /dev/$partition
mount /dev/$partition gentoo

cd gentoo

wget http://distfiles.gentoo.org/releases/amd64/autobuilds/20181002T214501Z/stage3-amd64-20181002T214501Z.tar.xz
tar pxf stage3*
rm -f stage3*

cp /etc/resolv.conf etc
mount -t proc none proc
mount --rbind /dev dev
mount --rbind /sys sys

echo "The default Desktop Environment is XFCE. Would you like to change that (y/N)?"
read de_change
if [ $"de_change" = "y"] || [ $"de_change" = "Y" ]; then
    echo "Here are the available Desktop environments: \n"
    echo -n -e "${green}* ${green}(X)FCE${normal} \n";
    echo -n -e "${yellow}* ${green}(K)DE Plasma${normal} \n";
    echo -n -e "${yellow}* ${green}(C)innamon${normal} \n";
    echo -n -e "${yellow}* ${green}(LXD)E${normal} \n";
    echo -n -e "${yellow}* ${green}(LXQ)T${normal} \n";
    echo -n -e "${yellow}* ${green}(M)ATE${normal} \n";
    echo 
    echo "Which DE would you like (X|K|C|M|LXD|LXQ)?"
    read DE
    case $DE in        
        K)
            desktop="plasma-desktop"
            ;;
        C)
            desktop="cinnamon"
            ;;
        M)
            desktop="mate-base/mate"
            ;;
        LXD)
            desktop="lxde-meta"
            ;;
        LXQ)
            desktop="lxqt-meta"
            ;;
        *)
            desktop="xfce4-meta xfce4-notifyd"
            ;;
    esac
fi


cat << EOF | chroot .

emerge-webrsync
eselect profile set 16

echo -e '\nMAKEOPTS="-j2"\nEMERGE_DEFAULT_OPTS="--keep-going=y --autounmask-write=y --jobs=2"\nCFLAGS="-O3 -pipe -march=native"\nCXXFLAGS="\${CFLAGS}"' >> /etc/portage/make.conf

#emerge gentoo-sources genkernel
#wget http://liquorix.net/sources/4.9/config.amd64
#genkernel --kernel-config=config.amd64 all

wget -O - https://github.com/TheNightmanCodeth/cloveros/raw/master/kernel.tar.xz | tar xJ -C /boot/
mkdir /lib/modules/
wget -O - https://github.com/TheNightmanCodeth/cloveros/raw/master/modules.tar.xz | tar xJ -C /lib/modules/

emerge grub dhcpcd

grub-install /dev/$drive
grub-mkconfig > /boot/grub/grub.cfg

rc-update add dhcpcd default

echo -e "$rootpassword\n$rootpassword" | passwd
useradd $user
echo -e "$userpassword\n$userpassword" | passwd $user
gpasswd -a $user wheel

emerge openssh openssl gcc

emerge xorg-server $desktop sddm sudo xfe wpa_supplicant dash porthole firefox vim linux-firmware alsa-utils inconsolata vlgothic liberation-fonts bind-tools colordiff xdg-utils nano compton
rm -Rf /usr/portage/packages/*
sed -i "s/# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/" /etc/sudoers
sed -Ei "s@c([2-6]):2345:respawn:/sbin/agetty 38400 tty@#\0@" /etc/inittab
sed -i "s@c1:12345:respawn:/sbin/agetty 38400 tty1 linux@c1:12345:respawn:/sbin/agetty --noclear 38400 tty1 linux@" /etc/inittab
sed -i "s/set timeout=5/set timeout=0/" /boot/grub/grub.cfg
echo -e "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=wheel\nupdate_config=1" > /etc/wpa_supplicant/wpa_supplicant.conf
rc-update add alsasound default
sed -i 's/DISPLAYMANAGER="xdm"/DISPLAYMANAGER="sddm"/' /etc/conf.d/xdm
rc-update add wpa_supplicant default
rc-update add xdm default
eselect fontconfig enable 52-infinality.conf
eselect infinality set infinality
eselect lcdfilter set infinality
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
eselect locale set en_US.utf8
gpasswd -a $user audio
gpasswd -a $user video
cd /home/$user/

mkdir Downloads
chown -R $user /home/$user/

exit

EOF

echo "Rebooting..."

reboot
