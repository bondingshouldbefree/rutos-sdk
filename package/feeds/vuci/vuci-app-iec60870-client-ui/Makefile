include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for IEC 60870-5 Client

ifeq (m, $(CONFIG_PACKAGE_vuci-app-iec60870-client-ui))
	APP_TLT_NAME:=IEC 60870-5 Client
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
	APP_APP_NAME:=iec60870-client
endif

include ../app.mk

define Package/vuci-app-iec60870-client-ui/description
	IEC 60870-5 client service for data acquisition.
endef

# call BuildPackage - OpenWrt buildroot signature
