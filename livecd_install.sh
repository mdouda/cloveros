if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

read -p "Automatic partitioning (a) or manual partitioning? (m) [a/m] " -n 1 partitioning
echo
if [[ $partitioning = "a" ]]; then
    read -e -p "Enter drive for CloverOS installation: " -i "/dev/sda" drive
    partition=${drive}1
elif [[ $partitioning = "m" ]]; then
    sudo gparted > /dev/null &
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
mount /dev/$partition gentoo

unsquashfs -f -d gentoo /mnt/cdrom/image.squashfs

cat << EOF | chroot gentoo

echo -e "$rootpassword\n$rootpassword" | passwd
useradd -M $user
echo -e "$userpassword\n$userpassword" | passwd $user

grub-install /dev/$drive
grub-mkconfig > /boot/grub/grub.cfg

sed -i "s/set timeout=5/set timeout=0/" /boot/grub/grub.cfg
sed -i "s@c1:12345:respawn:/sbin/agetty -a user --noclear 38400 tty1 linux@c1:12345:respawn:/sbin/agetty --noclear 38400 tty1 linux@" /etc/inittab
sed -i '/^#/!d' /home/user/.bash_profile
sed -i 's/^#\(.*\)/\1/g' /home/user/.bash_profile
sed -i "s@/home/user/@/home/$user/@" /home/user/.rtorrent.rc

gpasswd -a $user wheel
gpasswd -a $user video
gpasswd -a $user audio
mv /home/user/ /home/$user/
chown -R $user /home/$user/
if [[ $user != "user" ]]; then
    userdel user
fi
rm /home/$user/livecd_install.sh

EOF

reboot
