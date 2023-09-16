#!/bin/bash
# compile kernel selftests for pseudo_mm
# cd /root/linux && make O=/root/ -C tools/testing/selftests TARGETS=pseudo_mm

# create a initramfs
# do not forget to run make modules_install when compiling linux kernel code
# mkinitramfs -o ~/initramfs-6.1.0 6.1.0-rc8+
#

rm -f /root/multipass-shared/rootfs-work
cp --reflink=auto /root/multipass-shared/rootfs /root/multipass-shared/rootfs-work

qemu-system-x86_64 -kernel  ~/linux/arch/x86/boot/bzImage \
  -nographic \
  -netdev user,id=n1 \
  -device e1000,netdev=n1 \
  -m 16G,slots=10,maxmem=64G \
  -machine pc,nvdimm=on \
  -cpu host \
  --enable-kvm \
  -initrd /root/initramfs-6.1.0 \
  -object memory-backend-file,id=mem1,share=on,mem-path=/dev/dax0.0,size=4G,align=2M,readonly=off \
  -device nvdimm,id=nvdimm1,memdev=mem1,unarmed=off \
  -hda /root/multipass-shared/rootfs-work \
  -append 'console=ttyS0 root=/dev/sda rw'
  # -append 'console=ttyS0' \
