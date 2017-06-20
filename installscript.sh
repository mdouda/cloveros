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

wget http://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64/stage3-amd64-20170615.tar.bz2
tar pxf stage3*
rm -f stage3*

cp /etc/resolv.conf etc
mount -t proc none proc
mount --rbind /dev dev
mount --rbind /sys sys

cat << EOF | chroot .

emerge-webrsync

echo -e '\nPORTAGE_BINHOST="https://cloveros.ga"\nMAKEOPTS="-j8"\nEMERGE_DEFAULT_OPTS="--keep-going=y --autounmask-write=y --jobs=2 -G"\nCFLAGS="-O3 -pipe -funroll-loops -floop-block -floop-interchange -floop-strip-mine -ftree-loop-distribution"\nCXXFLAGS="\${CFLAGS}"' >> /etc/portage/make.conf

#emerge gentoo-sources genkernel
#wget http://liquorix.net/sources/4.9/config.amd64
#genkernel --kernel-config=config.amd64 all

wget -O - https://raw.githubusercontent.com/chiru-no/cloveros/master/kernel.tar.xz | tar xJ -C /boot/
mkdir /lib/modules/
wget -O - https://raw.githubusercontent.com/chiru-no/cloveros/master/modules.tar.xz | tar xJ -C /lib/modules/

emerge grub dhcpcd

grub-install /dev/$drive
grub-mkconfig > /boot/grub/grub.cfg

rc-update add dhcpcd default

echo -e "$rootpassword\n$rootpassword" | passwd
useradd $user
echo -e "$userpassword\n$userpassword" | passwd $user
gpasswd -a $user wheel

emerge -1 openssh openssl gcc
echo "media-video/mpv ~amd64" >> /etc/portage/package.accept_keywords
emerge xorg-server twm feh aterm sudo xfe wpa_supplicant dash porthole firefox emacs gimp mpv smplayer rtorrent weechat conky linux-firmware alsa-utils rxvt-unicode zsh zsh-completions gentoo-zsh-completions inconsolata vlgothic liberation-fonts bind-tools colordiff xdg-utils nano filezilla scrot
rm -Rf /usr/portage/packages/*
sed -i "s/# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/" /etc/sudoers
sed -Ei "s@c([2-6]):2345:respawn:/sbin/agetty 38400 tty@#\0@" /etc/inittab
sed -i "s@c1:12345:respawn:/sbin/agetty 38400 tty1 linux@c1:12345:respawn:/sbin/agetty --noclear 38400 tty1 linux@" /etc/inittab
sed -i "s/set timeout=5/set timeout=0/" /boot/grub/grub.cfg
echo -e "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=wheel\nupdate_config=1" > /etc/wpa_supplicant/wpa_supplicant.conf
rc-update add alsasound default
rc-update add wpa_supplicant default
eselect fontconfig enable 52-infinality.conf
eselect infinality set infinality
eselect lcdfilter set infinality
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
eselect locale set en_US.utf8
gpasswd -a $user audio
gpasswd -a $user video
cd /home/$user/
rm .bash_profile
wget https://raw.githubusercontent.com/chiru-no/cloveros/master/home/user/.bash_profile
wget https://raw.githubusercontent.com/chiru-no/cloveros/master/home/user/.zshrc
wget https://raw.githubusercontent.com/chiru-no/cloveros/master/home/user/.twmrc
wget https://raw.githubusercontent.com/chiru-no/cloveros/master/home/user/.Xdefaults
wget https://raw.githubusercontent.com/chiru-no/cloveros/master/home/user/wallpaper.png
wget https://raw.githubusercontent.com/chiru-no/cloveros/master/home/user/screenfetch-dev
echo -e "session = /home/$user/.rtorrent\ndirectory = /home/$user/Downloads/\nport_range = 53165-62153\ndht = on\npeer_exchange = yes\nuse_udp_trackers = yes" > .rtorrent.rc
mkdir Downloads
mkdir .rtorrent
mkdir .mpv
cd .mpv
wget https://raw.githubusercontent.com/chiru-no/cloveros/master/home/user/.mpv/config
chown -R $user /home/$user/

exit

EOF

reboot
