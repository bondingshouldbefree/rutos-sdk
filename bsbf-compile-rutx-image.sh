#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (C) 2025-2026 Chester A. Unal <chester.a.unal@arinc9.com>

usage() {
	echo "Usage: $0 --server-ipv4 <ADDR> --server-port <PORT> --uuid <UUID>"
	exit 1
}

# Parse arguments.
while [ $# -gt 0 ]; do
	case "$1" in
	--server-ipv4)
		[ -z "$2" ] && usage
		server_ipv4="$2"
		shift 2
		;;
	--server-port)
		[ -z "$2" ] && usage
		server_port="$2"
		shift 2
		;;
	--uuid)
		[ -z "$2" ] && usage
		uuid="$2"
		shift 2
		;;
	*)
		usage
		;;
	esac
done

# Show usage if server IPv4 address, server port, and UUID were not provided.
{ [ -z "$server_ipv4" ] || [ -z "$server_port" ] || [ -z "$uuid" ]; } && usage

BSBF_RESOURCES="https://raw.githubusercontent.com/bondingshouldbefree/bsbf-resources/refs/heads/main"

# Put the bsbf_teltonika_resources feed to the bottom of the feed list. This is
# to have the packages from other feeds ready which the bsbf packages depend on.
echo "src-git bsbf_teltonika_resources https://github.com/bondingshouldbefree/bsbf-teltonika-resources.git" >> feeds.conf.default

# Update feeds.
./scripts/feeds update

# Install needed packages from bsbf feeds.
mkdir package/feeds/bsbf_teltonika_resources
ln -s ../../../feeds/bsbf_teltonika_resources/bsbf-openwrt-resources package/feeds/bsbf_teltonika_resources/
ln -s ../../../feeds/bsbf_teltonika_resources/bsbf-resources package/feeds/bsbf_teltonika_resources/
ln -s ../../../feeds/bsbf_teltonika_resources/fping package/feeds/bsbf_teltonika_resources/
ln -s ../../../feeds/bsbf_teltonika_resources/htop package/feeds/bsbf_teltonika_resources/
ln -s ../../../feeds/bsbf_teltonika_resources/hwdata package/feeds/bsbf_teltonika_resources/
ln -s ../../../feeds/bsbf_teltonika_resources/libevdev package/feeds/bsbf_teltonika_resources/
ln -s ../../../feeds/bsbf_teltonika_resources/libimobiledevice package/feeds/bsbf_teltonika_resources/
ln -s ../../../feeds/bsbf_teltonika_resources/libimobiledevice-glue package/feeds/bsbf_teltonika_resources/
ln -s ../../../feeds/bsbf_teltonika_resources/libplist package/feeds/bsbf_teltonika_resources/
ln -s ../../../feeds/bsbf_teltonika_resources/libtatsu package/feeds/bsbf_teltonika_resources/
ln -s ../../../feeds/bsbf_teltonika_resources/libudev-zero package/feeds/bsbf_teltonika_resources/
ln -s ../../../feeds/bsbf_teltonika_resources/libusbmuxd package/feeds/bsbf_teltonika_resources/
ln -s ../../../feeds/bsbf_teltonika_resources/plp-mtu-discovery package/feeds/bsbf_teltonika_resources/
ln -s ../../../feeds/bsbf_teltonika_resources/tcp-in-udp package/feeds/bsbf_teltonika_resources/
ln -s ../../../feeds/bsbf_teltonika_resources/usbmode package/feeds/bsbf_teltonika_resources/
ln -s ../../../feeds/bsbf_teltonika_resources/usbmuxd package/feeds/bsbf_teltonika_resources/
ln -s ../../../feeds/bsbf_teltonika_resources/usbutils package/feeds/bsbf_teltonika_resources/
ln -s ../../../feeds/bsbf_teltonika_resources/xray-core package/feeds/bsbf_teltonika_resources/
ln -s ../../../feeds/bsbf_teltonika_resources/zram-swap package/feeds/bsbf_teltonika_resources/

# xray-core needs newer golang. Therefore, replace golang with the one from
# bsbf_teltonika_resources. Making xray-core point to the newer golang include
# is not enough; the newer golang must be provided to the build system to be
# able to compile xray-core. This means other go packages will also use the
# newer golang. Copy the package instead of symlinking which causes compilation
# failure.
rm -rf package/lang/golang
cp -r feeds/bsbf_teltonika_resources/golang package/lang/

# Install client resources.
mkdir -p files/etc
cp feeds/bsbf_teltonika_resources/resources-client/firewall.user files/etc/
mkdir -p files/etc/uci-defaults/etc
cp feeds/bsbf_teltonika_resources/resources-client/99-bsbf-bonding files/etc/uci-defaults/etc/

# Install xray configuration.
mkdir -p files/etc/xray
curl -s $BSBF_RESOURCES/resources-client/xray.json \
  | jq --arg SERVER "$server_ipv4" \
       --argjson PORT "$server_port" \
       --arg UUID "$uuid" '
        .outbounds[0].settings.address = $SERVER
      | .outbounds[0].settings.port = $PORT
      | .outbounds[0].settings.id = $UUID
      | .policy = {"levels": {"0": {"connIdle": 30}}}' \
  > files/etc/xray/config.json

