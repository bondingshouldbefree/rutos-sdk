include $(TOPDIR)/rules.mk

PKG_NAME:=netifd
PKG_RELEASE:=4

PKG_SOURCE_DATE:=2025-05-23
PKG_MAINTAINER:=Felix Fietkau <nbd@nbd.name>

PKG_LICENSE:=GPL-2.0-only
PKG_LICENSE_FILES:=

PKG_BUILD_PARALLEL:=1
PKG_BUILD_FLAGS:=lto

PKG_CONFIG_DEPENDS += \
	CONFIG_USE_PROCD \
	CONFIG_USE_OPENRC

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL=$(PROJECT_GIT)/project/netifd.git
PKG_SOURCE_VERSION:=7901e66c5f273bceee8981bc8a0c8b0e60945f60

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/netifd
  SECTION:=base
  CATEGORY:=Base system
  DEPENDS:=+libuci +libnl-tiny +libubus +ubus +ubusd +jshn +libubox +rpcd
  TITLE:=OpenWrt Network Interface Configuration Daemon
endef

define Package/netifd/conffiles
/etc/udhcpc.user
/etc/udhcpc.user.d/
endef

TARGET_CFLAGS += \
	-I$(STAGING_DIR)/usr/include/libnl-tiny \
	-I$(STAGING_DIR)/usr/include

CMAKE_OPTIONS += \
	-DLIBNL_LIBS=-lnl-tiny \
	-DDEBUG=1

define Package/netifd/install
	$(INSTALL_DIR) $(1)/sbin $(1)/lib/config.d $(1)/usr/libexec/rpcd
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/netifd $(1)/sbin/
	$(CP) ./files/* $(1)/
	$(LN) /usr/local/lib/netifd/proto $(1)/lib/netifd/
	$(INSTALL_DIR) $(1)/etc/udhcpc.user.d/
	$(CP) $(PKG_BUILD_DIR)/scripts/* $(1)/lib/netifd/
	$(INSTALL_BIN) ./files/usr/libexec/rpcd/wan_info $(1)/usr/libexec/rpcd/

	$(CP) $(1)/lib/network/300-setup-network $(1)/lib/config.d

	$(if $(CONFIG_SMP_SUPPORT),, \
		$(RM) $(1)/etc/hotplug.d/net/20-smp-packet-steering)

	$(if $(and $(CONFIG_MOBILE_SUPPORT),$(CONFIG_HAS_SINGLE_ETH_PORT)),,\
    	$(RM) $(1)/etc/hotplug.d/iface/29-setup-mobile-gateway-passthrough-bridge)

	$(if $(CONFIG_ADVANCED_NETWORK),,\
		$(RM) $(1)/usr/local/usr/lib/netifd/proto/l2tpv3.sh)

	$(if $(CONFIG_PPP_MOBILE_SUPPORT),, \
		$(RM) $(1)/usr/local/usr/lib/netifd/proto/pppmobile.sh)

	$(if $(CONFIG_USE_OPENRC),\
		$(OPENRC_INSTALL) boot network ./files/etc/init.d/network.openrc $(1))
	$(RM) $(1)/etc/init.d/network.openrc

	$(if $(CONFIG_AP_DEVICE), \
		mv $(1)/usr/local/usr/lib/netifd/proto/dhcp-tap.sh $(1)/usr/local/usr/lib/netifd/proto/dhcp.sh; \
		mv $(1)/lib/netifd/dhcp-tap.script $(1)/lib/netifd/dhcp.script; ,
		$(RM) $(1)/usr/local/usr/lib/netifd/proto/dhcp-tap.sh; \
		$(RM) $(1)/lib/netifd/dhcp-tap.script;)
endef

$(eval $(call BuildPackage,netifd))
