include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for Traffic Logging

ifeq (m, $(CONFIG_PACKAGE_vuci-app-ulog-ui))
	APP_TLT_NAME:=Traffic Logging
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
	APP_APP_NAME:=tlt-ulogd
endif

include ../app.mk

define Package/vuci-app-ulog-ui/description
  Traffic logger is a service that provides the possibility
  to set up periodic transfers of the selected traffic log
  to the FTP server.
endef

# call BuildPackage - OpenWrt buildroot signature
