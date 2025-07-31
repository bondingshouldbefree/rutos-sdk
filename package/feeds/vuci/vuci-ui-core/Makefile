#
# Copyright (C) 2022 Teltonika-Networks
#

include $(TOPDIR)/rules.mk

PKG_NAME:=vuci-ui-core
PKG_VERSION:=2025-07-21-7efce2bb86e
PKG_RELEASE:=3
PKG_LICENSE:=Teltonika-nda-source

PKG_BUILD_PARALLEL:=1
VUCI_APPS=$(shell grep ^CONFIG_PACKAGE_vuci-app.*-ui=y $(TOPDIR)/.config | cut -d'=' -f1 | cut -d'_' -f3 | sed ':a;N;$!ba;s/\n/ /g')
VUCI_PLUGINS=$(shell grep ^CONFIG_PACKAGE_vuci-app.*-ui=m $(TOPDIR)/.config | cut -d'=' -f1 | cut -d'_' -f3 | sed ':a;N;$!ba;s/\n/ /g')

PKG_CONFIG_DEPENDS:=CONFIG_VUCI_USE_HOST_NODE CONFIG_VUCI_BUILD_DEV
MENU_OUTPUT_DIR=$(PKG_BUILD_DIR)/applications/menu.d
# used for GPL app file path modification
APP_DIR=$(1)
APP_DIR_2=$(subst -ui,,$(1))
CORE_DIR=$(PKG_BUILD_DIR)/vuci-ui-core/src
FW_APP_DIR=$(1)

include $(INCLUDE_DIR)/package.mk
include ../utils.mk

define Package/vuci-ui-core
	SECTION:=webui
	CATEGORY:=WebUI
	TITLE:=vuci ui core
	DEPENDS:=+api-core
endef

define Package/vuci-ui-core/description
	Provides core ui for VuCI
endef

define Package/vuci-ui-core/config
	source "$(SOURCE)/Config.in"
endef

define Package/vuci-ui-core/conffiles
/etc/config/widget
endef
# FIXME needs update, since .vue files remains in applications dir now.
define install_closed_gpl
	$(INSTALL_DIR) "$(GPL_BUILD_DIR)/package/feeds/vuci"
	rm -rf ~/.npm/
	mv $(PKG_BUILD_DIR)/$(FW_APP_DIR)/src/views/system/FwVerify.vue \
		$(PKG_BUILD_DIR)/$(FW_APP_DIR)/src/views/system/FwVerify_temp.vue

	mv $(PKG_BUILD_DIR)/$(FW_APP_DIR)/src/views/system/FwVerifyGPL.vue \
		$(PKG_BUILD_DIR)/$(FW_APP_DIR)/src/views/system/FwVerify.vue

	mv $(CORE_DIR)/ui-core/plugins/brand/index.js \
		$(CORE_DIR)/ui-core/plugins/brand/index_temp.js

	mv $(CORE_DIR)/ui-core/plugins/brand/index_gpl.js \
		$(CORE_DIR)/ui-core/plugins/brand/index.js

	$(CP) "$(CORE_DIR)/ui-core/plugins/brand/brand.json" \
		"$(CORE_DIR)/public/brand"

	$(CP) "$(CORE_DIR)/ui-core/plugins/brand/brand.json" \
		"$(CORE_DIR)/dist/www/brand"

	$(MAKE) -C $(PKG_BUILD_DIR) DL_DIR="$(TOPDIR)/dl/$(PKG_NAME)"

	mv $(PKG_BUILD_DIR)/$(FW_APP_DIR)/src/views/system/FwVerify.vue \
		$(PKG_BUILD_DIR)/$(FW_APP_DIR)/src/views/system/FwVerifyGPL.vue

	mv $(PKG_BUILD_DIR)/$(FW_APP_DIR)/src/views/system/FwVerify_temp.vue \
		$(PKG_BUILD_DIR)/$(FW_APP_DIR)/src/views/system/FwVerify.vue

	$(INSTALL_DIR) $(1)/vuci-ui-core/src/dist

	$(CP) "$(CORE_DIR)/dist/www" $(1)/vuci-ui-core/src/dist/

	mv $(CORE_DIR)/ui-core/plugins/brand/index.js \
		$(CORE_DIR)/ui-core/plugins/brand/index_gpl.js

	mv $(CORE_DIR)/ui-core/plugins/brand/index_temp.js \
		$(CORE_DIR)/ui-core/plugins/brand/index.js

	rm "$(CORE_DIR)/public/brand/brand.json"

	rm "$(CORE_DIR)/dist/www/brand/brand.json"

	$(CP) ../compile-app-gpl.sh "$(GPL_BUILD_DIR)/package/feeds/vuci/"
	$(CP) ../gpl.vite.config.js "$(GPL_BUILD_DIR)/package/feeds/vuci/"
	$(CP) ../gpl.package.json "$(GPL_BUILD_DIR)/package/feeds/vuci/"
