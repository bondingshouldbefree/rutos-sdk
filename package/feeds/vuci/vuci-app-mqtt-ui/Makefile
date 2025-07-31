include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for MQTT

ifeq (m, $(CONFIG_PACKAGE_vuci-app-mqtt-ui))
	APP_TLT_NAME:=MQTT
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
	APP_APP_NAME:=mqtt_pub
endif

include ../app.mk

define Package/vuci-app-mqtt-ui/description
	MQTT protocol services' bundle. With this package it is
	possible to set up MQTT Broker and MQTT Bridge for data transferring
	and custom Teltonika MQTT Client for data retrieval.
endef

# call BuildPackage - OpenWrt buildroot signature
