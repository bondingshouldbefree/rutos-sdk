include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for BondingShouldBeFree
APP_NAME:=$(notdir ${CURDIR})
CLOSED_GPL_INSTALL:=y

ifeq (m, $(CONFIG_PACKAGE_$(APP_NAME)))
	APP_TLT_NAME:=BondingShouldBeFree
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
endif

define Package/$(APP_NAME)/description
	BondingShouldBeFree
endef

include ../app.mk

# call BuildPackage - OpenWrt buildroot signature
