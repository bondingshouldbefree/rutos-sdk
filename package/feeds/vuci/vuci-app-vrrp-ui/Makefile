include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for VRRP

ifeq (m, $(CONFIG_PACKAGE_vuci-app-vrrp-ui))
	APP_APP_NAME:=vrrpd
	APP_TLT_NAME:=VRRP
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
	APP_HW_INFO:=ethernet
endif

include ../app.mk

# call BuildPackage - OpenWrt buildroot signature
