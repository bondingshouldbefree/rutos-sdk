include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for Hotspot 2.0

ifeq (m, $(CONFIG_PACKAGE_vuci-app-hotspot2-ui))
	APP_TLT_NAME:=Hotspot 2.0
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
	APP_APP_NAME:=hotspot2
endif

include ../app.mk

define Package/vuci-app-hotspot2-ui/description
	Hotspot 2.0 package provides the possibility to setup your
	own Hotspot 2.0, also known as Passpoint, wireless network.
	Passpoint is a technology standard that enables seamless and
	secure Wi-Fi connectivity, often used in public Wi-Fi networks.
endef

# call BuildPackage - OpenWrt buildroot signature
