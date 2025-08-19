include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for PAM authentication

ifeq (m, $(CONFIG_PACKAGE_vuci-app-pamd-ui))
	APP_TLT_NAME:=PAM
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
	APP_APP_NAME:=pam
endif

include ../app.mk

define Package/vuci-app-pamd-ui/description
	Privileged access management (PAM) allows to manage access
	for different services through TACACS+ or Radius server.
endef

# call BuildPackage - OpenWrt buildroot signature
