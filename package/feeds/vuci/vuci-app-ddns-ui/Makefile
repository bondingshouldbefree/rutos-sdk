include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for Dynamic DNS


ifeq (m, $(CONFIG_PACKAGE_vuci-app-ddns-ui))
	APP_TLT_NAME:=DDNS
	APP_APP_NAME:=tlt-ddns
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
endif

include ../app.mk

define Package/vuci-app-ddns-ui/description
	Dynamic DNS (DDNS or DynDNS) is a method of automatically updating
	a name server in the Domain Name System (DNS). This is most often
	utilized when the end user has a dynamic IP address and wants to
	bind it to a static hostname.
endef

# call BuildPackage - OpenWrt buildroot signature
