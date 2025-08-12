include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for udprelay

ifeq (m, $(CONFIG_PACKAGE_vuci-app-udprelay-ui))
	APP_APP_NAME:=udprelay
	APP_TLT_NAME:=UDP Broadcast Relay
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
endif

include ../app.mk

define Package/vuci-app-udprelay-ui/description
	This program listens for packets on a specified UDP broadcast port. \
	When a packet is received, it sends that packet to all specified interfaces \
	but the one it came from as though it originated from the original sender.
endef

# call BuildPackage - OpenWrt buildroot signature
