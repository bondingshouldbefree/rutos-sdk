include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for DNP3
APP_DEPENDS:=+vuci-app-universal-gateway-api

APP_TLT_NAME:=DNP3
APP_ROUTER:=$(TLT_PLATFORM_NAME)
APP_APP_NAME:=dnp3

include ../app.mk

define Package/vuci-app-dnp3-ui/description
	DNP3 application stack which includes client and outstation.
	DNP3 client is designed for reading data from DNP3 outstations and storing in local database.
	DNP3 outstation is designed for DNP3 clients to read device data.
endef

# call BuildPackage - OpenWrt buildroot signature
