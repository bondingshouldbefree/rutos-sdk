include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for DMVPN
APP_DEPENDS:=+vuci-app-dynamic-routes-nhrp-ui

ifeq (m, $(CONFIG_PACKAGE_vuci-app-dmvpn-ui))
	APP_APP_NAME:=dmvpn
	APP_TLT_NAME:= DMVPN
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
endif

include ../app.mk

define Package/vuci-app-dmvpn-ui/description
	Dynamic Multipoint VPN (DMVPN) is a method of building scalable IPsec VPNs.
	DMVPN is configured as a hub-and-spoke network, where tunnels between spokes
	are built dynamically; therefore, no change in configuration is required on
	the hub in order to connect new spokes.
endef

# call BuildPackage - OpenWrt buildroot signature
