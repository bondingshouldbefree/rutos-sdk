include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for 802.1X Server

NO_API_DEPEND:=y
APP_DEPENDS:=+vuci-app-port-security-api

ifeq (m, $(CONFIG_PACKAGE_vuci-app-dot1x-server-ui))
	APP_APP_NAME:=dot1x-server
	APP_TLT_NAME:=802.1X
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
	APP_DEPENDS:=+vuci-app-port-security-api +vuci-app-dot1x-client-ui
endif

include ../app.mk

# call BuildPackage - OpenWrt buildroot signature
