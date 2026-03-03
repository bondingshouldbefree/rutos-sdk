include $(TOPDIR)/rules.mk

THEME_NAME=default
PKG_NAME:=hs_theme_$(THEME_NAME)
PKG_VERSION:=2022-07-27
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_LICENSE:=Teltonika-nda-source

include $(INCLUDE_DIR)/package.mk


define Package/tlt_hs_theme_$(THEME_NAME)
	SECTION:=webui
	CATEGORY:=WebUI
	SUBMENU:=Landing page themes
	TITLE:=Default theme
	DEPENDS:=+vuci-app-landingpage
endef

define Package/tlt_hs_theme_$(THEME_NAME)/description
	Hotspot landing page default theme.
endef

define Package/tlt_hs_theme_$(THEME_NAME)/prerm
	#!/bin/sh

	[[ -d "/etc/chilli/hotspotlogin/backup" ]] && rm -rf /etc/chilli/hotspotlogin/backup/
	exit 0
endef

define Package/tlt_hs_theme_$(THEME_NAME)/postinst
	#!/bin/sh

	[[ -d "/rom/etc/chilli/hotspotlogin" ]] || {
		mkdir -p /etc/chilli/hotspotlogin/backup/themes/default /etc/chilli/hotspotlogin/backup/cgi-bin/themes/default
		cp -rf /etc/chilli/hotspotlogin/themes/default/style /etc/chilli/hotspotlogin/backup/themes/default/
		cp -rf /etc/chilli/hotspotlogin/cgi-bin/themes/default /etc/chilli/hotspotlogin/backup/cgi-bin/themes/
		chown -R chilli:chilli /etc/chilli/hotspotlogin/backup/themes/default
		chown -R chilli:chilli /etc/chilli/hotspotlogin/backup/cgi-bin/themes/default
		chmod 0774 /etc/chilli/hotspotlogin/backup/themes/default
		chmod 0774 /etc/chilli/hotspotlogin/backup/cgi-bin/themes/default
	}

	exit 0
endef



define Package/tlt_hs_theme_$(THEME_NAME)/install
	$(INSTALL_DIR) $(1)/etc/chilli/hotspotlogin
	$(CP) files/etc/chilli/hotspotlogin/* $(1)/etc/chilli/hotspotlogin/

	$(INSTALL_DIR) $(1)/etc/permtab.d
	echo "/etc/chilli/hotspotlogin/themes/$(THEME_NAME)             chilli:chilli      664      r" > $(1)/etc/permtab.d/hs_theme_$(THEME_NAME)
	echo "/etc/chilli/hotspotlogin/cgi-bin/themes/$(THEME_NAME)	 chilli:chilli      664      r" >> $(1)/etc/permtab.d/hs_theme_$(THEME_NAME)
	echo "/etc/chilli/hotspotlogin/themes/$(THEME_NAME)             chilli:chilli      774      -" >> $(1)/etc/permtab.d/hs_theme_$(THEME_NAME)
	echo "/etc/chilli/hotspotlogin/themes/$(THEME_NAME)/fonts       chilli:chilli      774      -" >> $(1)/etc/permtab.d/hs_theme_$(THEME_NAME)
	echo "/etc/chilli/hotspotlogin/themes/$(THEME_NAME)/img         chilli:chilli      774      -" >> $(1)/etc/permtab.d/hs_theme_$(THEME_NAME)
	echo "/etc/chilli/hotspotlogin/themes/$(THEME_NAME)/style       chilli:chilli      774	  -" >> $(1)/etc/permtab.d/hs_theme_$(THEME_NAME)
	echo "/etc/chilli/hotspotlogin/cgi-bin/themes/$(THEME_NAME)     chilli:chilli      774      -" >> $(1)/etc/permtab.d/hs_theme_$(THEME_NAME)
	echo "" >> $(1)/etc/permtab.d/hs_theme_$(THEME_NAME)
endef

$(eval $(call BuildPackage,tlt_hs_theme_$(THEME_NAME)))
