#!/bin/bash

###############################################################
### CloverOS liveCD creator
### make-iso.sh
### https://cloveros.ga/ 
###
### Makes a liveCD for CloverOS from latest gentoo KDE iso
###
### License: DWTFYW
###############################################################

# Colors, bb
normal=$'\e[0m'; red=$'\e[31;01m'; green=$'\e[32;01m'; yellow=$'\e[33;01m'

print_status() {
	echo -n -e "${yellow}* ${green}${*}${normal}\n";
}

print_neutral() {
	echo -n -e "${yellow}* ${*}${normal} \n";
}

print_err() {
	echo -n -e "${yellow}* ${red}${*}${normal} \n";
}

# This script must be run as root!
if [ "$(id -u)" != "0" ]; then
	print_err "This script must be run as root!"
	exit 1
fi

export SCRIPT_URL="https://cloveros.ga/s/installscript.sh"

# Check for dependencies - 7z, mksquashfs, wget, and xorriso
print_status "Checking for dependencies..."
if [ ! -f /usr/bin/xorriso ] || [ ! -f /usr/bin/7z ] || [ ! -f /usr/bin/mksquashfs ] || [ ! -f /usr/bin/wget ]; then
	print_neutral "In order to build a CloverOS liveCD, you must have 7-zip, wget and squashfs-tools installed. Install them now? (Y/n)"
	read input

	case "$input" in
		y|Y)
			if [ ! -f /usr/bin/xorriso ]; then query="xorriso"; fi
			if [ ! -f /usr/bin/wget ]; then query="$query wget"; fi
			if [ ! -f /usr/bin/mksquashfs ]; then query="$query squashfs-tools"; fi
			if [ ! -f /usr/bin/7z ]; then query="$query p7zip"; fi
			pacman -Syy $(echo "$query") &>> make-iso.out
		;;
		*)	
			print_err "ERR: Missing dependencies. Exiting..."
			exit 1
		;;
	esac
fi

# Download latest debian-live-x.x.x-amd64-xfce-desktop.iso from debian if not already
if [ ! -e livedvd-amd64-multilib-*.iso ]; then
	print_status "Downloading latest gentoo livecd...";
	wget "https://ftp.heanet.ie/pub/gentoo//releases/amd64/20160704/livedvd-amd64-multilib-20160704.iso" &>> make-iso.out
else
	print_status "Gentoo iso already exists. Continuing...";
fi

export iso=$(ls "$(pwd)"/livedvd-amd64-multilib-* | tail -n1 | sed 's!.*/!!')

# Extract iso contents
print_status "Extracting iso contents..."
7z x "$iso" -oCloverOS-GentooLive &>> make-iso.out

# Extract the live filesystem
print_status "Decompressing livecd filesystem..."
cd CloverOS-GentooLive/
unsquashfs image.squashfs &>> make-iso.out
cd ..

# LiveCD FS is now located at $(pwd)/CloverOS-DebianLive/live/squashfs-root/

# Grab the installer and put it in place
print_status "Downloading CloverOS install script and moving into place..."
wget "$SCRIPT_URL" -O CloverOS-GentooLive/squashfs-root/usr/bin/CloverOS &>> make-iso.out
echo '#!/bin/bash' | cat - CloverOS-GentooLive/squashfs-root/usr/bin/CloverOS > temp && mv temp CloverOS-GentooLive/squashfs-root/usr/bin/CloverOS

# Apply permissions
print_status "Making script executable..."
chmod +x CloverOS-GentooLive/squashfs-root/usr/bin/CloverOS &>> make-iso.out

# Move over installer .desktop shortcut
print_status "Installing script desktop entry..."
cp install-cloveros.desktop CloverOS-GentooLive/squashfs-root/usr/share/applications/install-cloveros.desktop

## TODO: Apply custom wallpaper /usr/share/wallpapers/Lines is default
# rm CloverOS-DebianLive/live/squashfs-root/usr/share/wallpapers/Lines/contents/images/*.png
# cp walpaper_dir/*.png CloverOS-DebianLive/live/squashfs-root/usr/share/wallpapers/Lines/contents/images/

# Remove old live FS
print_status "Removing old squashfs package..."
cd CloverOS-GentooLive/
rm -f image.squashfs

# Rebuild the live FS
print_status "Rebuilding filesystem..."
mksquashfs squashfs-root image.squashfs -b 1024k -comp xz &>> make-iso.out
rm -rf squashfs-root

## TODO: Automate replace old md5 in md5sum.txt
print_neutral "$(md5sum image.squashfs)"

cd ..

# Make the ISO
print_status "Building iso..."
xorriso -as mkisofs -r -J \
       	-joliet-long -l -cache-inodes \
       	-isohybrid-mbr /usr/lib/syslinux/bios/isohdpfx.bin \
       	-partition_offset 16 -A "Gentoo Live" \
       	-b isolinux/isolinux.bin -c isolinux/boot.cat \
       	-no-emul-boot -boot-load-size 4 -boot-info-table  \
	-o CloverOS-live-v0.01-kde.iso CloverOS-GentooLive &>> make-iso.out

print_neutral "Would you like to clean up (rm CloverOS-DebianLive)? (y/n)"
read cleanup

case "$cleanup" in
	y|Y)
	    print_status "Cleaning up..."
	    rm -rf CloverOS-GentooLive/ &>> make-iso.out
esac

print_status "All set! Iso is located at $(pwd)/CloverOS-live-v0.01-kde.iso"
