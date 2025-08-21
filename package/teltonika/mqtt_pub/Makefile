include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=mqtt_pub
PKG_VERSION:=2025-07-31

PKG_SOURCE_VERSION:=2.15
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_SOURCE_VERSION)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_SOURCE_SUBDIR).tar.gz

PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/mqtt_pub
	SECTION:=net
	CATEGORY:=Network
	TITLE:=MQTT client for device monitoring
	DEPENDS:=+libuci +libtlt_uci +libmosquitto-ssl +libubus +libjson-c \
		+libubox +libblobmsg-json +mosquitto-ssl \
		+IO_SUPPORT:iomand +MOBILE_SUPPORT:libgsm +libmnfinfo
	USERID:=mqtt_pub=512:mqtt_pub=512
endef

define Package/mqtt_pub/description
	MQTT protocol services' bundle. With this package it is
	possible to set up MQTT Broker and MQTT Bridge for data transferring
	and custom Teltonika MQTT Client for data retrieval.
endef

define Package/mqtt_pub/conffiles
/etc/config/mqtt_pub
endef


define Package/mqtt_pub/install
	$(INSTALL_DIR) $(1)/etc/config $(1)/usr/share/acl.d
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/permtab.d
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_CONF_USR) $(PKG_BUILD_DIR)/files/mqtt_pub.conf $(1)/etc/config/mqtt_pub
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/mqtt_pub.init $(1)/etc/init.d/mqtt_pub
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/mqtt_pub.json $(1)/usr/share/acl.d/mqtt_pub.json
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/mqtt_pub $(1)/usr/sbin/mqtt_pub
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/mqtt_pub.permtab $(1)/etc/permtab.d/mqtt_pub
endef

$(eval $(call BuildPackage,mqtt_pub))
