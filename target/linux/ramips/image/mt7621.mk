#
# MT7621 Profiles
#

include common-teltonika.mk
include devices/common_mt7621.mk
include devices/rutmxx_family.mk
include devices/tap2xx_family.mk
include devices/otd5xx_family.mk
include devices/atrmxx_family.mk

KERNEL_LOADADDR := 0x80001000

define Device/tlt-mt7621-common
	HW_MODS := blv1
endef

define Device/teltonika_tap200
	$(Device/DefaultTeltonika)
	$(Device/tlt-mt7621-common)
	$(Device/tlt-desc-tap200)
	SOC := mt7621
	DEVICE_MODEL := TAP200
	DEVICE_INITIAL_FIRMWARE_SUPPORT := 7.5
	DEVICE_FEATURES := access_point single_port wifi small_flash dot1x-client no-wired-wan reset_button

	GPL_PREFIX := GPL
	DEVICE_DTS := mt7621-teltonika-tap200$(if $(CONFIG_BUILD_FACTORY_TEST_IMAGE),-factory)
	KERNEL := kernel-bin | append-dtb | lzma | uImage lzma
	BLOCKSIZE := 64k
	PAGESIZE := 2048
	FILESYSTEMS := squashfs

	DEVICE_DTS := mt7621-teltonika-tap200
	DEVICE_BOOT_NAME := tlt-mt7621
	# UBOOT_SIZE = "u-boot" + "u-boot-env"
	UBOOT_SIZE := 327680
	CONFIG_SIZE := 65536
	ART_SIZE := 65536
	NO_ART := 0
	IMAGE_SIZE := 15335k
	MASTER_IMAGE_SIZE := 15335k

	IMAGE/sysupgrade.bin = \
			append-kernel | pad-to $$$$(BLOCKSIZE) | \
			append-rootfs | pad-rootfs | append-metadata | \
			check-size $$$$(IMAGE_SIZE) | finalize-tlt-webui

	IMAGE/master_fw.bin = \
			append-tlt-uboot | pad-to $$$$(UBOOT_SIZE) | \
			append-tlt-config | pad-to $$$$(CONFIG_SIZE) | \
			append-tlt-art | pad-to $$$$(ART_SIZE) | \
			append-kernel | pad-to $$$$(BLOCKSIZE) | \
			append-rootfs | pad-rootfs | \
			append-version | \
			check-size $$$$(MASTER_IMAGE_SIZE) | \
			finalize-tlt-master-stendui

	DEVICE_PACKAGES := kmod-mt7621-qtn-rgmii

	DEVICE_PACKAGES.basic := kmod-mt7615e_66 kmod-mt7615-common_66 \
			   kmod-mt7615-firmware_66

	INCLUDED_DEVICES := \
		TEMPLATE_teltonika_tap200
endef

