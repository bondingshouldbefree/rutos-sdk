#
# Copyright (C) 2021 Teltonika
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=cmStreamApp
PKG_VERSION:=2026-02-11
PKG_RELEASE:=1

PKG_SOURCE_VERSION:=2.10
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_SOURCE_VERSION)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_SOURCE_SUBDIR).tar.gz

PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/cmStreamApp
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Cumulocity - Cloud of Things stream application.
	DEPENDS:=+libmosquitto +libtlt-logger +libtlt_uci +libuci \
		 +libmnfinfo +libubus +libubox +libcurl +MOBILE_SUPPORT:libgsm +liblua
	USERID:=iot=503:iot=503
endef

define Package/cmStreamApp/description
	Cumulocity - Cloud of Things IoT application meant
	for interaction with cloud-based Cumulocity IoT platform and
	Telekom Cloud of Things.
endef

define Package/cmStreamApp/conffiles
/etc/config/iot
endef


define Package/cmStreamApp/install
	$(INSTALL_DIR) $(1)/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/cmStreamApp $(1)/bin/cmStreamApp
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN_USR) $(PKG_BUILD_DIR)/files/iot.init $(1)/etc/init.d/iot
	$(INSTALL_DIR) $(1)/lib/lua/cm
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/srtemplate $(1)/lib/lua/cm/srtemplate.txt
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/iot $(1)/etc/config/iot
	$(INSTALL_DIR) $(1)/usr/share/acl.d $(1)/etc/permtab.d
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/iot.json $(1)/usr/share/acl.d/iot.json
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/iot.permtab $(1)/etc/permtab.d/iot

	if [ ! $(CONFIG_HNAT) ]; then \
		$(SED) "s#Teltonika-Networks_RUTX#Teltonika-Networks_$(call device_shortname)#g" $(1)/lib/lua/cm/srtemplate.txt; \
	fi;
endef

$(eval $(call BuildPackage,cmStreamApp))
