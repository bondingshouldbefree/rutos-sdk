include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for WOL


ifeq (m, $(CONFIG_PACKAGE_vuci-app-wol-ui))
	APP_TLT_NAME:=Wake on LAN
	APP_APP_NAME:=etherwake
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
endif

include ../app.mk

define Package/vuci-app-wol-ui/description
	WOL is an abbreviation for Wake-on-LAN. It is a standard that allows you
	to turn on a computer from another location over a network connection.
endef

# call BuildPackage - OpenWrt buildroot signature
