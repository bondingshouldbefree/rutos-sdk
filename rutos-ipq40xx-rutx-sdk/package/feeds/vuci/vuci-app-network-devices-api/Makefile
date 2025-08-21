include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI API Support for the Network Devices

CUSTOM_INSTALL=1
include ../api.mk

define Package/$(PKG_NAME)/install
	$(call Package/$(PKG_NAME)/install/Default,$(1))
	$(if $(CONFIG_SWITCH_DEVICE),\
		$(RM) $(1)/usr/lib/lua/api/network/devices_bridge.lua ; \
		$(RM) $(1)/usr/lib/lua/api/network/devices_ethernet.lua ; \
		$(RM) $(1)/usr/lib/lua/api/network/devices_utils.lua ; \
		$(RM) $(1)/usr/lib/lua/api/network/devices_port_based.lua
	)
endef

# call BuildPackage - OpenWrt buildroot signature
$(eval $(call BuildPackage,$(PKG_NAME)))
