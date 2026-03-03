#
# Copyright (C) 2021 Teltonika
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=host_block
PKG_VERSION:=2025-10-14
PKG_RELEASE:=1

PKG_SOURCE_VERSION:=1.11.1
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_SOURCE_VERSION)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_SOURCE_SUBDIR).tar.gz
PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/host_block
	SECTION:=base
	CATEGORY:=Base system
	TITLE:=Host Block
	DEPENDS:=+dnsmasq
	USERID:=hostblock=505:hostblock=505
endef

define Package/host_block/conffiles
/etc/config/hostblock
endef



define Package/host_block/install
	$(INSTALL_DIR) $(1)/etc/init.d/ $(1)/etc/config/ $(1)/usr/sbin/ $(1)/usr/share/acl.d/ $(1)/etc/permtab.d/ $(1)/etc/uci-defaults/7.18
	$(INSTALL_BIN_USR) $(PKG_BUILD_DIR)/files/hostblock.init $(1)/etc/init.d/hostblock
	$(INSTALL_CONF_USR) $(PKG_BUILD_DIR)/files/hostblock.conf $(1)/etc/config/hostblock
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/hostblock.sh $(1)/usr/sbin/hostblock.sh
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/hostblock.json $(1)/usr/share/acl.d/hostblock.json
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/hostblock.permtab $(1)/etc/permtab.d/hostblock
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/migrations/7.18/99_migrate_notinterface $(1)/etc/uci-defaults/7.18/99_migrate_notinterface
endef

$(eval $(call BuildPackage,host_block))
