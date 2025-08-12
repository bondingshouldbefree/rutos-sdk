include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for Modbus TCP Server
APP_DEPENDS:=+vuci-app-universal-gateway-api

ifeq (m, $(CONFIG_PACKAGE_vuci-app-modbus-server-ui))
	APP_TLT_NAME:=MODBUS Server
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
	APP_APP_NAME:=modbus_server
	APP_FIRMWARE:=7.0
endif

include ../app.mk

define Package/vuci-app-modbus-server-ui/description
	MODBUS TCP/Serial server designed for MODBUS clients to read and write device data.
endef

# call BuildPackage - OpenWrt buildroot signature