define Device/teltonika_rutm
	$(Device/DefaultTeltonika)
	$(Device/tlt-mt7621-common)
	SOC := mt7621
	DEVICE_MODEL := RUTM
	DEVICE_DTS := $(foreach dts,$(notdir $(wildcard $(PLATFORM_DIR)/dts/mt7621-teltonika-rutm*.dts)),$(patsubst %.dts,%,$(dts)))
	KERNEL = kernel-bin | gzip | fit gzip "$$(KDIR)/{$$(subst $$(space),$$(comma),$$(addprefix image-,$$(addsuffix .dtb,$$(DEVICE_DTS))))}"
	BLOCKSIZE := 128k
	PAGESIZE := 2048
	FILESYSTEMS := squashfs
	KERNEL_IN_UBI := 1
	DEVICE_INITIAL_FIRMWARE_SUPPORT := 7.4
	DEVICE_FEATURES := usb-port ncm poe gps serial modbus ios wifi dualsim bt \
			port-mirror ntrip bacnet hw-offload tlt-failsafe-boot mobile \
			modem-reset-quirk dot1x-client portlink dot1x-server \
			xfrm-offload tpm reset_button

	GPL_PREFIX := GPL
	DEVICE_BOOT_NAME := tlt-mt7621
	UBOOT_SIZE := 524288
	CONFIG_SIZE := 65536
	ART_SIZE := 65536
	NO_ART := 0
	MASTER_IMAGE_SIZE := 147456k

	IMAGE/sysupgrade.bin = append-ubi | append-metadata | finalize-tlt-webui

	IMAGE/master_fw.bin = \
			append-tlt-uboot | pad-to $$$$(UBOOT_SIZE) | \
			append-tlt-config | pad-to $$$$(CONFIG_SIZE) | \
			append-tlt-art | pad-to $$$$(ART_SIZE) | \
			append-ubi | \
			append-version | \
			check-size $$$$(MASTER_IMAGE_SIZE) | \
			finalize-tlt-master-stendui

	DEVICE_PACKAGES := kmod-mt7621-qtn-rgmii kmod-mt7615e_66 \
			   kmod-mt7615-common_66 kmod-mt7615-firmware_66 \
			   kmod-crypto-hw-eip93 kmod-hwmon-tla2021

	# USB related:
	DEVICE_PACKAGES += kmod-usb-core kmod-usb3 kmod-usb-serial kmod-usb-acm \
			kmod-usb-serial-ch341 kmod-usb-serial-pl2303 kmod-usb-serial-ark3116 \
			kmod-usb-serial-belkin kmod-usb-serial-cp210x kmod-usb-serial-cypress-m8 \
			kmod-usb-serial-ftdi kmod-usb-serial-ch343 kmod-sdhci-mt7620

	HW_MODS += W25N02KV RUTM52_TUSB8020B

	INCLUDED_DEVICES := \
		TEMPLATE_teltonika_rutm08 \
		TEMPLATE_teltonika_rutm09 \
		TEMPLATE_teltonika_rutm10 \
		TEMPLATE_teltonika_rutm11 \
		TEMPLATE_teltonika_rutm12 \
		TEMPLATE_teltonika_rutm20 \
		TEMPLATE_teltonika_rutm30 \
		TEMPLATE_teltonika_rutm31 \
		TEMPLATE_teltonika_rutm50 \
		TEMPLATE_teltonika_rutm51 \
		TEMPLATE_teltonika_rutm52 \
		TEMPLATE_teltonika_rutm54 \
		TEMPLATE_teltonika_rutm55 \
		TEMPLATE_teltonika_rutm56 \
		TEMPLATE_teltonika_rutm59

	DEVICE_MODEM_VENDORS := Quectel Telit
	DEVICE_MODEM_LIST := EG06 EG060K EG12 RM520N RG520N RG500U RG501Q FN990A EC200A
endef
TARGET_DEVICES += teltonika_rutm

