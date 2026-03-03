include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=ldpd-frr
PKG_VERSION:=2025-11-03
PKG_RELEASE:=1
PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/ldpd-frr
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Configuration template for frr-ldpd service
	DEPENDS:=+frr-ldpd +kmod-mpls
	USERID:=ldp:frr
endef

define Package/ldpd-frr/description
	Configuration template for frr-ldpd service
endef


define Package/ldpd-frr/conffiles
/etc/config/mpls
endef


define Package/ldpd-frr/install
	$(INSTALL_DIR) $(1)/etc/frr $(1)/etc/init.d/
	$(INSTALL_BIN) files/etc/lib/ldp_utils.sh $(1)/etc/frr
	$(INSTALL_BIN_USR) files/etc/init/ldp.init $(1)/etc/init.d/ldp
endef

define Package/ldpd-frr/postinst
	#!/bin/sh
	. /lib/functions.sh

	get_status() {

		config_load "mpls"
		config_get enabled "ldp" "enabled" "0"

		[ "$$enabled" == "0" ] && return 1

		return 0
	}

	get_status && /etc/init.d/frr reload

	exit 0
endef

define Package/ldpd-frr/prerm
	#!/bin/sh
	. /lib/functions.sh

	get_status() {

		config_load "mpls"
		config_get enabled "ldp" "enabled" "0"

		[ "$$enabled" == "0" ] && return 1

		return 0
	}

	get_status && /etc/init.d/frr reload

	exit 0
endef

$(eval $(call BuildPackage,ldpd-frr))
