include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for NAT64 (Jool)

ifeq (m, $(CONFIG_PACKAGE_vuci-app-jool-ui))
	APP_APP_NAME:=jool
	APP_TLT_NAME:=Jool
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
endif

include ../app.mk

define Package/vuci-app-jool-ui/description
	NAT64 is an IPv6 transition mechanism that facilitates communication between IPv6 and IPv4 hosts by using a form of network address translation.
endef

# call BuildPackage - OpenWrt buildroot signature
