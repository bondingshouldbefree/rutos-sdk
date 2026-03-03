include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for DNS Over HTTPS Proxy

ifeq (m, $(CONFIG_PACKAGE_vuci-app-https-dns-proxy-ui))
	APP_APP_NAME:=https-dns-proxy
	APP_TLT_NAME:=HTTPS DNS Proxy
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
endif

include ../app.mk

define Package/vuci-app-https-dns-proxy-ui/description
	DNS Over HTTPS Proxy
endef

# call BuildPackage - OpenWrt buildroot signature
