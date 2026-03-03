include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for BFD
ifeq (m, $(CONFIG_PACKAGE_vuci-app-bfd-ui))
	APP_APP_NAME:=bfdd-frr
	APP_TLT_NAME:=BFD
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
endif

include ../app.mk

define Package/vuci-app-bfd-ui/description
	Protocol intended to detect faults in the bidirectional path between two forwarding engines, including interfaces, data link(s), and to the extent possible the forwarding engines themselves, with potentially very low latency.
endef

# call BuildPackage - OpenWrt buildroot signature
