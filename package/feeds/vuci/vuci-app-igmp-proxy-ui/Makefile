include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for IGMP Proxy

ifeq (m, $(CONFIG_PACKAGE_vuci-app-igmp-proxy-ui))
	APP_APP_NAME:=igmpproxy
	APP_TLT_NAME:=IGMP Proxy
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
endif

include ../app.mk

define Package/vuci-app-igmp-proxy-ui/description
	IGMPproxy is a simple dynamic Multicast Routing Daemon
	which enables the ability for the router to learn multicast group membership information
	and forward multicast packets
endef

# call BuildPackage - OpenWrt buildroot signature
