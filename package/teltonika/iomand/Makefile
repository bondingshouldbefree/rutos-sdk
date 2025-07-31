#
# Copyright (C) 2024 Teltonika-Networks
#

include $(TOPDIR)/rules.mk

PKG_NAME:=iomand

PKG_SOURCE_VERSION:=2.24

PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/iomand
	SECTION:=base
	CATEGORY:=Base system
	TITLE:=Daemon providing I/O related functionality.
	DEPENDS:=+libuci +libubus +libubox +libcgi +libtlt-logger +liblog +libgpiod +kmod-tlt-pulse-counter
	ABI_VERSION:=1.0
	USERID:=ioman:ioman
endef

define Package/iomand/conffiles
/etc/config/ioman
endef


define Package/iomand/install
	$(INSTALL_DIR) $(1)/usr/bin $(1)/etc/config $(1)/etc/init.d $(1)/etc/hotplug.d/usb \
		$(1)/www/cgi-bin $(1)/usr/share/acl.d $(1)/etc/permtab.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/iomand $(1)/usr/bin/iomand
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/iomand.init $(1)/etc/init.d/ioman
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/acl.d/ioman.json $(1)/usr/share/acl.d/ioman.json
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/permtab.d/001-iomand $(1)/etc/permtab.d/001-iomand

	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/libioman.so $(1)/usr/lib/

	$(INSTALL_DIR) $(1)/etc/uci-defaults/etc

	$(if $(CONFIG_IO_SUPPORT), \
		$(CP) $(PKG_BUILD_DIR)/files/99_sms_utils-iomand $(1)/etc/uci-defaults/etc; \
	)
endef

ifneq ($(CONFIG_POWER_CONTROL_SUPPORT)$(CONFIG_IO_SUPPORT),)
define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/lib $(1)/usr/include/
	$(CP) $(PKG_BUILD_DIR)/libioman.so $(1)/usr/lib/
	$(CP) $(PKG_BUILD_DIR)/include/libioman.h $(1)/usr/include/
endef
endif

$(eval $(call BuildPackage,iomand))
