include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI API Support for Mobile Utilities

CUSTOM_INSTALL=1

include ../api.mk

define Package/$(PKG_NAME)/install
	$(call Package/$(PKG_NAME)/install/Default,$(1))
	files_dir="./files"; if [[ -d "$(PKG_BUILD_DIR)/files" ]]; then files_dir="$(PKG_BUILD_DIR)/files"; fi; \
	$(INSTALL_CONF) $$$$files_dir/etc/hotplug.d/gsm/1-new_modem $(1)/etc/hotplug.d/gsm/1-new_modem; 
endef

# call BuildPackage - OpenWrt buildroot signature
$(eval $(call BuildPackage,$(PKG_NAME)))

