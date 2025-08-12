#
# Copyright (C) 2021 Teltonika
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=profiler

PKG_SOURCE_VERSION:=2.16

PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/profiler
	SECTION:=base
	CATEGORY:=Base system
	DEPENDS:= +libubox +libuci +libubus
	TITLE:=Configuration profiles scheduler
	USERID:=profiler=528:profiler=528
endef

define Package/profiler/description
	Configuration profiles scheduler
endef

define Package/profiler/conffiles
/etc/config/profiles
endef


define Package/profiler/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/init.d $(1)/etc/config $(1)/usr/share/acl.d $(1)/etc/permtab.d $(1)/usr/libexec/rpcd
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/profiler $(1)/usr/sbin/
	$(INSTALL_CONF_USR) $(PKG_BUILD_DIR)/files/profiles.conf $(1)/etc/config/profiles
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/profiler.init $(1)/etc/init.d/profiler
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/profile.sh $(1)/usr/sbin/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/profiler.json $(1)/usr/share/acl.d/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/profiler.permtab $(1)/etc/permtab.d/profiler
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/rpc-profile.sh $(1)/usr/libexec/rpcd/rpc-profile
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/rpc-profile.json $(1)/usr/share/acl.d/
endef

$(eval $(call BuildPackage,profiler))
