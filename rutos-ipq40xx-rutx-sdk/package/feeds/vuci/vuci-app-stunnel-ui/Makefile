include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for STunnel

ifeq (m, $(CONFIG_PACKAGE_vuci-app-stunnel-ui))
	APP_APP_NAME:=stunnel
	APP_TLT_NAME:=Stunnel
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
endif

include ../app.mk

define Package/vuci-app-stunnel-ui/description
	Stunnel is a program that allows you to encrypt arbitrary TCP
	connections inside SSL (Secure Sockets Layer) available on both Unix
	and Windows. Stunnel can allow you to secure non-SSL aware daemons and
	protocols (like POP, IMAP, LDAP, etc) by having Stunnel provide the
	encryption, requiring no changes to the daemon's code.
endef

# call BuildPackage - OpenWrt buildroot signature
