include $(TOPDIR)/rules.mk
 
PKG_NAME:=vuci-app-landingpage
PKG_VERSION:=2021-02-19
PKG_RELEASE:=1
# there's a few files with custom licenses in here, but most of them are Apache v2.
PKG_LICENSE:=Apache-2.0
 
include $(INCLUDE_DIR)/package.mk
 
define Package/vuci-app-landingpage
	SECTION:=webui
	CATEGORY:=WebUI
	SUBMENU:=Applications
	TITLE:=Hotspot landingpage core files
	DEPENDS:=+liblua +vuci-app-coovachilli-themes-ui
endef

define Package/vuci-app-landingpage/conffiles
/etc/config/landingpage
endef
 
define Package/vuci-app-landingpage/install
	$(CP) ./files/* $(1)
	$(INSTALL_BIN) ./files/etc/chilli/hotspotlogin/cgi-bin/hotspot $(1)/etc/chilli/hotspotlogin/cgi-bin/hotspot
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/template
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/parser.so $(1)/usr/lib/lua/luci/template/parser.so
endef

define Package/vuci-app-landingpage/postinst
#!/bin/sh

[ -z "$${IPKG_INSTROOT}" ] && {
	http_dis=$$(uci -q get uhttpd.hotspot.disabled)
	#We need to start http instance if HS service was enabled before
	[ "$$http_dis" = "1" ] || /etc/init.d/uhttpd reload
}

exit 0
endef

define Package/vuci-app-landingpage/postrm
#!/bin/sh

[ -z "$${IPKG_INSTROOT}" ] && {
	http_dis=$$(uci -q get uhttpd.hotspot.disabled)
	[ "$$http_dis" = "0" ] && {
		uci -q set uhttpd.hotspot.disabled=1
		uci -q commit uhttpd
		
		/etc/init.d/uhttpd reload
	}
}

exit 0
endef

define Build/Compile
	# clean files leftover from Host/Compile
	if [ -e $(PKG_BUILD_DIR)/plural_formula.o ] ; then rm $(PKG_BUILD_DIR)/plural_formula.o ; fi
	if [ -e $(PKG_BUILD_DIR)/template_lmo.o ] ; then rm $(PKG_BUILD_DIR)/template_lmo.o ; fi
	$(call Build/Compile/Default)
endef

include $(INCLUDE_DIR)/host-build.mk

define Host/Configure
endef

define Host/Compile
	$(MAKE) -C src/ clean po2lmo jsmin
endef

define Host/Install
	$(INSTALL_DIR) $(1)/bin
	$(INSTALL_DIR) $(1)/lib/lua/5.1
	$(INSTALL_BIN) src/po2lmo $(1)/bin/po2lmo
	$(INSTALL_BIN) src/jsmin $(1)/bin/jsmin
endef

$(eval $(call HostBuild))
$(eval $(call BuildPackage,vuci-app-landingpage))
