include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for Modbus
APP_DEPENDS:=+vuci-app-universal-gateway-api

ifneq ($(or $(CONFIG_USB_SUPPORT_EXTERNAL),$(CONFIG_SERIAL_SUPPORT)),)
	APP_DEPENDS+=vuci-app-modbus-serial-ui
endif

ifeq (m, $(CONFIG_PACKAGE_vuci-app-modbus-client-ui))
	APP_TLT_NAME:=MODBUS Client
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
	APP_APP_NAME:=modbus_client
endif

include ../app.mk

define Package/vuci-app-modbus-client-ui/description
	MODBUS TCP/Serial client designed for reading/writing data from MODBUS servers and storing read data in local database.
endef

# call BuildPackage - OpenWrt buildroot signature
