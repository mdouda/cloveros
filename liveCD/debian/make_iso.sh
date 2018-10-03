#!/bin/bash

###############################################################
### jOS liveCD creator
### make-iso.sh
### https://jOS.ga/ 
###
### Makes a liveCD for jOS from latest debian XFCE iso
###
### License: DWTFYW
###############################################################

# Colors, bb
normal=$'\e[0m'; red=$'\e[31;01m'; green=$'\e[32;01m'; yellow=$'\e[33;01m';

print_status() {
	echo -n -e "${yellow}* ${green}${*}${normal}\n";
}

print_neutral() {
	echo -n -e "${yellow}* ${*}${normal} \n";
}

print_err() {
	echo -n -e "${yellow}* ${red}${*}${normal} \n";
}

download_debian() {
	print_status "What liveCD will you be building (xfce|kde|cinnamon|gnome|lxde|MATE)?"
	read desktop_session

	case "$desktop_session" in
		xfce)
			print_status "Downloading latest debian xfce livecd...";
			wget "https://cdimage.debian.org/debian-cd/current-live/amd64/iso-hybrid/debian-live-9.5.0-amd64-xfce.iso" &>> make-iso.out
			;;
		kde)
			print_status "Downloading latest debian kde livecd...";
			wget "https://cdimage.debian.org/debian-cd/current-live/amd64/iso-hybrid/debian-live-9.5.0-amd64-kde.iso" &>> make-iso.out
			;;
		cinnamon)
			print_status "Downloading latest debian cinnamon livecd...";
			wget "https://cdimage.debian.org/debian-cd/current-live/amd64/iso-hybrid/debian-live-9.5.0-amd64-cinnamon.iso" &>> make-iso.out
			;;
		gnome)
			print_status "Downloading latest debian gnome livecd...";
			wget "https://cdimage.debian.org/debian-cd/current-live/amd64/iso-hybrid/debian-live-9.5.0-amd64-gnome.iso" &>> make-iso.out
			;;
		lxde)
			print_status "Downloading latest debian lxde livecd...";
			wget "https://cdimage.debian.org/debian-cd/current-live/amd64/iso-hybrid/debian-live-9.5.0-amd64-lxde.iso" &>> make-iso.out
			;;
		*)
			print_status "Downloading latest debian mate livecd...";
			wget "https://cdimage.debian.org/debian-cd/current-live/amd64/iso-hybrid/debian-live-9.5.0-amd64-mate.iso" &>> make-iso.out
			;;
	esac
}

# This script must be run as root!
if [ "$(id -u)" != "0" ]; then
	print_err "This script must be run as root!"
	exit 1
fi

export SCRIPT_URL="https://github.com/TheNightmanCodeth/jOS/raw/jOS/installscript.sh"

# Check for dependencies - 7z, mksquashfs, wget, and xorriso
print_status "Checking for dependencies..."
if [ ! -f /usr/bin/xorriso ] || [ ! -f /usr/bin/7z ] || [ ! -f /usr/bin/mksquashfs ] || [ ! -f /usr/bin/wget ]; then
	print_neutral "In order to build a jOS liveCD, you must have 7-zip, wget and squashfs-tools installed. Install them now? (Y/n)"
	read input

	case "$input" in
		y|Y)
			if [ ! -f /usr/bin/xorriso ]; then query="xorriso"; fi
			if [ ! -f /usr/bin/wget ]; then query="$query wget"; fi
			if [ ! -f /usr/bin/mksquashfs ]; then query="$query squashfs-tools"; fi
			if [ ! -f /usr/bin/7z ]; then query="$query p7zip"; fi

			if [ -f /etc/os-release ]; then
				. /etc/os-release
				OS=$NAME ## Will be 'Gentoo', 'Arch Linux', 'Debian GNU/Linux', 'Ubuntu'
				case $OS in
					"Gentoo")
							emerge $(echo "$query ")  &>> make-iso.out
							;;
					"Arch Linux")
							pacman -Syy $(echo "$query") &>> make-iso.out
							;;
					"Debian GNU/Linux")
							apt install $(echo "$query") &>> make-iso.out
							;;
					"Ubuntu")
							apt install $(echo "$query") &>> make-iso.out
							;;
				esac
			fi			
		;;
		*)	
			print_err "ERR: Missing dependencies. Exiting..."
			exit 1
		;;
	esac
