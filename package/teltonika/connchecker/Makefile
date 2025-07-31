#
# Copyright (C) 2024 Teltonika
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=connchecker
PKG_VERSION:=2025-01-15
PKG_SOURCE_VERSION:=7.11
PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/connchecker
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Connection checker
	DEPENDS:= +libubox +libubus +liblog
	USERID:=connchecker:connchecker
	$(eval CAP_DIR:=$(if $(findstring m,$(CONFIG_PACKAGE_connchecker)),,/usr/local))
	FATTRS:=$(CAP_DIR)/usr/sbin/connchecker::::cap_net_raw=ep
endef

define Package/connchecker/description
	Daemon for continuous monitoring of network connectity and DNS resolution.
endef

define Package/connchecker/conffiles
/etc/config/connchecker
endef

define Build/Configure
endef


define Package/connchecker/install
	$(eval DEST_DIR:=$$(1)$(if $(findstring m,$(CONFIG_PACKAGE_connchecker)),,/usr/local))
	$(INSTALL_DIR) $(DEST_DIR)/usr/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/connchecker $(DEST_DIR)/usr/sbin/connchecker
	$(INSTALL_DIR) $(1)/etc/init.d/
	$(INSTALL_BIN) ./files/connchecker.init $(1)/etc/init.d/connchecker
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF_USR) ./files/connchecker.config $(1)/etc/config/connchecker
	$(INSTALL_DIR) $(1)/usr/share/acl.d/
	$(INSTALL_DATA) ./files/connchecker_acl.json $(1)/usr/share/acl.d/connchecker_acl.json
	$(INSTALL_DIR) $(1)/etc/permtab.d
	$(INSTALL_DATA) ./files/connchecker.permtab $(1)/etc/permtab.d/connchecker
endef

$(eval $(call BuildPackage,connchecker))
