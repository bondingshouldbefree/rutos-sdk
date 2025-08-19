#
# Copyright (C) 2024 Teltonika-Networks
#

include $(TOPDIR)/rules.mk

PKG_NAME:=uboot-mt7621


ifeq ($(CONFIG_TARGET_ramips_mt76x8),y)
  PKG_SOURCE_VERSION:=4872f5d08214a55560eab1aa6a567488fd571f77
else
  PKG_SOURCE_VERSION:=2.18-mt7621
endif

PKG_ASLR_PIE:=0

PKG_LICENSE:=GPL-2.0-or-later

include $(INCLUDE_DIR)/package.mk

define Package/uboot-mt7621
	SECTION:=boot
	CATEGORY:=Boot Loaders
	TITLE:=Uboot for Teltonika MT7621 based boards
endef

define Build/Configure
	$(if $(CONFIG_TARGET_ramips_mt76x8),\
		$(if $(call device_shortname),\
			$(MAKE) -C $(PKG_BUILD_DIR) mt7628_tlt_$(call device_shortname)_defconfig,\
			$(MAKE) -C $(PKG_BUILD_DIR) mt7628_tlt_rute_defconfig;) \
	, \
		$(if $(call device_shortname),\
			$(MAKE) -C $(PKG_BUILD_DIR) mt7621_tlt_$(call device_shortname)_defconfig,\
			$(MAKE) -C $(PKG_BUILD_DIR) mt7621_tlt_rutm_defconfig;) \
	)
endef

OVERRIDE_PATH := /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

define Build/Compile
	# Python older than 3.12 requires its header appended explicitly to the include path
	env -i PATH=$(OVERRIDE_PATH) HOME=$(PKG_BUILD_DIR) \
		$(MAKE) -C $(PKG_BUILD_DIR) \
			BUILD_TOPDIR=$(PKG_BUILD_DIR) \
			CROSS_COMPILE=$(TOOLCHAIN_DIR)/bin/$(TARGET_CROSS) \
			$(if $(findstring 3.11,$(shell $(PYTHON) --version)),HOSTCFLAGS="$(HOSTCFLAGS) -I/usr/include/python3.11") \
			STAGING_DIR=$(PKG_BUILD_DIR)
endef

define Package/uboot-mt7621/install
	$(if $(CONFIG_TARGET_ramips_mt76x8),\
		$(CP) $(PKG_BUILD_DIR)/u-boot-mt7628.bin $(BIN_DIR)/u-boot_tlt-mt7628.bin; \
		$(CP) $(PKG_BUILD_DIR)/u-boot-mt7628_webui.bin $(BIN_DIR)/u-boot_tlt-mt7628_webui.bin \
	, \
		$(CP) $(PKG_BUILD_DIR)/u-boot-mt7621.bin $(BIN_DIR)/u-boot_tlt-mt7621.bin; \
		$(CP) $(PKG_BUILD_DIR)/u-boot-mt7621_webui.bin $(BIN_DIR)/u-boot_tlt-mt7621_webui.bin \
	)
	$(CP) $(PKG_BUILD_DIR)/version $(BIN_DIR)/u-boot_version
endef

$(eval $(call BuildPackage,uboot-mt7621))
