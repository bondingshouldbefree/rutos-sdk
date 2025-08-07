include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=impulse-counter
PKG_VERSION:=2025-07-02
PKG_SOURCE_VERSION:=7.16
PKG_LICENSE:=Teltonika-closed


include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=base
	CATEGORY:=Base system
	TITLE:=Impulse counter
	DEPENDS:=+libubox +libuci +libtlt_uci +libubus +libblobmsg-json +lsqlite3 +libtlt-logger +iomand
	USERID:=icounter=592:icounter=592
endef

define Package/$(PKG_NAME)/description
	Impulse counter application is used to count impulse signals and store them in a database.
endef


define Package/$(PKG_NAME)/conffiles
/etc/config/impulse_counter
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/init.d $(1)/etc/config $(1)/usr/share/acl.d $(1)/etc/permtab.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/impulse_counter $(1)/usr/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/impulse_counter.init $(1)/etc/init.d/impulse_counter
	$(INSTALL_CONF_USR) $(PKG_BUILD_DIR)/files/impulse_counter.conf $(1)/etc/config/impulse_counter
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/impulse_counter.json $(1)/usr/share/acl.d/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/impulse_counter.permtab $(1)/etc/permtab.d/impulse_counter
endef

define Package/$(PKG_NAME)/postinst
	#!/bin/sh

	/etc/init.d/rpcd reload

	[ -z "$${IPKG_INSTROOT}" ] || exit 0
	[ -e /lib/data_sender/libdata_sender.sh ] || exit 0

	. /lib/data_sender/libdata_sender.sh

	ds_find_plugin impulse_counter && /etc/init.d/data_sender restart

	exit 0
endef

define Package/$(PKG_NAME)/prerm
	#!/bin/sh
	. /lib/functions.sh
	. /lib/config/uci.sh

	rm -f /tmp/impulse_counter.db

	[ -f "/etc/config/data_sender" ] || return 0

	config_load data_sender

	list_length=0
	impulse_counter_list_count=0

	check_list_impulse_counter_in() {
		list_length=$$((list_length+1))
	}

	count_impulse_counter_in() {
		config_get plugin "$$1" plugin ""
		[ "$$plugin" = "impulse_counter" ] && impulse_counter_list_count=$$((impulse_counter_list_count+1))
	}

	del_impulse_counter_in() {
		uci_remove data_sender "$$1"
	}

	check_impulse_counter_col() {
		list_length=0
		impulse_counter_list_count=0

		config_foreach count_impulse_counter_in "input"
		config_list_foreach "$$1" input check_list_impulse_counter_in

		if [ "$$list_length" -ge 2 ] && [ "$$list_length" -ne "$$impulse_counter_list_count" ]; then
			uci_remove data_sender "$$2"
			uci_remove_list data_sender "$$1" input "$$2"
		elif [ "$$list_length" -ge 2 ] && [ "$$list_length" -eq "$$impulse_counter_list_count" ]; then
			config_list_foreach "$$1" input del_impulse_counter_in

			config_get out "$$1" output ""
			uci_remove data_sender "$$out"

			uci_remove data_sender "$$1"
		else
			config_get in "$$1" input ""
			uci_remove data_sender "$$in"

			config_get out "$$1" output ""
			uci_remove data_sender "$$out"

			uci_remove data_sender "$$1"

		fi

	}

	start_impulse_counter_in() {
		config_get plugin "$$1" plugin ""
		[ "$$plugin" = "impulse_counter" ] || return 0

		config_foreach check_impulse_counter_col "collection" "$$1"
		uci_commit data_sender 2> /dev/null
		config_load data_sender
	}

	config_foreach start_impulse_counter_in "input"
	/etc/init.d/data_sender reload 2> /dev/null || true
endef

define Package/$(PKG_NAME)/postrm
	#!/bin/sh
	/etc/init.d/rpcd reload
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
