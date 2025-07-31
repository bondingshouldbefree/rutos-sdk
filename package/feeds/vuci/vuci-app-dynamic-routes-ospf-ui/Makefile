include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support Dynamic routes ospf application

ifeq (m, $(CONFIG_PACKAGE_vuci-app-dynamic-routes-ospf-ui))
	APP_APP_NAME:=frr-ospfd
	APP_TLT_NAME:= OSPF daemon
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
endif

include ../app.mk

define Package/vuci-app-dynamic-routes-ospf-ui/description
	Open Shortest Path First (OSPF) is a routing protocol
	for Internet Protocol (IP) networks. It uses a link state
	routing (LSR) algorithm and falls into the group of interior
	gateway protocols (IGPs), operating within a single autonomous system (AS).
endef

# call BuildPackage - OpenWrt buildroot signature
