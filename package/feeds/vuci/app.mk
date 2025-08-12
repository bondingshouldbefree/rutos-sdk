APP_NAME?=$(notdir ${CURDIR})
APP_SECTION?=vuci
APP_CATEGORY?=VuCI
VUCI_CORE_VERSION:=$(shell git --git-dir=$(CURDIR)/../../../.git log -1 --pretty="%ci %h" | awk '{ print $$1 "-" $$4 }')
VUCI_CORE_DIR=$(BUILD_DIR)/vuci-ui-core-$(VUCI_CORE_VERSION)
VUCI_APPS=$(shell grep ^CONFIG_PACKAGE_vuci-app.*-ui=y $(TOPDIR)/.config | cut -d'=' -f1 | cut -d'_' -f3 | sed ':a;N;$!ba;s/\n/ /g')
VUCI_JSONS=$(notdir $(wildcard $(VUCI_CORE_DIR)/applications/menu.d/*.json))
APP_NAME_ONLY=$(patsubst %-ui,%,$(APP_NAME))
PKG_NAME?=$(APP_NAME)
PKG_RELEASE?=1
PLUGIN_DIR:=$(VUCI_CORE_DIR)/.plugin
PKG_VERSION?=$(VUCI_CORE_VERSION)
PKG_LICENSE?=Teltonika-nda-source

include $(INCLUDE_DIR)/package.mk
include ../utils.mk

define Package/$(PKG_NAME)
	SECTION:=$(APP_SECTION)
	CATEGORY:=$(APP_CATEGORY)
	SUBMENU:=Applications/UI
	TITLE:=$(if $(APP_TITLE),$(APP_TITLE),$(APP_NAME))
ifndef NO_API_DEPEND
	DEPENDS:=$(APP_DEPENDS) +vuci-ui-core +$(patsubst %-ui,%,$(APP_NAME))-api
else
	DEPENDS:=$(APP_DEPENDS) +vuci-ui-core 
endif
ifdef APP_TLT_NAME
	PKG_TLT_NAME:=$(APP_TLT_NAME)
endif
ifdef APP_ROUTER
	PKG_ROUTER:=$(APP_ROUTER)
endif
ifdef APP_APP_NAME
	PKG_APP_NAME:=$(APP_APP_NAME)
endif
ifdef APP_HW_INFO
	PKG_HW_INFO:=$(APP_HW_INFO)
endif
endef


packed_src :=
ifneq ($(CONFIG_GPL_BUILD), y)
	packed_src = 1
endif
ifeq ($(CONFIG_GPL_BUILD), y)
ifeq ($(CONFIG_GPL_INCLUDE_WEB_SOURCES), y)
	packed_src = 1
endif
endif

define Package/$(PKG_NAME)/post/Default
#!/bin/sh
[ -z "$${IPKG_INSTROOT}" ] || exit 0
ubus send vuci.notify '{"event": "reload_routes"}'
exit 0
endef

ifndef Package/$(PKG_NAME)/postinst
define Package/$(PKG_NAME)/postinst
$(call Package/$(PKG_NAME)/post/Default,$(1))
endef
endif

ifndef Package/$(PKG_NAME)/postrm
define Package/$(PKG_NAME)/postrm
$(call Package/$(PKG_NAME)/post/Default,$(1))
endef
endif

ifndef CLOSED_GPL_INSTALL
define Build/Compile
	if [[ -d ./files ]]; then $(CP) ./files/ $(PKG_BUILD_DIR)/ ; fi
	$(if $(packed_src), \
		$(if $(findstring m,$(CONFIG_PACKAGE_$(PKG_NAME))), \
			$(INSTALL_DIR) $(PLUGIN_DIR)/$(PKG_NAME); \
			$(CP) $(PKG_BUILD_DIR)/* $(PLUGIN_DIR)/$(PKG_NAME); \
			$(if $(wildcard $(VUCI_CORE_DIR)/vuci-ui-core/src/dist/applications/$(APP_NAME_ONLY)), \
				$(CP) $(VUCI_CORE_DIR)/vuci-ui-core/src/dist/applications/$(APP_NAME_ONLY) $(PKG_BUILD_DIR)/dest; \
			) \
		) \
	, \
		$(Build/Compile/Default) \
	)
endef

define Build/Prepare
	$(if $(packed_src), \
		$(INSTALL_DIR) $(PKG_BUILD_DIR) $(PKG_BUILD_DIR)/src; \
		if [[ -d ./src ]] && [[ ! `ls -1 ./src | wc -l` = 0 ]]; then $(CP) ./src/* $(PKG_BUILD_DIR)/src; fi \
	)
endef

define Package/$(PKG_NAME)/install/Default
	if [[ -d $(PKG_BUILD_DIR)/files ]] && [[ "$$$$(ls -A $(PKG_BUILD_DIR)/files)" ]]; then \
		$(if $(CONFIG_AP_DEVICE), , $(RM) $(PKG_BUILD_DIR)/files/usr/share/vuci/menu.d/*.tap.json;) \
		$(if $(CONFIG_SWITCH_DEVICE), , $(RM) $(PKG_BUILD_DIR)/files/usr/share/vuci/menu.d/*.tsw.json;) \
		if [ -n "$(CONFIG_SWITCH_DEVICE)" ] || [ -n "$(CONFIG_AP_DEVICE)" ]; then \
			if [ ! -z "$$$$(ls $(PKG_BUILD_DIR)/files/usr/share/vuci/menu.d/*.tap.json)" ] || [ ! -z "$$$$(ls $(PKG_BUILD_DIR)/files/usr/share/vuci/menu.d/*.tsw.json)" ]; then \
				find $(PKG_BUILD_DIR)/files/usr/share/vuci/menu.d/ -type f -not \( -name '*.tap.json' -or -name '*.tsw.json' \) -exec $(RM) {} +; \
			fi; \
		fi; \
		$(if $(CONFIG_GPL_BUILD), \
			$(if $(filter $(PKG_NAME), $(VUCI_APPS)), \
				$(RM) -r $(PKG_BUILD_DIR)/files/usr/share/vuci/menu.d/; \
			) \
		) \
		$(CP) $(PKG_BUILD_DIR)/files/* $(1); \
		$(if $(VUCI_JSONS), \
			find $(1)/usr/share/vuci/menu.d/ -type f -name '*.json' -exec sh -c 'for file; do if echo $(VUCI_JSONS) | grep -w $$$$(basename "$$$$file"); then rm -f "$$$$file"; fi; done' sh {} +; \
		) \
	fi; \
	if [[ -d "$(PKG_BUILD_DIR)/dest" ]] && [[ "$$$$(ls -A $(PKG_BUILD_DIR)/dest -I .gitignore)" ]]; then \
		$(INSTALL_DIR) $(1)/www/assets; \
		$(CP) $(PKG_BUILD_DIR)/dest/* $(1)/www/assets; \
	fi
	$(if $(CONFIG_VUCI_MINIFY_JSON),$(call JsonMin,$(1)/),true);
endef
else
define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR)/src CC="$(HOSTCC)" CXX="$(HOSTCXX)"
	$(RM) -rf $(PKG_BUILD_DIR)/src
endef

define Build/Prepare
	$(INSTALL_DIR) $(PKG_BUILD_DIR) $(PKG_BUILD_DIR)/src; \
	if [[ -d ./src ]] && [[ ! `ls -1 ./src | wc -l` = 0 ]]; then \
		$(CP) ./src/* $(PKG_BUILD_DIR)/src; \
		$(CP) ../compile-app-gpl.sh $(PKG_BUILD_DIR)/src; \
		$(CP) ../gpl.vite.config.js $(PKG_BUILD_DIR)/src; \
		$(CP) ../gpl.package.json $(PKG_BUILD_DIR)/src/package.json; \
	fi
	if [[ -d ./files ]]; then $(CP) ./files/ $(PKG_BUILD_DIR)/ ; fi
endef

define Package/$(PKG_NAME)/install/Default
	if [[ -d $(PKG_BUILD_DIR)/files ]] && [[ "$$$$(ls -A $(PKG_BUILD_DIR)/files)" ]]; then \
		$(if $(CONFIG_AP_DEVICE), , $(RM) $(PKG_BUILD_DIR)/files/usr/share/vuci/menu.d/*.tap.json;) \
		$(if $(CONFIG_SWITCH_DEVICE), , $(RM) $(PKG_BUILD_DIR)/files/usr/share/vuci/menu.d/*.tsw.json;) \
		if [ -n "$(CONFIG_SWITCH_DEVICE)" ] || [ -n "$(CONFIG_AP_DEVICE)" ]; then \
			if [ ! -z "$$$$(ls $(PKG_BUILD_DIR)/files/usr/share/vuci/menu.d/*.tap.json)" ] || [ ! -z "$$$$(ls $(PKG_BUILD_DIR)/files/usr/share/vuci/menu.d/*.tsw.json)" ]; then \
				find $(PKG_BUILD_DIR)/files/usr/share/vuci/menu.d/ -type f -not \( -name '*.tap.json' -or -name '*.tsw.json' \) -exec $(RM) {} +; \
			fi; \
		fi; \
		$(CP) $(PKG_BUILD_DIR)/files/* $(1); \
		$(if $(VUCI_JSONS), \
			find $(1)/usr/share/vuci/menu.d/ -type f -name '*.json' -exec sh -c 'for file; do if echo $(VUCI_JSONS) | grep -w $$$$(basename "$$$$file"); then rm -f "$$$$file"; fi; done' sh {} +; \
		) \
	fi; \
	if [[ -d "$(PKG_BUILD_DIR)/dest" ]] && [[ "$$$$(ls -A $(PKG_BUILD_DIR)/dest -I .gitignore)" ]]; then \
		$(INSTALL_DIR) $(1)/www/views; \
		$(CP) $(PKG_BUILD_DIR)/dest/* $(1)/www/views; \
	fi
	$(if $(CONFIG_VUCI_MINIFY_JSON),$(call JsonMin,$(1)/),true);
endef
endif

define Build/InstallGPL
	if [ ! -f "$(VUCI_CORE_DIR)/gpl_install" ]; then \
		$(MAKE) -C $(TOPDIR) package/vuci-ui-core/gpl-install V=s; \
	fi; \
	$(if $(CONFIG_GPL_INCLUDE_WEB_SOURCES), \
		$(Build/InstallGPL/Default); \
		mkdir -p $(GPL_BUILD_DIR)/package/feeds/vuci/applications; \
		cd  $(GPL_BUILD_DIR)/package/feeds/vuci/applications && ln -s ../$(PKG_NAME) $(PKG_NAME); , \
		$(INSTALL_DIR) $(PKG_GPL_BUILD_DIR)/files; \
		if [[ -d $(PKG_BUILD_DIR)/files ]] && [[ "$$(ls -A $(PKG_BUILD_DIR)/files)" ]]; then \
			$(CP) $(PKG_BUILD_DIR)/files/* $(PKG_GPL_BUILD_DIR)/files ;\
		fi ; \
		$(if $(findstring m,$(CONFIG_PACKAGE_$(PKG_NAME))), \
			$(INSTALL_DIR) $(1)/dest; \
			$(CP) $(VUCI_CORE_DIR)/vuci-ui-core/src/dist/applications/$(APP_NAME_ONLY)/* $(1)/dest || \
				$(CP) $(PKG_BUILD_DIR)/dest/* $(1)/dest || true; \
		) \
	)
endef

ifndef Package/$(PKG_NAME)/install
define Package/$(PKG_NAME)/install
$(call Package/$(PKG_NAME)/install/Default,$(1))
endef
endif

ifneq ($(CUSTOM_INSTALL),1)
$(eval $(call BuildPackage,$(PKG_NAME)))
endif
