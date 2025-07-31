#
# Copyright (C) 2025 Teltonika
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=libtag
PKG_VERSION:=2025-07-02
PKG_RELEASE:=1

PKG_SOURCE_VERSION:=7.16

PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/libtag
	SECTION:=libs
	CATEGORY:=Libraries
	TITLE:=Tag handling library.
	DEPENDS:=+libubox +libubus
endef

define Package/libtag/description
	Tag handling library.
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/lib $(1)/usr/include/
	$(CP) $(PKG_BUILD_DIR)/*.so $(STAGING_DIR)/usr/lib/
	$(CP) $(PKG_BUILD_DIR)/include/*.h $(STAGING_DIR)/usr/include/
endef


define Package/libtag/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_BUILD_DIR)/libtag.so $(1)/usr/lib/
endef

$(eval $(call BuildPackage,libtag))
