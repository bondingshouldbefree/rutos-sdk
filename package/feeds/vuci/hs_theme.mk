
PKG_NAME:=hs_theme_$(THEME_NAME)
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_LICENSE:=Teltonika-nda-source

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)/description
	Hotspot landing page $(THEME_TITLE).
endef

define Package/$(PKG_NAME)
	PKG_TLT_NAME:=Hotspot landing page $(shell echo $(THEME_NAME) | tr '_' ' ') theme
	PKG_ROUTER:=$(TLT_PLATFORM_NAME)
	SECTION:=webui
	CATEGORY:=WebUI
	SUBMENU:=Landing page themes
	TITLE:=$(THEME_TITLE)
	DEPENDS:=+vuci-app-landingpage
	APP_HW_INFO:=ethernet/wifi
endef

define Package/$(PKG_NAME)/prerm
	#!/bin/sh
	if [ "$$(uci -q get landingpage.general.theme)" = '$(THEME_NAME)' ]; then
		echo "ret: Theme already in use"
		exit 1
	fi
	# Delete directory on delete as makefile deletes only files not directories
	rm -rf /etc/chilli/hotspotlogin/themes/$(THEME_NAME)
	
	exit 0
endef

define Build/Compile
endef

define Build/InstallGPL
	$(if $(CONFIG_GPL_INCLUDE_WEB_SOURCES), \
		$(Build/InstallGPL/Default) \
	, \
		$(INSTALL_DIR) $(PKG_GPL_BUILD_DIR)/files; \
		$(CP) ./files/* $(PKG_GPL_BUILD_DIR)/files; \
	)
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/chilli/hotspotlogin
	$(CP) files/etc/chilli/hotspotlogin/* $(1)/etc/chilli/hotspotlogin/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
