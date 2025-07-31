#
# Copyright (C) 2021 Teltonika
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=rut_fota

PKG_SOURCE_VERSION:=2.19.2

PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/librut_fota
	SECTION:=base
	CATEGORY:=Base system
	TITLE:=Library for handling rut_fota information
	DEPENDS:=+libubus +libubox +libblobmsg-json +libjson-c
endef

define Package/rut_fota
	SECTION:=base
	CATEGORY:=Base system
	TITLE:=Firmware Over The Air Utility
	DEPENDS:=+libuci +libmnfinfo +MOBILE_SUPPORT:libgsm +libubus +libubox +libopenssl +libblobmsg-json +libjson-c +librut_fota +liblog
	USERID:=rut_fota:rut_fota
	FATTRS:=/sbin/rut_fota:rut_fota::y:
endef

define Package/rut_fota/conffiles
/etc/config/rut_fota
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/lib $(1)/usr/include/
	$(CP) $(PKG_BUILD_DIR)/librut_fota.so $(1)/usr/lib/
	$(CP) $(PKG_BUILD_DIR)/src/lib/librut_fota.h $(1)/usr/include/
endef


define Package/librut_fota/install
	$(INSTALL_DIR) $(1)/usr/lib/ $(1)/usr/lib/rpcd/shared
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/fota.so $(1)/usr/lib/rpcd/shared
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/librut_fota.so $(1)/usr/lib/
endef

FOTA_HOST:=$(shell echo $(TLT_VERSION) | grep -Pq '[^_]+_R_\d' || echo 'demo')rut.teltonika.lt

define Package/rut_fota/install
	$(INSTALL_DIR) $(1)/etc/init.d/ $(1)/etc/config/ $(1)/sbin/ $(1)/usr/share/acl.d/ $(1)/etc/permtab.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/rut_fota $(1)/sbin/rut_fota
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/rut_fota.init $(1)/etc/init.d/rut_fota

	$(INSTALL_CONF_USR) $(PKG_BUILD_DIR)/files/rut_fota.config $(1)/etc/config/rut_fota
	$(SED) "s#%%FOTA_HOST%%#"$(FOTA_HOST)"#g" $(1)/etc/config/rut_fota

	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/TN_RUT_FOTA_CA.pem $(1)/etc/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/rut_fota.json $(1)/usr/share/acl.d/rut_fota.json

	if [ $(TLT_PLATFORM_TRB16) ]; then \
		$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/rut_fota_trb16.permtab $(1)/etc/permtab.d/rut_fota; \
	else \
		$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/rut_fota.permtab $(1)/etc/permtab.d/rut_fota; \
	fi;
endef

$(eval $(call BuildPackage,librut_fota))
$(eval $(call BuildPackage,rut_fota))
