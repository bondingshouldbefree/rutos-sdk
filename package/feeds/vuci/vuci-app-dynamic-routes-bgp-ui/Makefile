include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support Dynamic routes bgp application

ifeq (m, $(CONFIG_PACKAGE_vuci-app-dynamic-routes-bgp-ui))
	APP_APP_NAME:=frr-bgpd
	APP_TLT_NAME:= BGP daemon
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
endif

include ../app.mk

define Package/vuci-app-dynamic-routes-bgp-ui/description
	Border Gateway Protocol (BGP) is a standardized exterior
	gateway protocol designed to exchange routing and reachability
	information among autonomous systems (AS) on the Internet.
endef

# call BuildPackage - OpenWrt buildroot signature
