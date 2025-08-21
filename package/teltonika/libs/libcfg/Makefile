
#
# Copyright (C) 2024 Teltonika
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=libcfg
PKG_SOURCE_VERSION:=1.4
PKG_SOURCE_DATE:=2025-07-02
PKG_ABI_VERSION:=$(call abi_version_str,$(PKG_SOURCE_DATE))

GPL_INCLUDE_HEADERS:=1

PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

MAKE_FLAGS += \
	FPIC="$(FPIC)" \
	SOVERSION="$(PKG_ABI_VERSION)"

define Package/libcfg
	SECTION:=libs
	CATEGORY:=Libraries
	TITLE:=A helper library for UCI config parsing
	DEPENDS:=+libuci +libubus +libubox
	ABI_VERSION:=$(PKG_ABI_VERSION)
endef


define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/lib $(1)/usr/include/
	$(CP) $(PKG_BUILD_DIR)/libcfg.so* $(1)/usr/lib/
	$(CP) $(PKG_BUILD_DIR)/include/libcfg.h $(1)/usr/include/
	$(CP) $(PKG_BUILD_DIR)/include/libcfg_uci.h $(1)/usr/include/
	$(CP) $(PKG_BUILD_DIR)/include/libcfg_ubus.h $(1)/usr/include/
endef

define Package/libcfg/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/libcfg.so.$(PKG_ABI_VERSION) $(1)/usr/lib/libcfg.so.$(PKG_ABI_VERSION)
endef

$(eval $(call BuildPackage,libcfg))
