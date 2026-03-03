include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI API Support for Package Manager

# when @ is used, pkg name must be full (like in .config file - PACKAGE_*).
# curl and pkg manager is not available on tswos. @ works better with warnings (doesn't display them) when both packages aren't selected
APP_DEPENDS:=+@PACKAGE_curl

include ../api.mk

# call BuildPackage - OpenWrt buildroot signature
