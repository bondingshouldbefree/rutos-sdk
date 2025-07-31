include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI API Support for 802.1X

APP_DEPENDS:=+(HAS_DOT1X_SERVER||SWITCH_DEVICE):dsa-dot1x-server \
		 +(HAS_DOT1X_SERVER||SWITCH_DEVICE):radius_test \
		 +(HAS_DOT1X_CLIENT||SWITCH_DEVICE):dot1x-client

include ../api.mk

# call BuildPackage - OpenWrt buildroot signature
