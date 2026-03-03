#
# Copyright (C) 2021 Teltonika
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=rms-packages
PKG_VERSION:=2026-02-11
PKG_RELEASE:=1

PKG_SOURCE_VERSION:=3.26
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_SOURCE_VERSION)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_SOURCE_SUBDIR).tar.gz

PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/librms
	SUBMENU:=RMS
	SECTION:=base
	CATEGORY:=Base system
	TITLE:=Library for handling rms information
	DEPENDS:=+libubus +libubox +libblobmsg-json
endef

define Package/rms_mqtt
	SUBMENU:=RMS
	SECTION:=base
	CATEGORY:=Base system
	TITLE:=MQTT application for RMS by Teltonika
	DEPENDS:=+libmosquitto +libmnfinfo +libopenssl +libuci +MOBILE_SUPPORT:libgsm \
			+libblobmsg-json +libubox +libubus +libpthread +libtlt_uci +libboardjson
	USERID:=rms=552:rms=552
	#FATTRS:=/usr/sbin/rms_mqtt::::cap_setuid,cap_setgid=ep
endef

ifeq ($(CONFIG_GATEWAY_DEVICE), y)
	TARGET_CFLAGS += -DGATEWAY_DEVICE
endif

TARGET_CFLAGS += $(if $(CONFIG_TPM_SUPPORT),-DTPM_SUPPORT)


define Package/rms_mqtt/conffiles
/etc/config/rms_mqtt
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include $(1)/usr/lib
	$(CP) $(PKG_BUILD_DIR)/librms/librms.h $(1)/usr/include/
	$(CP) $(PKG_BUILD_DIR)/librms/librms.so $(1)/usr/lib/
endef


define Package/rms_mqtt/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/permtab.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/rms_mqtt/rms_mqtt $(1)/usr/sbin/rms_mqtt

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN_USR) $(PKG_BUILD_DIR)/files/rms_mqtt.init $(1)/etc/init.d/rms_mqtt

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF_USR) $(PKG_BUILD_DIR)/files/rms_mqtt.conf $(1)/etc/config/rms_mqtt

	$(INSTALL_DIR) $(1)/etc/rms_mqtt/
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/files/RutOS_teltonika.lt.ca $(1)/etc/rms_mqtt/RutOS@teltonika.lt.ca
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/files/RutOS_teltonika.lt.crt $(1)/etc/rms_mqtt/RutOS@teltonika.lt.crt
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/files/RutOS_teltonika.lt.key $(1)/etc/rms_mqtt/RutOS@teltonika.lt.key

	# $(INSTALL_DIR) $(1)/usr/share/acl.d
	# $(INSTALL_DATA) $(PKG_BUILD_DIR)/files/rms_mqtt.json $(1)/usr/share/acl.d/rms_mqtt.json
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/rms.permtab $(1)/etc/permtab.d/

	$(INSTALL_DIR) $(1)/etc/uci-defaults/7.18
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/migrations/7.18/01-rms_cfg_files_cleanup $(1)/etc/uci-defaults/7.18/
endef


define Package/librms/install
	$(INSTALL_DIR) $(1)/usr/lib/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/librms/librms.so $(1)/usr/lib/
endef

$(eval $(call BuildPackage,rms_mqtt))
$(eval $(call BuildPackage,librms))
