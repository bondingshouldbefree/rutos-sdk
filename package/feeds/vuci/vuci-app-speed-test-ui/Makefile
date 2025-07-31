include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for Speed Test


ifeq (m, $(CONFIG_PACKAGE_vuci-app-speed-test-ui))
	APP_TLT_NAME:=Speedtest
	APP_APP_NAME:=speedtest
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
endif

include ../app.mk

define Package/vuci-app-speed-test-ui/description
	Speed Test package provides with the possibility to test
	the data transfer speed of your WAN connection.
endef

# call BuildPackage - OpenWrt buildroot signature
