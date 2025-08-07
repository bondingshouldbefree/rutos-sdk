include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for Ntrip

APP_TLT_NAME:=NTRIP
APP_ROUTER:=$(TLT_PLATFORM_NAME)
APP_APP_NAME:=ntrip_client_v2
APP_HW_INFO:=usb/rs485/rs232

include ../app.mk

define Package/vuci-app-ntrip-ui/description
  NTRIP client designed for providing differential correction data acquired via Internet Protocol to RTK receiver or rover connected via serial connection.
  It is not meant to correct the GPS coordinates of the Teltonika device itself.
endef

# call BuildPackage - OpenWrt buildroot signature
