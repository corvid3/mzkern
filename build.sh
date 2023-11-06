#!/bin/bash

# make sure limine exists
if ! [ -a limine/bin/limine ]
then
	echo "limine not built; building!"
	(
	  cd limine
		./bootstrap
		./configure --enable-uefi-x86-64 --enable-uefi-ia32 --enable-uefi-cd --enable-bios-cd
		make
  )
fi;

# build the kernel
echo "building kernel image"
(
	cd ksrc
	zig build
)

echo "installing kernel image & limine to mzkern.iso"
(
	# remove old installation artifacts & tmpdir if exists
	if [ -d tmpiso ]; then rm -rf tmpiso; echo "deleting old artifacts"; fi;

	# move artifacts over, move into temp dir
	mkdir tmpiso
	cp -v ksrc/zig-out/bin/mzkern \
				limine.cfg \
				limine/bin/limine-uefi-cd.bin \
				limine/bin/limine-bios-cd.bin \
				limine/bin/limine-bios.sys \
				tmpiso/

	mkdir -p tmpiso/EFI/BOOT
	cp -v limine/bin/BOOTX64.EFI tmpiso/EFI/BOOT/
	cp -v limine/bin/BOOTIA32.EFI tmpiso/EFI/BOOT/

	# create the bare-bones empty iso
	fallocate mzkern.iso -l 75M

	# create the EFI partition
	xorriso -as mkisofs -b limine-bios-cd.bin \
		-no-emul-boot -boot-load-size 4 -boot-info-table \
		--efi-boot limine-uefi-cd.bin \
		-efi-boot-part --efi-boot-image --protective-msdos-label \
		tmpiso -o mzkern.iso

	./limine/bin/limine bios-install mzkern.iso
)

