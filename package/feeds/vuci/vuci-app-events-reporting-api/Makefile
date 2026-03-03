include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI API Support for Events Reporting

APP_DEPENDS:=+event-juggler +libparam +libubus +liblua +MOBILE_SUPPORT:libgsm

CUSTOM_INSTALL=1
include ../api.mk

ifneq ($(CONFIG_GPL_INCLUDE_WEB_SOURCES), y)
endif

define Package/$(PKG_NAME)/install
	$(call Package/$(PKG_NAME)/install/Default,$(1))
	$(INSTALL_DIR) $(1)/usr/lib/lua/
	$(CP) $(PKG_BUILD_DIR)/lualibparam.so $(1)/usr/lib/lua/
endef

# call BuildPackage - OpenWrt buildroot signature
$(eval $(call BuildPackage,$(PKG_NAME)))
