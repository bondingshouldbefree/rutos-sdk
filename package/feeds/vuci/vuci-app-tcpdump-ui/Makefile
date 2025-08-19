include $(TOPDIR)/rules.mk

NO_API_DEPEND:=y
APP_TITLE:=VuCI UI Support for tcpdump

APP_DEPENDS=+vuci-app-troubleshoot-ui +tcpdump

ifeq (m, $(CONFIG_PACKAGE_vuci-app-tcpdump-ui))
	APP_APP_NAME:=tcpdump
	APP_TLT_NAME:=TCPdump
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
endif

define Package/vuci-app-tcpdump-ui/description
	TCP dump is used to capture packets moving through network interfaces.
endef

include ../app.mk

# call BuildPackage - OpenWrt buildroot signature
