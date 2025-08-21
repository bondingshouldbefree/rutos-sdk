include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for OPC UA server

ifeq (m, $(CONFIG_PACKAGE_vuci-app-opcua-server-ui))
	APP_TLT_NAME:=OPC UA Server
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
	APP_APP_NAME:=opcua_server
endif

include ../app.mk

define Package/vuci-app-opcua-server-ui/description
	OPC UA server designed for OPC UA clients to read device data.
endef

# call BuildPackage - OpenWrt buildroot signature
