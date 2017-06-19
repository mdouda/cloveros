read -p "Enter preferred root password " rootpassword
read -p "Enter preferred username " user
read -p "Enter preferred user password " userpassword

mkdir gentoo

echo -e "o\nn\np\n1\n\n\nw" | fdisk /dev/sda
mkfs.ext4 -F /dev/sda1
mount /dev/sda1 gentoo

cd gentoo
wget http://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64/stage3-amd64-20170615.tar.bz2
tar pxf stage3*
rm stage3*

cp /etc/resolv.conf etc
mount -t proc none proc
mount --rbind /dev dev
mount --rbind /sys sys

cat << EOF | chroot .

emerge-webrsync
echo -e '\nMAKEOPTS="-j8"\nEMERGE_DEFAULT_OPTS="--keep-going=y --autounmask-write=y --jobs=2 -G"\nCFLAGS="-O3 -pipe -march=native"\nCXXFLAGS="\${CFLAGS}"' >> /etc/portage/make.conf

emerge gentoo-sources genkernel
wget http://liquorix.net/sources/4.9/config.amd64
genkernel --kernel-config=config.amd64 all

emerge grub dhcpcd
grub-install /dev/sda
grub-mkconfig > /boot/grub/grub.cfg
rc-update add dhcpcd default

echo -e "$rootpassword\n$rootpassword" | passwd
useradd $user
echo -e "$userpassword\n$userpassword" | passwd $user
gpasswd -a $user wheel

exit

EOF

reboot
