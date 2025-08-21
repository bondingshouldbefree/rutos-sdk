include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for VXLAN

APP_DEPENDS=+vuci-app-network-devices-ui

ifeq (m, $(CONFIG_PACKAGE_vuci-app-vxlan-ui))
	APP_APP_NAME:=vxlan
	APP_TLT_NAME:=VXLAN
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
	PKG_NETWORK_RESTART:=1
endif

define Package/vuci-app-vxlan-ui/description
	VXLAN is a tunneling technology used on large Layer 2 networks, and transmits packets over a VXLAN tunnel between source and destination devices.
endef

include ../app.mk

# call BuildPackage - OpenWrt buildroot signature
