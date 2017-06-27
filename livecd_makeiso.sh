#!/bin/bash

export VERSION=$1

if [ ! $2 = "-no-download" ] || [ ! -d ./files/ ]; then
	# Get files.tar.gz
	wget https://github.com/TheNightmanCodeth/cloveros/releases/download/0.1/files-all_iso.tar.gz
	tar pxf files-all_iso.tar.gz
	rm files-all_iso.tar.gz
fi

## Check for xorriso
if [ ! -e /usr/bin/xorriso ] && [ ! -e /usr/local/bin/xorriso ]; then
        echo "xorriso is missing. Please install xorriso and start the script again"
	exit 1
fi

if [ -e ./image.squashfs ]; then
	## Move the pre-created squashfs into the files dir
	cp image.squashfs files/image.squashfs
else
	echo "image.squashfs was not found in pwd. Please generate it and run this script again"
	exit 1
fi

## Check if mkiso is present
if [ -e /usr/bin/mkiso ]; then
	echo "Mkiso found"
	mkiso files isohdpfx.bin CloverOS-x86_64-$VERSION.iso CloverOS
else
	echo "Mkiso was not found. Fallback to xorriso..."
	xorriso -as mkisofs -r -J \
		-joliet-long -l -cache-inodes \
		-isohybrid-mbr isohdpfx.bin -partition_offset 16 \
		-A "CloverOS" -b isolinux/isolinux.bin -c isolinux/boot.cat \
		-no-emul-boot -boot-load-size 4 -boot-info-table -o CloverOS-x86_64-$VERSION.iso \
		CloverOS &>> live-cd.log
fi

echo "ISO Created"
