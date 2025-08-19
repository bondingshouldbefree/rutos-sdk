include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=azure_iothub
PKG_VERSION:=2025-07-31
PKG_RELEASE:=1

PKG_SOURCE_VERSION:=3.6
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_SOURCE_VERSION)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_SOURCE_SUBDIR).tar.gz

PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/azure_iothub
	SECTION:=base
	CATEGORY:=Base system
	DEPENDS:=+libc +libuci +libubus +libblobmsg-json +libtlt-logger \
		 +libubox +libazure-iot-sdk-c +libmnfinfo +liblua +libtlt_uci \
		 +libapi
	TITLE:=Azure IoT Hub client
	USERID:=azure=537:azure=537
endef

define Package/azure_iothub/description
	Azure IoT Hub is a utility meant to interact with
	Microsoft Azure IoT Hub cloud platform.
endef

define Package/azure_iothub/conffiles
/etc/config/azure_iothub
endef

define Build/InstallDev
	$(INSTALL_DIR) $(STAGING_DIR)/usr/include/
	$(CP) $(PKG_BUILD_DIR)/libaz_plugin_handler/*.h $(STAGING_DIR)/usr/include/

	$(INSTALL_DIR) $(1)/usr/lib/
	$(CP) $(PKG_BUILD_DIR)/libaz_plugin_handler/*.so $(STAGING_DIR)/usr/lib/
endef


define Package/azure_iothub/install
	$(INSTALL_DIR) $(1)/lib
	$(INSTALL_DIR) $(1)/lib/azure/plugins
	$(INSTALL_DIR) $(1)/lib/azure

	$(CP) $(PKG_BUILD_DIR)/libaz_plugin_handler/*.so $(1)/lib/
	$(CP) $(PKG_BUILD_DIR)/plugins/*.so $(1)/lib/azure/plugins/

	$(INSTALL_DIR) $(1)/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/azure_iothub $(1)/sbin/azure_iothub

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/azure_iothub.init $(1)/etc/init.d/azure_iothub

	$(INSTALL_DIR) $(1)/etc/config/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/azure_iothub.conf $(1)/etc/config/azure_iothub

	$(INSTALL_DIR) $(1)/etc/uci-defaults/
	$(INSTALL_DIR) $(1)/etc/uci-defaults/7.5
	$(INSTALL_DIR) $(1)/etc/uci-defaults/7.7
	$(INSTALL_DIR) $(1)/etc/uci-defaults/7.8
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/uci-default/7.5/98_azure_to_data_sender $(1)/etc/uci-defaults/7.5/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/uci-default/7.7/98_azure_data_sender_collection_fix $(1)/etc/uci-defaults/7.7/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/uci-default/7.8/99_azure_pnp $(1)/etc/uci-defaults/7.8/

	$(INSTALL_DIR) $(1)/usr/share/acl.d
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/azure_iothub.json $(1)/usr/share/acl.d/azure_iothub.json
	$(INSTALL_DIR) $(1)/etc/permtab.d
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/azure_iothub.permtab $(1)/etc/permtab.d/azure_iothub
endef

define Package/azure_iothub/prerm
	#!/bin/sh
	. /lib/functions.sh

	[ -f "/etc/config/data_sender" ] || exit 0

	. /lib/data_sender/libdata_sender.sh 
	ds_remove_plugin_cfg azure

	exit 0
endef

$(eval $(call BuildPackage,azure_iothub))
