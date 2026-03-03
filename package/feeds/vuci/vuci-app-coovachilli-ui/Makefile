include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for Coova Chilli

ifeq (m, $(CONFIG_PACKAGE_vuci-app-coovachilli-ui))
	APP_TLT_NAME:=Hotspot
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
	APP_APP_NAME:=coova-chilli
	APP_HW_INFO:=ethernet/wifi
endif

include ../app.mk

define Package/vuci-app-coovachilli-ui/description
	CoovaChilli is an open source access controller for wireless LAN
	access points and is based on ChilliSpot. It is used for authenticating
	users of a wireless (or wired) LAN. It supports web based login (UAM)
	which is today's standard for public HotSpots and it supports Wireless
	Protected Access (WPA) which is the standard of the future.
endef

# call BuildPackage - OpenWrt buildroot signature
