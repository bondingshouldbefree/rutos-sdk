include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for VRF

ifeq (m, $(CONFIG_PACKAGE_vuci-app-vrf-ui))
	APP_APP_NAME:=vrf
	APP_TLT_NAME:=VRF
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
endif

include ../app.mk

# call BuildPackage - OpenWrt buildroot signature