define Device/teltonika_atrm50
	$(Device/DefaultTeltonika)
	$(Device/tlt-mt7621-common)
	$(Device/tlt-desc-atrm50)
	SOC := mt7621
	DEVICE_MODEL := ATRM50
	DEVICE_DTS = $$(SOC)_$(1)
	KERNEL = kernel-bin | gzip | fit gzip "$$(KDIR)/{$$(subst $$(space),$$(comma),$$(addprefix image-,$$(addsuffix .dtb,$$(DEVICE_DTS))))}"
	BLOCKSIZE := 128k
	PAGESIZE := 2048
	FILESYSTEMS := squashfs
	KERNEL_IN_UBI := 1
	DEVICE_INITIAL_FIRMWARE_SUPPORT := 7.13
	DEVICE_DTS := mt7621_teltonika_atrm50
	DEVICE_FEATURES := usb-port ncm gps serial modbus power-control wifi dualsim \
			port-mirror ntrip hw-offload tlt-failsafe-boot mobile modem-reset-quirk portlink dot1x-server framed-routing \
			xfrm-offload tpm reset_button

	DEVICE_BOOT_NAME := tlt-mt7621
	UBOOT_SIZE := 524288
	CONFIG_SIZE := 65536
	ART_SIZE := 65536
	NO_ART := 0
	MASTER_IMAGE_SIZE := 147456k

	IMAGE/sysupgrade.bin = append-ubi | append-metadata | finalize-tlt-webui

	IMAGE/master_fw.bin = \
			append-tlt-uboot | pad-to $$$$(UBOOT_SIZE) | \
			append-tlt-config | pad-to $$$$(CONFIG_SIZE) | \
			append-tlt-art | pad-to $$$$(ART_SIZE) | \
			append-ubi | \
			append-version | \
			check-size $$$$(MASTER_IMAGE_SIZE) | \
			finalize-tlt-master-stendui

	DEVICE_PACKAGES := kmod-mt7621-qtn-rgmii kmod-mt7615e_66 \
			   kmod-mt7615-common_66 kmod-mt7615-firmware_66 \
			   kmod-crypto-hw-eip93

	# USB related:
	DEVICE_PACKAGES += kmod-usb-core kmod-usb3 kmod-usb-serial kmod-usb-acm \
			kmod-usb-serial-ch341 kmod-usb-serial-pl2303 kmod-usb-serial-ark3116 \
			kmod-usb-serial-belkin kmod-usb-serial-cp210x kmod-usb-serial-cypress-m8 \
			kmod-usb-serial-ftdi kmod-usb-serial-ch343 kmod-sdhci-mt7620

	HW_MODS += W25N02KV

	INCLUDED_DEVICES := \
		TEMPLATE_teltonika_atrm50

	DEVICE_MODEM_VENDORS := Quectel
	DEVICE_MODEM_LIST := RG501Q RG520

endef

define Device/teltonika_otd5
	$(Device/DefaultTeltonika)
	$(Device/tlt-mt7621-common)
	SOC := mt7621
	DEVICE_MODEL := OTD5
	DEVICE_DTS := $(foreach dts,$(notdir $(wildcard $(PLATFORM_DIR)/dts/mt7621-teltonika-otd5*.dts)),$(patsubst %.dts,%,$(dts)))
	KERNEL = kernel-bin | gzip | fit gzip "$$(KDIR)/{$$(subst $$(space),$$(comma),$$(addprefix image-,$$(addsuffix .dtb,$$(DEVICE_DTS))))}"
	BLOCKSIZE := 128k
	PAGESIZE := 2048
	FILESYSTEMS := squashfs
	KERNEL_IN_UBI := 1
	DEVICE_INITIAL_FIRMWARE_SUPPORT := 7.10.1
	DEVICE_FEATURES := ncm poe dualsim hw-offload \
			tlt-failsafe-boot mobile modem-reset-quirk portlink dot1x-server framed-routing xfrm-offload networks_external no-wired-wan \
			tpm reset_button

	DEVICE_BOOT_NAME := tlt-mt7621
	UBOOT_SIZE := 524288
	CONFIG_SIZE := 65536
	ART_SIZE := 65536
	NO_ART := 0
	MASTER_IMAGE_SIZE := 147456k

	IMAGE/sysupgrade.bin = append-ubi | append-metadata | finalize-tlt-webui

	IMAGE/master_fw.bin = \
			append-tlt-uboot | pad-to $$$$(UBOOT_SIZE) | \
			append-tlt-config | pad-to $$$$(CONFIG_SIZE) | \
			append-ubi | \
			append-version | \
			check-size $$$$(MASTER_IMAGE_SIZE) | \
			finalize-tlt-master-stendui

	DEVICE_PACKAGES := kmod-mt7621-qtn-rgmii kmod-crypto-hw-eip93

	# USB related:
	DEVICE_PACKAGES += kmod-usb-core kmod-usb3 kmod-usb-serial kmod-usb-acm

	DEVICE_MODEM_VENDORS := Quectel
	DEVICE_MODEM_LIST := RG520N

	INCLUDED_DEVICES := \
		TEMPLATE_teltonika_otd500 \
		TEMPLATE_teltonika_otd501
		
	SUPPORTED_DEVICES := teltonika,otd5 teltonika,otd500 teltonika,otd501
endef
