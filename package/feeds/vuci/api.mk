APP_NAME?=$(notdir ${CURDIR})
APP_SECTION?=vuci
APP_CATEGORY?=VuCI

PKG_NAME?=$(APP_NAME)
PKG_RELEASE?=1
PKG_LICENSE?=Teltonika-nda-source
PKG_BUILD_DEPENDS:=VUCI_MINIFY_LUA:luasrcdiet/host

include $(INCLUDE_DIR)/package.mk
include ../utils.mk


define Package/$(PKG_NAME)
	SECTION:=$(APP_SECTION)
	CATEGORY:=$(APP_CATEGORY)
	SUBMENU:=Applications/API
	TITLE:=$(if $(APP_TITLE),$(APP_TITLE),$(APP_NAME))
	DEPENDS:=$(APP_DEPENDS) +api-core
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
ifdef APP_USERID
	USERID:=$(APP_USERID)
endif
endef

define Package/$(PKG_NAME)/post/Default
#!/bin/sh
[ -z "$${IPKG_INSTROOT}" ] || exit 0
ubus call session reload_acls
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

define Build/Prepare
	$(INSTALL_DIR) $(PKG_BUILD_DIR)
	if [[ -d ./files ]] && [[ "$$$$(ls -A ./files)" ]]; then $(CP) -R ./files $(PKG_BUILD_DIR)/files; fi
	# only called if pkg has .c files in ./src dir to copy
	if [[ -d ./src ]] && [[ "$$$$(ls -A ./src)" ]]; then $(CP) ./src/* $(PKG_BUILD_DIR)/; fi
endef

define Build/Compile
	$(if $(CONFIG_VUCI_MINIFY_LUA),$(call MinifyLua,$(PKG_BUILD_DIR)/files),true);
	$(if $(CONFIG_VUCI_COMPILE_LUA),$(call CompileLua,$(PKG_BUILD_DIR)/files),true);
	$(if $(CONFIG_VUCI_MINIFY_JSON),$(call JsonMin,$(PKG_BUILD_DIR)/files),true);
	# only called if pkg has .c files in ./src dir (or ./bin for GPL build) to compile
	if [[ -d ./src && "$$$$(ls -A ./src)" ]] || [[ -d ./bin && "$$$$(ls -A ./bin)" ]]; then ( $(call Build/Compile/Default) ); fi
endef

define Build/Configure
endef

define Package/$(PKG_NAME)/install/Default
	files_dir="./files"; if [[ -d "$(PKG_BUILD_DIR)/files" ]]; then files_dir="$(PKG_BUILD_DIR)/files"; fi; \
	if [[ -d "$$$$files_dir" ]]; then \
		$(CP) "$$$$files_dir"/* $(1)/; \
		$(if $(CONFIG_AP_DEVICE), , $(RM) $(1)/usr/share/rpcd/acl.d/*.tap.json;) \
		$(if $(CONFIG_SWITCH_DEVICE), , $(RM) $(1)/usr/share/rpcd/acl.d/*.tsw.json;) \
		if [ -n "$(CONFIG_SWITCH_DEVICE)" ] || [ -n "$(CONFIG_AP_DEVICE)" ]; then \
			if [ ! -z "$$$$(ls $(1)/usr/share/rpcd/acl.d/*.tap.json)" ] || [ ! -z "$$$$(ls $(1)/usr/share/rpcd/acl.d/*.tsw.json)" ]; then \
				find $(1)/usr/share/rpcd/acl.d/ -type f -not \( -name '*.tap.json' -or -name '*.tsw.json' \) -exec $(RM) {} +; \
			fi; \
		fi; \
	fi
endef

define install_closed_gpl
	$(INSTALL_DIR) $(PKG_GPL_BUILD_DIR)/files
	$(CP) $(PKG_BUILD_DIR)/files/* $(PKG_GPL_BUILD_DIR)/files
endef

define Build/InstallGPL
	$(if $(CONFIG_GPL_INCLUDE_WEB_SOURCES), \
		$(Build/InstallGPL/Default),$(install_closed_gpl))
endef

ifndef Package/$(PKG_NAME)/install
define Package/$(PKG_NAME)/install
$(call Package/$(PKG_NAME)/install/Default,$(1))
endef
endif

ifneq ($(CUSTOM_INSTALL),1)
$(eval $(call BuildPackage,$(PKG_NAME)))
endif
