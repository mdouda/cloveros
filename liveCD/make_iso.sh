#!/bin/bash

###############################################################
### CloverOS liveCD creator
### make-iso.sh
### https://cloveros.ga/ 
###
### Makes a liveCD for CloverOS from latest debian XFCE iso
###
### License: DWTFYW
###############################################################

export SCRIPT_URL="https://cloveros.ga/s/installscript.sh"

# Check for dependencies - 7z, mksquashfs, wget, 	
if [ ! -f /usr/bin/xorriso ] || [ ! -f /usr/bin/7z ] || [ ! -f /usr/bin/mksquashfs ] || [ ! -f /usr/bin/wget ]; then
	echo
	echo -n "In order to build a CloverOS liveCD, you must have 7-zip, wget and squashfs-tools installed. Install them now? (Y/n)"
	read input

	case "$input" in
		y|Y)
			if [ ! -f /usr/bin/xorriso ]; then query="xorriso"; fi
			if [ ! -f /usr/bin/wget ]; then query="$query wget"; fi
			if [ ! -f /usr/bin/mksquashfs ]; then query="$query squashfs-tools"; fi
			if [ ! -f /usr/bin/7z ]; then query="$query p7zip"; fi
			sudo pacman -Syy $(echo "$query")
		;;
		*)	
			echo "ERR: Missing dependencies. Exiting..."
			exit 1
		;;
	esac
fi

# Download latest debian-live-x.x.x-amd64-xfce-desktop.iso from debian
debain_iso="https://cdimage.debian.org/debian-cd/current-live/amd64/iso-hybrid/debian-live-8.8.0-amd64-xfce-desktop.iso"
wget "$debian_iso"
export iso=$(ls "$(pwd)"/debian-live-* | tail -n1 | sed 's!.*/!!')

# Extract iso contents
7z x "$iso" -oCloverOS-DebianLive

# Extract the live filesystem
cd CloverOS-DebianLive/live
sudo unsquashfs filesystem.squashfs
cd ../..

# LiveCD FS is now located at $(pwd)/CloverOS-DebianLive/live/squashfs-root/

# Grab the installer and put it in place
sudo wget "$SCRIPT_URL" -O CloverOS-DebianLive/live/squashfs-root/usr/bin/CloverOS
echo '#!/bin/bash' | cat - CloverOS-DebianLive/live/squashfs-root/usr/bin/CloverOS > temp && sudo mv temp CloverOS-DebianLive/live/squashfs-root/usr/bin/CloverOS

# Apply permissions
sudo chmod +x CloverOS-DebianLive/live/squashfs-root/usr/bin/CloverOS

## TODO: Apply custom wallpaper /usr/share/wallpapers/Lines is default
# rm CloverOS-DebianLive/live/squashfs-root/usr/share/wallpapers/Lines/contents/images/*.png
# cp walpaper_dir/*.png CloverOS-DebianLive/live/squashfs-root/usr/share/wallpapers/Lines/contents/images/

# Remove old live FS
cd CloverOS-DebianLive/live/
rm filesystem.squashfs

# Rebuild the live FS
echo "Rebuilding filesystem..."
sudo mksquashfs squashfs-root filesystem.squashfs -b 1024k -comp xz
sudo rm -r squashfs-root

## TODO: Automate replace old md5 in md5sum.txt
echo "$(md5sum filesystem.squashfs)"

cd ../..

# Make the ISO
sudo xorriso -as mkisofs -r -J \
       	-joliet-long -l -cache-inodes \
       	-isohybrid-mbr /usr/lib/syslinux/bios/isohdpfx.bin \
       	-partition_offset 16 -A "Debian Live" \
       	-b isolinux/isolinux.bin -c isolinux/boot.cat \
       	-no-emul-boot -boot-load-size 4 -boot-info-table  \
	-o CloverOS-live-v0.01-xfce.iso CloverOS-DebianLive
