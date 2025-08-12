include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for the MWAN3 multiwan by teltonika

ifeq (m, $(CONFIG_PACKAGE_vuci-app-mwan3-ui))
	APP_APP_NAME:=mwan3
	APP_TLT_NAME:=Failover
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
endif

include ../app.mk

# call BuildPackage - OpenWrt buildroot signature
