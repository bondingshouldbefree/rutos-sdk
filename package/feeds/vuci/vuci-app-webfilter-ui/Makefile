include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for webfilter

ifeq (m, $(CONFIG_PACKAGE_vuci-app-webfilter-ui))
	APP_TLT_NAME:=Web filter
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
	APP_APP_NAME:=web_filter
endif

include ../app.mk

define Package/vuci-app-webfilter-ui/description
	Web Filter package provides you with the possibility to set up
	lists of wanted or unwanted websites (Blacklists or Whitelists).
endef

# call BuildPackage - OpenWrt buildroot signature
