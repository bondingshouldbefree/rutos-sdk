#
# Copyright (C) 2009 OpenWrt.org
#

SUBTARGET:=mt7621
BOARDNAME:=MT7621 based boards
FEATURES+=nand rtc usb dsa soft_port_mirror
CPU_TYPE:=1004kc
ARCH_PACKAGES:=mipsel_24kc
KERNELNAME:=vmlinux vmlinuz
# make Kernel/CopyImage use $LINUX_DIR/vmlinuz
IMAGES_DIR:=../../..

define Target/Description
	Build firmware images for Ralink MT7621 based boards.
endef
