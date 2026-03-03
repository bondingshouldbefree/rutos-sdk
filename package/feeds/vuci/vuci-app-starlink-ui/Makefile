include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for Starlink
ifeq (m, $(CONFIG_PACKAGE_vuci-app-starlink-ui))
	APP_APP_NAME:=starlink
	APP_TLT_NAME:=Starlink
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
endif

include ../app.mk

define Package/vuci-app-starlink-ui/description
	Starlink management integration
endef

# call BuildPackage - OpenWrt buildroot signature
