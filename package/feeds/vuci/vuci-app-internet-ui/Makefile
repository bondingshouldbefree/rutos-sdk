include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for Internet status

ifeq (m, $(CONFIG_PACKAGE_vuci-app-internet-ui))
	APP_APP_NAME:=connchecker
	APP_TLT_NAME:=Connchecker
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
endif

include ../app.mk

# call BuildPackage - OpenWrt buildroot signature
