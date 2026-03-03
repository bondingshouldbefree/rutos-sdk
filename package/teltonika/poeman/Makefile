#
# Copyright (C) 2024 Teltonika-Networks
#

include $(TOPDIR)/rules.mk

PKG_NAME:=poeman

PKG_SOURCE_VERSION:=2.15.1
PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

GPL_INCLUDE_HEADERS:=1

define Package/poeman
	SECTION:=base
	CATEGORY:=Base system
	TITLE:=POE manager
	DEPENDS:= +libubus +libubox +libuci +libmnfinfo +libgpiod
	USERID:=poeman:poeman
endef

define Package/libpoeman
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=Device POE manager API library
  DEPENDS:= +libubox +libuci +libmnfinfo
endef

define Build/InstallDev
	$(INSTALL_DIR) $(STAGING_DIR)/usr/lib $(STAGING_DIR)/usr/include/libpoeman
	$(CP) $(PKG_BUILD_DIR)/*.so $(STAGING_DIR)/usr/lib/
	$(CP) $(PKG_BUILD_DIR)/include/*.h $(STAGING_DIR)/usr/include/libpoeman
endef


define Package/poeman/install
	$(INSTALL_DIR) $(1)/etc/init.d $(1)/usr/bin $(1)/lib/config.d $(1)/usr/share/acl.d $(1)/etc/permtab.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/poeman.init $(1)/etc/init.d/poeman
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/poeman $(1)/usr/bin/poeman
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/files/config.d/600-generate-poe-config $(1)/lib/config.d/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/acl.d/poeman.json $(1)/usr/share/acl.d/poeman.json
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/permtab.d/poeman $(1)/etc/permtab.d/poeman
endef

define Package/libpoeman/install
	$(INSTALL_DIR) $(1)/usr/lib/rpcd/shared
	$(CP) $(PKG_BUILD_DIR)/libpoeman.so $(1)/usr/lib/rpcd/shared/
endef

$(eval $(call BuildPackage,poeman))
$(eval $(call BuildPackage,libpoeman))
