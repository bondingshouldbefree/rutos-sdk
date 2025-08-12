include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI API Support for Cloud Solutions

APP_DEPENDS:=+rms_mqtt

CUSTOM_INSTALL=1
include ../api.mk

define Package/$(PKG_NAME)/install
	$(call Package/$(PKG_NAME)/install/Default,$(1))
	$(if $(CONFIG_AP_DEVICE),\
		$(RM) $(1)/usr/share/rpcd/acl.d/cloudsolutions.json,\
		$(RM) $(1)/usr/share/rpcd/acl.d/cloudsolutions_system.json)
endef


# call BuildPackage - OpenWrt buildroot signature
$(eval $(call BuildPackage,$(PKG_NAME)))
