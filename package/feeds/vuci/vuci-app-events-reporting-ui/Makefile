include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for Events Reporting

ifeq (m, $(CONFIG_PACKAGE_vuci-app-events-reporting-ui))
	APP_TLT_NAME:=Events reporting
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
	APP_APP_NAME:=events_reporting
endif

include ../app.mk

define Package/vuci-app-events-reporting-ui/description
	Events reporting feature provides the possibility to configure
	rules that inform via SMS or email when certain trigger events occur.
endef

# call BuildPackage - OpenWrt buildroot signature
