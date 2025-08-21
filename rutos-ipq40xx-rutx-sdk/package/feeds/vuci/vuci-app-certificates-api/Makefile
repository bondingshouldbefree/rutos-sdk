include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI API Support for Certificates
APP_USERID:=certificates:certificates
APP_DEPENDS:=+TPM_SUPPORT:tpm2_importer

define Package/vuci-app-certificates-api/conffiles
/etc/config/certificates
endef

include ../api.mk

# call BuildPackage - OpenWrt buildroot signature
