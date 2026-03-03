include $(TOPDIR)/rules.mk

PKG_LICENSE:=Teltonika-nda-source

APP_TITLE:=VuCI UI Support for APN database

ifeq (m, $(CONFIG_PACKAGE_vuci-app-apn-database-ui))
	APP_APP_NAME:=apn-db-webui
	APP_TLT_NAME:=APN Database webui
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
endif

define Package/vuci-app-apn-database-ui/description
	Package for additional WebUI page to manage APN database values.
endef

include ../app.mk

# call BuildPackage - OpenWrt buildroot signature
