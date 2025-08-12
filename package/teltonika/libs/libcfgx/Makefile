#
# Copyright (C) 2024 Teltonika
#

include $(TOPDIR)/rules.mk

PKG_NAME:=libcfgx
PKG_SOURCE_VERSION:=7.17
PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=libs
	CATEGORY:=Libraries
	TITLE:=Configuration parsing library by Teltonika
	DEPENDS:=+libubox +libuci +libtlt_uci +libtlt-logger
endef

define Package/$(PKG_NAME)/description
	An abstraction over UCI and blobmsg to allow deduplication of configuration parsing logic.
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/lib $(1)/usr/include/
	$(CP) $(PKG_BUILD_DIR)/*.so $(1)/usr/lib/
	$(CP) $(PKG_BUILD_DIR)/include/*.h $(1)/usr/include/
endef


define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_BUILD_DIR)/libcfgx.so $(1)/usr/lib/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

