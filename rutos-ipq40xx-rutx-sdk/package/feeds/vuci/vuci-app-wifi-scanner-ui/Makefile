include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for Wifi scanner


ifeq (m, $(CONFIG_PACKAGE_vuci-app-wifi-scanner-ui))
	APP_TLT_NAME:=Wifi Scanner
	APP_APP_NAME:=wifi_scanner
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
endif

include ../app.mk

define Package/vuci-app-wifi-scanner-ui/description
	Wireless devices beacon and probe packet analyzer
endef

# call BuildPackage - OpenWrt buildroot signature
