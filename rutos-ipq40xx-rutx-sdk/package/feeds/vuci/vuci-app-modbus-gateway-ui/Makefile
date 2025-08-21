include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for Modbus Gateway

ifeq (m, $(CONFIG_PACKAGE_vuci-app-modbus-gateway-ui))
	APP_TLT_NAME:=MQTT Modbus gateway
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
	APP_APP_NAME:=mqtt-modbus-gateway
endif

include ../app.mk

define Package/vuci-app-modbus-gateway-ui/description
	MQTT-Modbus Gateway is a service meant to read/write MODBUS TCP/RTU servers via MQTT messages.
endef

# call BuildPackage - OpenWrt buildroot signature
