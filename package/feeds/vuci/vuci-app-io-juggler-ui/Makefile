include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for I/O Juggler

ifeq (m, $(CONFIG_PACKAGE_vuci-app-io-juggler-ui))
	APP_TLT_NAME:=I/O Juggler
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
	APP_APP_NAME:=io_juggler
	APP_HW_INFO:=ios
endif

include ../app.mk

define Package/vuci-app-io-juggler-ui/description
	The I/O Juggler provides the possibility to create automated rules
	that perform certain actions based on Input state changes and other conditions.
endef

# call BuildPackage - OpenWrt buildroot signature