# Install bsbf-plpmtu configuration.
mkdir -p files/usr/sbin
curl -s $BSBF_RESOURCES/resources-shared/bsbf-plpmtu \
  | sed "s/^\(PLPMTUD_NODE=\"\)[^:]*/\1$server_ipv4/" \
  > files/usr/sbin/bsbf-plpmtu

chmod +x files/usr/sbin/bsbf-plpmtu

# Install bsbf-tcp-in-udp script.
curl -s $BSBF_RESOURCES/resources-client/bsbf-tcp-in-udp \
  | sed -e "s/^PORT=.*/PORT=$server_port/" \
	-e "s/^IPv4=.*/IPv4=\"$server_ipv4\"/" \
  > files/usr/sbin/bsbf-tcp-in-udp

chmod +x files/usr/sbin/bsbf-tcp-in-udp

# Configure the build system.
#
# Enable PACKAGE_bsbf-autoconf-dhcp, PACKAGE_kmod-usb-net-cdc-ether, and
# PACKAGE_usb-modeswitch to support modems and Ethernet to USB adapters running
# in ECM mode and automatically configure them.
#
# Enable PACKAGE_kmod-usb-net-ipheth and PACKAGE_usbmuxd to support iOS
# tethering. Remove BUSYBOX_DEFAULT_LSUSB and BUSYBOX_CONFIG_LSUSB which
# conflicts with usbutils, a dependency of usbmuxd.
#
# Enable PACKAGE_kmod-usb-net-rtl8152 and PACKAGE_kmod-usb-net-rndis to support
# some Ethernet to USB adapters, RNDIS modems, and Android tethering.
#
# Enable PACKAGE_bsbf-mptcp, PACKAGE_bsbf-netspeed, PACKAGE_bsbf-plpmtu,
# PACKAGE_bsbf-rate-limiting, PACKAGE_bsbf-route, PACKAGE_bsbf-tcp-in-udp, and
# PACKAGE_bsbf-tlt-sw-link to provide the necessary components for bonding.
#
# Enable PACKAGE_vuci-app-bsbf-api and PACKAGE_vuci-app-bsbf-ui to provide a web
# UI for monitoring and managing bonding.
#
# Enable PACKAGE_htop to monitor the usage of system resources.
#
# Enable PACKAGE_iptables-mod-extra, PACKAGE_iptables-mod-tproxy, and
# PACKAGE_xray-core to provide transparent proxying.
#
# Enable PACKAGE_iperf3 to monitor network performance.
#
# Enable KERNEL_MPTCP to provide MPTCP IPv4 support.
#
# Enable PACKAGE_kmod-sched and PACKAGE_kmod-sched-bpf to support loading BPF
# programmes.
#
# Enable PACKAGE_zram-swap to provide compressed swap memory.
#
# Disable FSTOOLS_FS_ROOTFS_READONLY to have write access on the root
# filesystem.
echo 'CONFIG_PACKAGE_bsbf-autoconf-dhcp=y
CONFIG_PACKAGE_kmod-usb-net-cdc-ether=y
CONFIG_PACKAGE_usb-modeswitch=y
CONFIG_PACKAGE_kmod-usb-net-ipheth=y
CONFIG_PACKAGE_usbmuxd=y
CONFIG_PACKAGE_kmod-usb-net-rtl8152=y
CONFIG_PACKAGE_kmod-usb-net-rndis=y
CONFIG_PACKAGE_bsbf-client-web=y
CONFIG_PACKAGE_bsbf-mptcp=y
CONFIG_PACKAGE_bsbf-netspeed=y
CONFIG_PACKAGE_bsbf-plpmtu=y
CONFIG_PACKAGE_bsbf-rate-limiting=y
CONFIG_PACKAGE_bsbf-route=y
CONFIG_PACKAGE_bsbf-tcp-in-udp=y
CONFIG_PACKAGE_bsbf-tlt-sw-link=y
CONFIG_PACKAGE_vuci-app-bsbf-api=y
CONFIG_PACKAGE_vuci-app-bsbf-ui=y
CONFIG_PACKAGE_htop=y
CONFIG_PACKAGE_iptables-mod-extra=y
CONFIG_PACKAGE_iptables-mod-tproxy=y
CONFIG_PACKAGE_xray-core=y
CONFIG_PACKAGE_iperf3=y
CONFIG_KERNEL_MPTCP=y
CONFIG_PACKAGE_kmod-sched=y
CONFIG_PACKAGE_kmod-sched-bpf=y
CONFIG_PACKAGE_zram-swap=y
CONFIG_FSTOOLS_FS_ROOTFS_READONLY=n' >> .config
make defconfig

cleanup() {
	rm -rf package/lang/golang
	git restore feeds.conf.default .config package/lang/golang
	rm -rf package/feeds/bsbf_teltonika_resources
	rm -rf files
}
trap cleanup EXIT
# Exit on interrupt to call the EXIT trap.
trap 'exit 1' INT

# Compile an image and sign it.
make -j$(nproc)
make sign
