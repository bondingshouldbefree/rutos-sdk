include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for IEC 60870-5 Server

ifeq (m, $(CONFIG_PACKAGE_vuci-app-iec60870-server-ui))
	APP_TLT_NAME:=IEC 60870-5 Server
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
	APP_APP_NAME:=iec60870-server
endif

include ../app.mk

define Package/vuci-app-iec60870-server-ui/description
	Server application implementation intended for router data provision and control using IEC 60870 protocol.
	Supports both 104 and 101 parts of specification.
endef

# call BuildPackage - OpenWrt buildroot signature
