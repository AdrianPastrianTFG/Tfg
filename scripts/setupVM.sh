#!/bin/bash

#Configuration script for the installation of NixOS with an specific service

if [ "$#" -ne 1 ]; then
	echo "ERROR: Script accepts only one parameter." >&2
	echo "Correct usage: $0 [ Service ]"
	exit 1
fi

if lsblk | grep sda ; then
	sfdisk --force /dev/sda < partitions_cp.disk
	udevadm settle

	mkfs.vfat -F 32 /dev/sda1
	mkfs.ext4 -f /dev/sda2
	udevadm settle

	mount /dev/sda2 /mnt
	udevadm settle

	mkdir -p /mnt/boot
	mount /dev/sda1 /mnt/boot
	udevadm settle

	service="$1"

	if [ -d /tmp/*repo*/ ]; then
		rm -rf /tmp/*repo*
	fi

	git clone "https://github.com/AdrianPastrianTFG/Tfg.git" /tmp/my-repo

	mkdir -p /mnt/etc/nixos

	nixos-generate-config --root /mnt

	if cp "/tmp/my-repo/VMsConf/$service/configuration.nix" /mnt/etc/nixos/ ; then
		nixos-install --no-root-passwd
		rm -rf /tmp/my-repo
	else
		echo "ERROR: The configuration.nix file could not be found" >&2
		exit 1
	fi
else
	echo "ERROR: Disks names are not correct"
fi
