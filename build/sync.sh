#!/bin/sh

# Sync VM <--> Repo.
# Run this script inside build/ directory.

# On copying from virtual disk to src/, the directory is emptied before copy. Comment out "rm -rf ../src/*" to copy onto src.

# Uncomment if you use doas instead of sudo
#alias sudo=doas

# Set this
ZEALDISK=""

[ -z $ZEALDISK ] && echo "Please edit this script with the full path to your ZealOS virtual disk." && exit 1

TMPMOUNT=/tmp/zealtmp
USAGE="Usage: $0 [ repo | vm ]"

mount_vdisk() {
	echo "Mounting virtual disk..."
	sudo qemu-nbd -c /dev/nbd0 $ZEALDISK
	sudo partprobe /dev/nbd0       
	sudo mount /dev/nbd0p1 $TMPMOUNT
}

umount_vdisk() {
	echo "Unmounting virtual disk..."
	sync
	sudo umount $TMPMOUNT
	sudo qemu-nbd -d /dev/nbd0
}

if [ -z $1 ]
then
	echo $USAGE
else
	sudo modprobe nbd
	[ ! -d $TMPMOUNT ] && mkdir $TMPMOUNT
	case $1 in
		repo)
			echo "Emptying src..."
			rm -rf ../src/*
			mount_vdisk
			echo "Copying vdisk root to src..."
			cp -r $TMPMOUNT/* ../src
			rm ../src/Boot/BootMHD2.BIN.C
			if [ -d $TMPMOUNT/HTML ]
			then
			        echo "Copying HTML docs to docs/..."
			        cp -r $TMPMOUNT/HTML/* ../docs
			else
			        echo "No HTML docs to copy."
			fi
			umount_vdisk
			[ -f ../src/Tmp/AUTO.ISO.C ] && mv ../src/Tmp/AUTO.ISO.C ./AUTO.ISO
			echo "Finished."
			git status
			;;
		vm)
			mount_vdisk
			echo "Copying src to vdisk..."
			sudo cp -r ../src/* $TMPMOUNT
			umount_vdisk
			echo "Finished."
			;;
		*)
			echo "Unknown action."
			echo $USAGE
			;;
	esac
fi
