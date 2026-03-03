include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for TR-069

ifeq (m, $(CONFIG_PACKAGE_vuci-app-tr069-ui))
	APP_TLT_NAME:=TR-069
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
	APP_APP_NAME:=easycwmp
endif

include ../app.mk

define Package/vuci-app-tr069-ui/description
 TR-069 is an open source implementation of the client CWMP (TR-069)
 protocol for data transfer to Auto Configuration Server (ACS).
endef

# call BuildPackage - OpenWrt buildroot signature
