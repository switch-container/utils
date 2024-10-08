#!/bin/bash
# run inside multipass vm

set -exuo pipefail

#my_dir="$(cd $(dirname $0) && pwd)"
my_dir=/home/ubuntu/qemu_linux/tmp

function make_rootfs_file {
    fallocate -l $rootfs_size $rootfs_file
    sudo mkfs.ext4 $rootfs_file
}
function mount_rootfs {
    sudo mount -o loop $rootfs_file $mount_point
}
function install_os_to_rootfs_in_docker {
    docker run \
        --interactive \
        --network host \
        -e http_proxy=http://127.0.0.1:7890 \
        -e https_proxy=http://127.0.0.1:7890 \
        -v $mount_point:/root \
        $docker_image <<FOE
mkdir -p /root/var/lib/pacman

# echo 1 selects man-db, yes says 'y' to all pacman's questions
# bit of a hack
(echo 1; yes) | pacman -Sy -r /root base ${install_packages[@]}

chroot /root bash
mkdir -p /root/app
python -m venv /root/app/test
source /root/app/test/bin/activate
pip install requests urllib3 matplotlib pyyaml gevent
FOE
}
function remote_root_password_in_rootfs {
    sudo chroot $mount_point <<EOF
passwd -d root
EOF
}
function enable_networking_in_rootfs {
    # And enable some pacman repos
    sudo chroot $mount_point <<EOF
# Enable dhcp and dns resolution
cat <<EOF2 >>/etc/systemd/network/a.network
[Network]
DHCP=yes
[Match]
Name=en*
EOF2
systemctl enable systemd-resolved
systemctl enable systemd-networkd

# Enable the first 5 US pacman repos
grep -A6 United\ States /etc/pacman.d/mirrorlist \
    | grep Server | sed 's/^#//' >> /etc/pacman.d/mirrorlist
EOF
}
function unmount_rootfs {
    sudo umount $mount_point
}

work_dir=$my_dir/work
output_dir=$my_dir/output
rootfs_file=$output_dir/rootfs
docker_image=archlinux:latest
mount_point=$work_dir/mnt
install_packages=(vim man man-db man-pages python iproute2 net-tools libnet libnl libcap gdb perf sysstat)
rootfs_size=12GiB

mkdir -p $mount_point
mkdir -p $work_dir
mkdir -p $output_dir

make_rootfs_file
mount_rootfs
install_os_to_rootfs_in_docker
remote_root_password_in_rootfs
enable_networking_in_rootfs
unmount_rootfs
