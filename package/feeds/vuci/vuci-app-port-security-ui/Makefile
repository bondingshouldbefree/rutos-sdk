include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for 802.1X

ifeq (m, $(CONFIG_PACKAGE_vuci-app-port-security-ui))
	APP_APP_NAME:=dot1x-server
	APP_TLT_NAME:=802.1X
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
endif

include ../app.mk

# call BuildPackage - OpenWrt buildroot signature
