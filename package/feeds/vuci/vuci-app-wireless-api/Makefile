include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI API Support for Wireless
APP_DEPENDS:=+libiwinfo-lua

CUSTOM_INSTALL=1
include ../api.mk

define Package/$(PKG_NAME)/install
	$(call Package/$(PKG_NAME)/install/Default,$(1))
	files_dir="./files"; if [[ -d "$(PKG_BUILD_DIR)/files" ]]; then files_dir="$(PKG_BUILD_DIR)/files"; fi; \
	$(INSTALL_BIN) "$$$$files_dir"/usr/lib/lua/api/network/supplicant_control.lua $(1)/usr/lib/lua/api/network/supplicant_control.lua
endef

# call BuildPackage - OpenWrt buildroot signature
$(eval $(call BuildPackage,$(PKG_NAME)))
