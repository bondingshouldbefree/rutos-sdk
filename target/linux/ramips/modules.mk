# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2006-2016 OpenWrt.org

OTHER_MENU:=Other modules

define KernelPackage/pwm-mediatek-ramips
  SUBMENU:=Other modules
  TITLE:=MT7628 PWM
  DEPENDS:=@(TARGET_ramips_mt76x8)
  KCONFIG:= \
	CONFIG_PWM=y \
	CONFIG_PWM_MEDIATEK_RAMIPS \
	CONFIG_PWM_SYSFS=y
  FILES:= \
	$(LINUX_DIR)/drivers/pwm/pwm-mediatek-ramips.ko
  AUTOLOAD:=$(call AutoProbe,pwm-mediatek-ramips)
endef

define KernelPackage/pwm-mediatek-ramips/description
  Kernel modules for MediaTek Pulse Width Modulator
endef

$(eval $(call KernelPackage,pwm-mediatek-ramips))

define KernelPackage/sdhci-mt7620
  SUBMENU:=Other modules
  TITLE:=MT7620 SDCI
  DEPENDS:=@(TARGET_ramips_mt7620||TARGET_ramips_mt76x8||TARGET_ramips_mt7621) +kmod-mmc
  KCONFIG:= \
	CONFIG_MTK_MMC \
	CONFIG_MTK_AEE_KDUMP=n \
	CONFIG_MTK_MMC_CD_POLL=n
  FILES:= \
	$(LINUX_DIR)/drivers/mmc/host/mtk-mmc/mtk_sd.ko
  AUTOLOAD:=$(call AutoProbe,mtk_sd,1)
endef

$(eval $(call KernelPackage,sdhci-mt7620))

I2C_MT7621_MODULES:= \
  CONFIG_I2C_MT7621:drivers/i2c/busses/i2c-mt7621

define KernelPackage/i2c-mt7628
  $(call i2c_defaults,$(I2C_MT7621_MODULES),59)
  TITLE:=MT7628/88 I2C Controller
  DEPENDS:=+kmod-i2c-core \
	@(TARGET_ramips_mt76x8)
endef

define KernelPackage/i2c-mt7628/description
 Kernel modules for enable mt7621 i2c controller.
endef

$(eval $(call KernelPackage,i2c-mt7628))

define KernelPackage/dma-ralink
  SUBMENU:=Other modules
  TITLE:=Ralink GDMA Engine
  DEPENDS:=@TARGET_ramips @!TARGET_ramips_rt288x
  KCONFIG:= \
	CONFIG_DMADEVICES=y \
	CONFIG_RALINK_GDMA
  FILES:= \
	$(LINUX_DIR)/drivers/dma/virt-dma.ko \
	$(LINUX_DIR)/drivers/dma/ralink-gdma.ko
  AUTOLOAD:=$(call AutoLoad,52,ralink-gdma)
endef

define KernelPackage/dma-ralink/description
 Kernel modules for enable ralink gdma engine.
endef

$(eval $(call KernelPackage,dma-ralink))