fi

# Download latest debian-live-x.x.x-amd64-xfce-desktop.iso from debian if not already
if [ ! -e debian-live-*.iso ]; then
	download_debian
else
	print_status "Debian iso already exists. Are you building for a different DE?";
	read -p "${yellow}  (y/N) -> ${red} " new_de
	echo "${normal}"
	case new_de in
		[yY])
			download_debian
			;;
		*)
			print_status "Continuing..."
			;;
	esac
fi

export iso=$(ls "$(pwd)"/debian-live-* | tail -n1 | sed 's!.*/!!')

# Extract iso contents
print_status "Extracting iso contents..."
7z x "$iso" -ojOS-DebianLive &>> make-iso.out

# Extract the live filesystem
print_status "Decompressing livecd filesystem..."
cd jOS-DebianLive/live
unsquashfs filesystem.squashfs &>> make-iso.out
cd ../..

# LiveCD FS is now located at $(pwd)/jOS-DebianLive/live/squashfs-root/

# Grab the installer and put it in place
print_status "Downloading jOS install script and moving into place..."
wget "$SCRIPT_URL" -O jOS-DebianLive/live/squashfs-root/usr/bin/jOS &>> make-iso.out
echo '#!/bin/bash' | cat - jOS-DebianLive/live/squashfs-root/usr/bin/jOS > temp && mv temp jOS-DebianLive/live/squashfs-root/usr/bin/jOS

# Apply permissions
print_status "Making script executable..."
chmod +x jOS-DebianLive/live/squashfs-root/usr/bin/jOS &>> make-iso.out

# Move over installer .desktop shortcut
print_status "Installing script desktop entry..."
cp install-jOS.desktop jOS-DebianLive/live/squashfs-root/usr/share/applications/install-jOS.desktop

## TODO: Apply custom wallpaper /usr/share/wallpapers/Lines is default
# rm jOS-DebianLive/live/squashfs-root/usr/share/wallpapers/Lines/contents/images/*.png
# cp walpaper_dir/*.png jOS-DebianLive/live/squashfs-root/usr/share/wallpapers/Lines/contents/images/

# Remove old live FS
print_status "Removing old squashfs package..."
cd jOS-DebianLive/live/
rm -f filesystem.squashfs

# Rebuild the live FS
print_status "Rebuilding filesystem..."
mksquashfs squashfs-root filesystem.squashfs -b 1024k -comp xz &>> make-iso.out
rm -rf squashfs-root

## TODO: Automate replace old md5 in md5sum.txt
print_neutral "$(md5sum filesystem.squashfs)"

cd ../..

# Make the ISO
print_status "Building iso..."
xorriso -as mkisofs -r -J \
       	-joliet-long -l -cache-inodes \
       	-isohybrid-mbr /usr/share/syslinux/isohdpfx.bin \
       	-partition_offset 16 -A "Debian Live" \
       	-b isolinux/isolinux.bin -c isolinux/boot.cat \
       	-no-emul-boot -boot-load-size 4 -boot-info-table  \
	-o jOS-live-v0.01-xfce.iso jOS-DebianLive &>> make-iso.out

print_neutral "Would you like to clean up \(rm jOS-DebianLive\)? \(y/n\)"
read cleanup

case "$cleanup" in
	y|Y)
	    print_status "Cleaning up..."
	    rm -rf jOS-DebianLive/ &>> make-iso.out
esac

print_status "All set! Iso is located at $(pwd)/jOS-live-v0.01-xfce.iso"