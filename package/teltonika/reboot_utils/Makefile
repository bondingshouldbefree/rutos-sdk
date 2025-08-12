#
# Copyright (C) 2022 Teltonika
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=reboot_utils
PKG_VERSION:=2025-05-15
PKG_RELEASE:=1

PKG_SOURCE_VERSION:=3.11
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_SOURCE_VERSION)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_SOURCE_SUBDIR).tar.gz

PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/reboot_utils/default
	SECTION:=utils
	CATEGORY:=Base system
endef

define Package/reboot_utils
	$(Package/reboot_utils/default)
	TITLE:=Reboot utilities
	USERID:=preboot=531:preboot=531
	MENU:=1
endef

define Package/reboot_utils-periodic
	$(Package/reboot_utils/default)
	TITLE:=Periodic reboot by Teltonika
	DEPENDS:=reboot_utils
endef

define Package/reboot_utils-periodic/conffiles
/etc/config/periodic_reboot
endef

define Package/reboot_utils-ping
	$(Package/reboot_utils/default)
	TITLE:=ping_reboot
	DEPENDS:=reboot_utils
	USER_GROUPS:=preboot:network
endef

define Package/reboot_utils-ping/conffiles
/etc/config/ping_reboot
endef



define Package/reboot_utils/install
	$(INSTALL_DIR) $(1)/usr/share/acl.d
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/preboot.json $(1)/usr/share/acl.d/
endef

define Package/reboot_utils-periodic/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/config $(1)/etc/init.d $(1)/usr/libexec/reboot_utils
	$(INSTALL_CONF_USR) $(PKG_BUILD_DIR)/files/periodic_reboot.conf $(1)/etc/config/periodic_reboot
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/periodic_reboot.init $(1)/etc/init.d/periodic_reboot
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/periodic_reboot.sh $(1)/usr/libexec/reboot_utils
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/periodic_reboot_init.sh $(1)/usr/libexec/reboot_utils
endef

define Package/reboot_utils-ping/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/init.d/ $(1)/etc/config/ $(1)/usr/libexec/reboot_utils
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/ping_reboot.init $(1)/etc/init.d/ping_reboot
	$(INSTALL_CONF_USR) $(PKG_BUILD_DIR)/files/ping_reboot.conf $(1)/etc/config/ping_reboot
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/ping_reboot.sh $(1)/usr/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/ping_reboot_init.sh $(1)/usr/libexec/reboot_utils
endef

$(eval $(call BuildPackage,reboot_utils))
$(eval $(call BuildPackage,reboot_utils-periodic))
$(eval $(call BuildPackage,reboot_utils-ping))
