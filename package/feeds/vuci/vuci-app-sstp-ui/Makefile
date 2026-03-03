include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for SSTP
ifeq (m, $(CONFIG_PACKAGE_vuci-app-sstp-ui))
	APP_APP_NAME:=sstp-client
	APP_TLT_NAME:=SSTP
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
endif

include ../app.mk

define Package/vuci-app-sstp-ui/description
	Secure Socket Tunneling Protocol (SSTP) is a VPN protocol
	designed to transport PPP traffic via a secure SSL/TLS channel.
endef

# call BuildPackage - OpenWrt buildroot signature