endef




ifneq ($(CONFIG_VUCI_BUILD_DEV),)
	MAKE_VARS = NODE_ENV=development
endif

ifneq ($(CONFIG_VUCI_USE_HOST_NODE),)
	NODE_EXTRA_PATH =
	ifneq ($(CONFIG_VUCI_NODE_EXTRA_BIN_PATH),)
		NODE_EXTRA_PATH:=":$(CONFIG_VUCI_NODE_EXTRA_BIN_PATH)"
	endif
	NODE_PATH=$(shell PATH=/usr/bin:/usr/local/bin$(NODE_EXTRA_PATH) which node)
	NPM_PATH=$(shell PATH=/usr/bin:/usr/local/bin$(NODE_EXTRA_PATH) which npm)
	ifneq ($(NODE_PATH),)
		MAKE_VARS += NODE=$(NODE_PATH)
	endif
	ifneq ($(NPM_PATH),)
		MAKE_VARS += NPM=$(NPM_PATH)
	endif
else
	MAKE_VARS += NODE=$(STAGING_DIR_HOSTPKG)/bin/node
	MAKE_VARS += NPM=$(STAGING_DIR_HOSTPKG)/bin/npm
endif

define Package/vuci-ui-core/install
	$(INSTALL_DIR) $(1)/www
	$(INSTALL_DIR) $(1)/usr/share/vuci/menu.d
	$(CP) $(PKG_BUILD_DIR)/vuci-ui-core/src/dist/www/* $(1)/www/
	if [ ! -z "$$$$(ls ./modem-icons/$(TLT_PLATFORM_NAME)*)" ]; then \
		$(CP) ./modem-icons/$(TLT_PLATFORM_NAME)* $(1)/www/icons/modem-icons/; \
	fi
	$(CP) ../menu_static.sh $(PKG_BUILD_DIR)
	$(if $(CONFIG_GPL_BUILD), \
		$(RM) -rf $(MENU_OUTPUT_DIR); \
		mkdir -p $(MENU_OUTPUT_DIR) && \
		$(foreach app_dir,$(VUCI_APPS), \
			$(eval app_ui_dir=$(notdir $(app_dir))) \
			$(CP) -fpR ../$(app_ui_dir)/files/usr/share/vuci/menu.d/*.json "$(MENU_OUTPUT_DIR)/" 2>/dev/null || true; \
		) \
	)
	$(PKG_BUILD_DIR)/menu_static.sh $(PKG_BUILD_DIR)/menu.json $(MENU_OUTPUT_DIR)
	$(CP) $(PKG_BUILD_DIR)/menu.json $(1)/usr/share/vuci/menu.d/
	$(if $(CONFIG_VUCI_MINIFY_JSON),$(call JsonMin,$(1)/),true);

endef

define Package/vuci-ui-core/postinst
#!/bin/sh
[ -z "$${IPKG_INSTROOT}" ] && exit 0

uci batch <<-EOF
	set uhttpd.main.ubus_prefix="/ubus"
	set uhttpd.main.index_page='cgi-bin/luci'
	set uhttpd.main.error_page="/404.html"
	commit uhttpd
EOF
/etc/init.d/uhttpd restart
/etc/init.d/rpcd restart
exit 0
endef

$(eval $(call BuildPackage,vuci-ui-core))
