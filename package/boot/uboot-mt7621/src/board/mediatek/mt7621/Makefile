# SPDX-License-Identifier: GPL-2.0

obj-y += board.o

ifndef CONFIG_SPL_BUILD
obj-$(CONFIG_VENDOR_TLT) += fsb_flash.o
obj-$(CONFIG_VENDOR_TLT) += mnf_flash.o
obj-$(CONFIG_VENDOR_TLT) += mnf_fields.o
obj-$(CONFIG_VENDOR_TLT) += gpio.o
obj-$(CONFIG_VENDOR_TLT) += cmd_phy.o
endif
