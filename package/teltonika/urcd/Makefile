#
# Copyright (C) 2023 Teltonika
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=urcd

PKG_SOURCE_VERSION:=1.8

PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/urcd
	MENU:=1
	SECTION:=net
	CATEGORY:=Network
	TITLE:=GSM URC manager
	DEPENDS:= +libubus +libubox +libgsm +liburc +libuci \
		+libtlt-logger +libboardjson +liblog +libcfg
endef


define Package/urcd/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/init.d/ $(1)/usr/share/acl.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/urcd $(1)/usr/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/urcd.init $(1)/etc/init.d/urcd
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/urcd.json $(1)/usr/share/acl.d/
endef

$(eval $(call BuildPackage,urcd))
