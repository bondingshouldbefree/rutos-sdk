include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for Impulse Counter

ifeq (m, $(CONFIG_PACKAGE_vuci-app-impulse-counter-ui))
	APP_TLT_NAME:=Impulse Counter
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
	APP_APP_NAME:=impulse-counter
	APP_HW_INFO:=ios
endif

include ../app.mk

define Package/vuci-app-impulse-counter-ui/description
	Impulse counter application is used to count impulse signals and store them in a database.
endef

# call BuildPackage - OpenWrt buildroot signature
