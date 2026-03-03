include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for relayd

ifeq (m, $(CONFIG_PACKAGE_vuci-app-relayd-ui))
	APP_APP_NAME:=relay_configuration
	APP_TLT_NAME:=Relay configuration
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
endif

include ../app.mk

# call BuildPackage - OpenWrt buildroot signature
