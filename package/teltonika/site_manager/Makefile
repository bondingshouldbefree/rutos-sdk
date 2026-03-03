include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=site_manager

PKG_SOURCE_VERSION:=7.21-1

PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/siteman
	SECTION:=base
	CATEGORY:=Base system
	TITLE:=Teltonika Site Manager
	DEPENDS:=+libuci +libubus +libblobmsg-json +libtlt-logger +libubox \
			+libuuid +libmnfinfo +libtdp +libcfg +libmosquitto-ssl +mosquitto-ssl
	USERID:=siteman=654:siteman=654
	PROVIDES:=site_manager
	FATTRS:=/usr/bin/siteman::::cap_net_bind_service=ep
endef

define Package/siteman/conffiles
/etc/config/siteman
/etc/config/siteman_devices
/etc/config/siteman_groups
endef

define Package/siteman/config
	source "$(SOURCE)/Config_siteman.in"
endef

define Package/siteman_client
	SECTION:=base
	CATEGORY:=Base system
	TITLE:=Teltonika Site Manager client service
	DEPENDS:=+libuci +libcfg +libubox +libtlt-logger +libtdp \
			+libmnfinfo +libubus +libblobmsg-json +libuuid +libmosquitto-ssl \
			+SITEMANC_DISCOVERY_CUSTOM:libcurl
	USERID:=sitemanc=655:sitemanc=655
	PROVIDES:=sitemanc
	FATTRS:=/usr/bin/sitemanc::::cap_net_bind_service,cap_sys_time=ep
endef

define Package/siteman_client/conffiles
/etc/config/sitemanc
endef

define Package/siteman_client/config
	source "$(SOURCE)/Config.in"
endef

TARGET_CFLAGS += \
	$(if $(CONFIG_SITEMANC_DISCOVERY_CUSTOM),-DSITEMANC_DISCOVERY_CUSTOM) \
	$(if $(CONFIG_SITEMANC_DISCOVERY_STATIC),-DSITEMANC_DISCOVERY_STATIC) \
	$(if $(CONFIG_SITEMANC_DISCOVERY_DHCP),-DSITEMANC_DISCOVERY_DHCP) \
	$(if $(CONFIG_SITEMANC_DISCOVERY_DNS),-DSITEMANC_DISCOVERY_DNS) \
	$(if $(CONFIG_SITEMANC_DISCOVERY_RADIUS),-DSITEMANC_DISCOVERY_RADIUS) \
	$(if $(CONFIG_SITEMANC_DISCOVERY_TLT),-DSITEMANC_DISCOVERY_TLT) \
	$(if $(CONFIG_SITEMANC_DEBUG),-DSITEMANC_DEBUG) \
	$(if $(CONFIG_SITEMAN_DEBUG),-DSITEMAN_DEBUG) \
	$(if $(CONFIG_SITEMAN_MAX_CLIENTS),-DDM_DEV_MAX_COUNT=$(CONFIG_SITEMAN_MAX_CLIENTS)) \
	$(if $(CONFIG_SITEMAN_DEFAULT_API_VERSION),-DDM_DEFAULT_API_VERSION=$(CONFIG_SITEMAN_DEFAULT_API_VERSION)) \
	-DLTDP_DEBUG

define Package/libtdp
	SECTION:=libs
	CATEGORY:=Libraries
	TITLE:=TDP (Teltonika Device Discovery) protocol library
	PROVIDES:=libtdp
endef



define Package/siteman/install
	$(INSTALL_DIR) $(1)/usr/bin $(1)/etc/init.d $(1)/etc/config \
		$(1)/lib/troubleshoot/ $(1)/etc/siteman $(1)/etc/siteman/certs \
		$(1)/usr/share/acl.d $(1)/lib/upgrade/keep.d $(1)/etc/uci-defaults $(1)/etc/permtab.d

	$(INSTALL_DATA) $(PKG_BUILD_DIR)/siteman/files/siteman.cfg $(1)/etc/config/siteman
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/siteman/files/config/* $(1)/etc/config/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/siteman/files/99-siteman.sh $(1)/etc/uci-defaults/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/siteman/siteman $(1)/usr/bin/siteman
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/siteman/files/siteman.init $(1)/etc/init.d/siteman
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/siteman/files/siteman_troubleshoot.sh $(1)/lib/troubleshoot/siteman.sh
	install -m0400 $(PKG_BUILD_DIR)/siteman/files/siteman/* $(1)/etc/siteman/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/siteman/files/cert_gen.sh $(1)/etc/siteman/cert_gen.sh
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/siteman/files/siteman_acl.json $(1)/usr/share/acl.d/siteman.json
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/siteman/files/siteman.upgrade $(1)/lib/upgrade/keep.d/siteman
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/siteman/files/siteman.permtab $(1)/etc/permtab.d/siteman
endef

define Package/siteman_client/install
	$(INSTALL_DIR) $(1)/usr/bin $(1)/etc/init.d $(1)/etc/config \
		$(1)/lib/troubleshoot/ $(1)/etc/sitemanc $(1)/etc/sitemanc/certs \
		$(1)/lib/upgrade/keep.d $(1)/etc/permtab.d $(1)/usr/share/acl.d

	$(INSTALL_BIN) $(PKG_BUILD_DIR)/siteman_client/files/sitemanc.init $(1)/etc/init.d/sitemanc
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/siteman_client/sitemanc $(1)/usr/bin/sitemanc
	$(if $(CONFIG_AP_DEVICE),
		$(INSTALL_DATA) $(PKG_BUILD_DIR)/siteman_client/files/sitemanc.cfg $(1)/etc/config/sitemanc,
		$(INSTALL_DATA) $(PKG_BUILD_DIR)/siteman_client/files/sitemanc_rut.cfg $(1)/etc/config/sitemanc)

	$(INSTALL_DATA) $(PKG_BUILD_DIR)/siteman_client/files/sitemanc/* $(1)/etc/sitemanc/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/siteman_client/files/dhcp.sh $(1)/etc/sitemanc/dhcp.sh
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/siteman_client/files/sitemanc_troubleshoot.sh $(1)/lib/troubleshoot/sitemanc.sh
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/siteman_client/files/sitemanc_acl.json $(1)/usr/share/acl.d/sitemanc.json
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/siteman_client/files/sitemanc.upgrade $(1)/lib/upgrade/keep.d/sitemanc
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/siteman_client/files/sitemanc.permtab $(1)/etc/permtab.d/sitemanc
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/lib $(1)/usr/include/
	$(CP) $(PKG_BUILD_DIR)/libtdp/libtdp.so $(1)/usr/lib/
	$(CP) $(PKG_BUILD_DIR)/libtdp/include/libtdp.h $(1)/usr/include/
endef

define Package/libtdp/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/libtdp/libtdp.so $(1)/usr/lib/
endef

$(eval $(call BuildPackage,libtdp))
$(eval $(call BuildPackage,siteman))
$(eval $(call BuildPackage,siteman_client))

