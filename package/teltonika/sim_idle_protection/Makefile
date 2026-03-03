include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=sim_idle_protection

PKG_SOURCE_VERSION:=7.18

PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=base
	CATEGORY:=Base system
	TITLE:=sim idle protection
	USERID:=sim_idle_protection=574:sim_idle_protection=574
endef

define Package/$(PKG_NAME)/description
	Package enabling periodic switching to a secondary SIM card for data
	connection, preventing SIM card blockage due to inactivity.
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/sim_idle_protection
endef


define Package/sim_idle_protection/postinst
	#!/bin/sh
	. /lib/functions.sh

	[[ -s "/etc/config/sim_idle_protection" ]] && return 0

	touch /etc/config/sim_idle_protection

	add_sim_idle_protection_config() {
		config_get modem $$1 modem
		config_get position $$1 position
		config_get esim_profile $$1 esim_profile

		[[ -z "$$modem" ]] && return
		[[ -z "$$position" ]] && return

		uci_add sim_idle_protection sim_idle_protection
		uci_set sim_idle_protection $$CONFIG_SECTION enable 0
		uci_set sim_idle_protection $$CONFIG_SECTION period month
		uci_set sim_idle_protection $$CONFIG_SECTION day 1
		uci_set sim_idle_protection $$CONFIG_SECTION hour 1
		uci_set sim_idle_protection $$CONFIG_SECTION min 0
		uci_set sim_idle_protection $$CONFIG_SECTION packet_size 56
		uci_set sim_idle_protection $$CONFIG_SECTION count 2
		uci_set sim_idle_protection $$CONFIG_SECTION host 8.8.8.8
		uci_set sim_idle_protection $$CONFIG_SECTION ip_type ipv4
		uci_set sim_idle_protection $$CONFIG_SECTION modem "$$modem"
		uci_set sim_idle_protection $$CONFIG_SECTION position "$$position"
		uci_set sim_idle_protection $$CONFIG_SECTION esim_profile "$$esim_profile"
		uci_commit sim_idle_protection
	}

	config_load simcard
	config_foreach add_sim_idle_protection_config sim

	[[ -x "/bin/trigger_vuci_routes_reload" ]] && /bin/trigger_vuci_routes_reload
endef

define Package/$(PKG_NAME)/prerm
    #!/bin/sh
	[[ -s "/etc/config/sim_idle_protection" ]] && rm -f /etc/config/sim_idle_protection
	[[ -s "/etc/crontabs/sim_idle_protection" ]] && rm -f /etc/crontabs/sim_idle_protection
	[[ -s "/etc/permtab.d/sim_idle_protection" ]] && rm -f /etc/permtab.d/sim_idle_protection
	[[ -x "/bin/trigger_vuci_routes_reload" ]] && /bin/trigger_vuci_routes_reload
endef


define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/init.d/ $(1)/etc/permtab.d/ $(1)/sbin/ $(1)/etc/config/ $(1)/usr/share/acl.d/
	$(INSTALL_BIN_USR) $(PKG_BUILD_DIR)/files/sim_idle_protection.init $(1)/etc/init.d/sim_idle_protection
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/sim_idle_protection.sh $(1)/sbin/sim_idle_protection.sh
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/acl.d/sim_idle_protection.json $(1)/usr/share/acl.d/sim_idle_protection.json
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/permtab.d/sim_idle_protection $(1)/etc/permtab.d/sim_idle_protection
endef

$(eval $(call BuildPackage,sim_idle_protection))
