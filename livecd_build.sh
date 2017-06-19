if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

rootpassword=password
user=user
userpassword=password

mkdir image
cd image

wget http://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64/stage3-amd64-20170615.tar.bz2
tar pxf stage3*
rm -f stage3*

cp /etc/resolv.conf etc
mount -t proc none proc
mount --rbind /dev dev
mount --rbind /sys sys

cat << EOF | chroot .

emerge-webrsync

echo -e '\nPORTAGE_BINHOST="https://cloveros.ga"\nMAKEOPTS="-j8"\nEMERGE_DEFAULT_OPTS="--keep-going=y --autounmask-write=y --jobs=2 -G"\nCFLAGS="-O3 -pipe -march=native -funroll-loops -floop-block -floop-interchange -floop-strip-mine -ftree-loop-distribution"\nCXXFLAGS="${CFLAGS}"' >> /etc/portage/make.conf

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

emerge -1 openssh openssl
echo "media-video/mpv ~amd64" >> /etc/portage/package.accept_keywords
emerge xorg-server twm feh aterm sudo xfe wpa_supplicant dash porthole firefox emacs gimp mpv smplayer rtorrent weechat conky linux-firmware alsa-utils rxvt-unicode zsh zsh-completions gentoo-zsh-completions inconsolata vlgothic liberation-fonts bind-tools colordiff xdg-utils nano filezilla screenfetch scrot
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
gpasswd -a $user audio
gpasswd -a $user video
cd /home/$user/
rm .bash_profile
wget https://raw.githubusercontent.com/chiru-no/cloveros/master/home/user/.bash_profile
wget https://raw.githubusercontent.com/chiru-no/cloveros/master/home/user/.zshrc
wget https://raw.githubusercontent.com/chiru-no/cloveros/master/home/user/.twmrc
wget https://raw.githubusercontent.com/chiru-no/cloveros/master/home/user/.Xdefaults
wget https://raw.githubusercontent.com/chiru-no/cloveros/master/home/user/wallpaper.png
echo -e "session = /home/$user/.rtorrent\ndirectory = /home/$user/Downloads/\nport_range = 53165-62153\ndht = on\npeer_exchange = yes\nuse_udp_trackers = yes" > .rtorrent.rc
mkdir Downloads
mkdir .rtorrent
mkdir .mpv
cd .mpv
wget https://raw.githubusercontent.com/chiru-no/cloveros/master/home/user/.mpv/config
chown -R $user /home/$user/

emerge gparted squashfs-tools
sed -i "s@c1:12345:respawn:/sbin/agetty --noclear 38400 tty1 linux@c1:12345:respawn:/sbin/agetty -a user --noclear 38400 tty1 linux@" /etc/inittab
sed -i 's/^/#/' /home/user/.bash_profile
echo "if [ -z "$DISPLAY" ]; then export DISPLAY=:0; X&; sleep 1; twm; feh --bg-max wallpaper.png; urxvt -e sudo ./livecd_install.sh fi" >> /home/user/.bash_profile

wget https://raw.githubusercontent.com/chiru-no/cloveros/master/livecd_install.sh -O /home/user/livecd_install.sh
chmod +x /home/user/livecd_install.sh

emerge -uvD world
emerge --depclean
rm -Rf /usr/portage/packages/*

exit

EOF

cd ..
umount -l image/*
mksquashfs image image.squashfs -b 1024k -comp xz -Xbcj x86 -Xdict-size 100%
rm -Rf image/
