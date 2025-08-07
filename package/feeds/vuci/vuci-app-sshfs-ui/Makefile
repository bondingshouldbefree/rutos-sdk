include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for SSHFS

ifeq (m, $(CONFIG_PACKAGE_vuci-app-sshfs-ui))
	APP_APP_NAME:=sshfs
	APP_TLT_NAME:=SSHFS
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
endif

include ../app.mk

define Package/vuci-app-sshfs-ui/description
	Simple application to mount and interact with directories and files located on a remote server or workstation over SFTP.
endef

# call BuildPackage - OpenWrt buildroot signature
