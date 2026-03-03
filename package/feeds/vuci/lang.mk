APP_NAME?=$(notdir ${CURDIR})
APP_SECTION?=vuci
APP_CATEGORY?=VuCI
unique_id:=$(shell echo $$RANDOM | md5sum | cut -c1-6)

PKG_NAME?=$(APP_NAME)
PKG_RELEASE?=$(VERSION)
PKG_LICENSE?=Teltonika-nda-source

include $(INCLUDE_DIR)/package.mk
include ../utils.mk

define Package/$(PKG_NAME)
	SECTION:=$(APP_SECTION)
	CATEGORY:=$(APP_CATEGORY)
	SUBMENU:=Languages
	TITLE:=$(if $(APP_TITLE),$(APP_TITLE),$(APP_NAME))
	DEPENDS:=$(APP_DEPENDS) +vuci-ui-core
	PKG_ROUTER:=$(TLT_PLATFORM_NAME)
	PKG_TLT_NAME:=$(APP_TITLE)
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	mkdir -p $(1)/www/i18n
	$(CP) ./$(LANG_LONG_NAME).json $(1)/www/i18n/$(LANGUAGE)_$(unique_id).json
	$(if $(CONFIG_VUCI_MINIFY_JSON),$(call JsonMin,$(1)/),true);
	gzip -f $(1)/www/i18n/$(LANGUAGE)_$(unique_id).json
endef

define Build/InstallGPL
	$(if $(CONFIG_GPL_INCLUDE_WEB_SOURCES), \
		$(Build/InstallGPL/Default) \
	, \
		$(CP) ./$(LANG_LONG_NAME).json $(PKG_GPL_BUILD_DIR) \
	)
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [ "$$(uci get vuci.main.set_main_language)" = '1' ]; then
	uci set vuci.main.lang="$(LANGUAGE)"
	uci delete vuci.main.set_main_language
	uci commit vuci
fi
if [ ! -L /www/i18n ]; then
    ln -s /usr/local/www/i18n /www/i18n
fi
exit 0
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
	if [ "$$(uci get vuci.main.lang)" = '$(LANGUAGE)' ]; then
		uci set vuci.main.lang='en'
		uci commit vuci
	fi
exit 0
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
