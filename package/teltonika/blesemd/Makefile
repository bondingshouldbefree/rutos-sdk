#
# Copyright (C) 2022 Teltonika
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=blesemd
PKG_SOURCE_VERSION:=7.17
PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/blesemd
	SECTION:=base
	CATEGORY:=Base system
	TITLE:=Bluetooth Low Energy Sensor management daemon
	DEPENDS:=+libubus +libuci +libblobmsg-json +bluez-libs +lsqlite3
	FATTRS:=/usr/bin/blesemd::::cap_net_raw,cap_net_admin+eip
	USERID:=blesemd=527:blesemd=527
endef

define Package/blesemd/description
	Management utility for Bluetooth Low Energy devices
endef

define Package/blesemd/conffiles
/etc/config/blesem
/etc/config/ble_devices
endef


define Package/blesemd/install
	$(INSTALL_DIR) $(1)/etc/init.d $(1)/etc/config $(1)/etc/permtab.d $(1)/usr/bin $(1)/usr/share/acl.d

	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/blesem.init $(1)/etc/init.d/blesem
	$(INSTALL_CONF_USR) $(PKG_BUILD_DIR)/files/blesem.conf $(1)/etc/config/blesem
	$(INSTALL_CONF_USR) $(PKG_BUILD_DIR)/files/ble_devices.conf $(1)/etc/config/ble_devices
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/blesemd $(1)/usr/bin/blesemd
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/blesem.json $(1)/usr/share/acl.d/blesem.json
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/blesem.permtab $(1)/etc/permtab.d/blesem
endef

$(eval $(call BuildPackage,blesemd))
