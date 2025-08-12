include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=bfdd-frr
PKG_VERSION:=2024-10-10
PKG_RELEASE:=2
PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/bfdd-frr
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Configuration template for frr-bfdd service
	DEPENDS:=+frr-bfdd
	USERID:=bfd:frr
endef

define Package/bfdd-frr/description
	Configuration template for frr-bfdd service
endef


define Package/bfdd-frr/conffiles
/etc/config/bfd
endef


define Package/bfdd-frr/install
	$(INSTALL_DIR) $(1)/etc/frr $(1)/etc/init.d/ $(1)/etc/permtab.d/
	$(INSTALL_BIN) files/etc/lib/bfd_utils.sh $(1)/etc/frr
	$(INSTALL_BIN) files/etc/init/bfd.init $(1)/etc/init.d/bfd
endef

define Package/bfdd-frr/postinst
	#!/bin/sh
	. /lib/functions.sh

	get_status() {

		config_load "bfd"
		config_get enabled "bfd" "enabled" "0"

		[ "$$enabled" == "0" ] && return 1

		return 0
	}

	get_status && /etc/init.d/frr reload

	exit 0
endef

define Package/bfdd-frr/prerm
	#!/bin/sh
	. /lib/functions.sh

	get_status() {

		config_load "bfd"
		config_get enabled "bfd" "enabled" "0"

		[ "$$enabled" == "0" ] && return 1

		return 0
	}

	get_status && /etc/init.d/frr reload

	exit 0
endef

$(eval $(call BuildPackage,bfdd-frr))
