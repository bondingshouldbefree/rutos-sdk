include $(TOPDIR)/rules.mk

NO_API_DEPEND:=y
APP_TITLE:=VuCI UI Support for travelmate

APP_DEPENDS=+vuci-app-wireless-ui +travelmate

ifeq (m, $(CONFIG_PACKAGE_vuci-app-travelmate-ui))
	APP_HW_INFO:=wifi
	APP_APP_NAME:=travelmate
	APP_TLT_NAME:=TravelMate
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
endif

define Package/vuci-app-travelmate-ui/description
	Travelmate package provides "Redirect captive portal" functionality to wireless clients.
endef

include ../app.mk

# call BuildPackage - OpenWrt buildroot signature
