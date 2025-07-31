#
# Copyright (C) 2007-2018 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

RCOMPR:=EXCLUDE_PATTERN="chilli_script\|chilli_response" $(RCOMPR)

PKG_NAME:=coova-chilli
PKG_VERSION:=2025-06-12
PKG_MAINTAINER:=Jaehoon You <teslamint@gmail.com>
PKG_LICENSE:=GPL-2.0-or-later
PKG_LICENSE_FILES:=COPYING
PKG_RELEASE:=2

PKG_SOURCE_VERSION:=1.4
PKG_SOURCE_URL:=https://codeload.github.com/coova/coova-chilli/tar.gz/refs/tags/$(PKG_SOURCE_VERSION)?
PKG_SOURCE:=coova-chilli-$(PKG_SOURCE_VERSION).tar.gz
PKG_HASH:=987647a4c8efe7b1e2d7108d56068e3bd7830d326680f0eaa2c705e4c59c46d9

PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_SOURCE_VERSION)-$(PKG_VERSION)

PKG_ORIGIN_URL:=https://github.com/coova/coova-chilli

PKG_INSTALL:=1

PKG_CONFIG_DEPENDS := \
  COOVACHILLI_MINIPORTAL \
  COOVACHILLI_REDIR \
  COOVACHILLI_USERAGENT \
  COOVACHILLI_DNSLOG \
  COOVACHILLI_UAMDOMAINFILE \
  COOVACHILLI_LARGELIMITS \
  COOVACHILLI_NOSSL \
  COOVACHILLI_OPENSSL \
  COOVACHILLI_CURL \
  COOVACHILLI_DATABASE \
  COOVACHILLI_UBUS \
  CONFIG_MOBILE_SUPPORT

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/kernel.mk

define Package/coova-chilli
  SUBMENU:=Captive Portals
  SECTION:=net
  CATEGORY:=Network
  DEPENDS:=+libuci +libtlt_uci +kmod-tun +librt +COOVACHILLI_CYASSL:libcyassl +COOVACHILLI_OPENSSL:libopenssl \
	+COOVACHILLI_DATABASE:libsqlite3 +MOBILE_SUPPORT:libgsm +libubus +libubox +libtltchilli +libjson-c +COOVACHILLI_CURL:libcurl \
	+COOVACHILLI_KMOD:kmod-ipt-coova +libcap +rms-json-hotspot
  TITLE:=Wireless LAN HotSpot controller (Coova Chilli Version)
  URL:=https://coova.github.io/
  MENU:=1
  USERID:=chilli=511:chilli=511
  FATTRS:=/usr/sbin/chilli::::cap_net_admin,cap_net_raw,cap_net_bind_service=ep;/usr/sbin/chilli_script:root::y:
endef

define Package/coova-chilli/description
	CoovaChilli is an open source access controller for wireless LAN
	access points and is based on ChilliSpot. It is used for authenticating
	users of a wireless (or wired) LAN. It supports web based login (UAM)
	which is today's standard for public HotSpots and it supports Wireless
	Protected Access (WPA) which is the standard of the future.
	Authentication,	authorization and accounting (AAA) is handled by your
	favorite radius server.
endef

define Package/coova-chilli/config
  source "$(SOURCE)/Config.in"
endef

define KernelPackage/ipt-coova
  URL:=http://www.coova.org/CoovaChilli
  SUBMENU:=Netfilter Extensions
  DEPENDS:=+kmod-ipt-core +libxtables +kmod-ifb +tc
  TITLE:=Coova netfilter module
  FILES:=$(PKG_BUILD_DIR)/src/linux/xt_*.$(LINUX_KMOD_SUFFIX)
  AUTOLOAD:=$(call AutoProbe,xt_coova)
endef

define KernelPackage/ipt-coova/description
	Netfilter kernel module for CoovaChilli
	Includes:
	- coova
endef

DISABLE_NLS=

TARGET_CFLAGS += $(FPIC) -DCONFIG_MACHINE_$(TLT_PLATFORM_NAME)

CONFIGURE_VARS += \
       ARCH="$(LINUX_KARCH)" \
       KERNEL_DIR="$(LINUX_DIR)"

MAKE_FLAGS += \
       ARCH="$(LINUX_KARCH)" \
       KERNEL_DIR="$(LINUX_DIR)"

MAKE_INSTALL_FLAGS += \
       ARCH="$(LINUX_KARCH)" \
       KERNEL_DIR="$(LINUX_DIR)" \
       INSTALL_MOD_PATH="$(PKG_INSTALL_DIR)"

define Build/Prepare
$(call Build/Prepare/Default)
	( cd $(PKG_BUILD_DIR) ; \
		[ -f ./configure ] || { \
			./bootstrap ; \
		} \
	)
endef

define Build/Configure
	$(call Build/Configure/Default, \
	--without-cyassl \
	--enable-miniconfig \
	--localstatedir=/var/run/chilli \
	--enable-chilliscript \
	$(if $(filter m,$(CONFIG_PACKAGE_coova-chilli)),--sbindir=/usr/local/usr/sbin,) \
	$(if $(CONFIG_COOVACHILLI_CHILLIQUERY),--enable,--disable)-chilliquery \
	$(if $(CONFIG_COOVACHILLI_PROXY),--enable,--disable)-chilliproxy \
	$(if $(CONFIG_COOVACHILLI_REDIR),--enable,--disable)-chilliredir \
	$(if $(CONFIG_COOVACHILLI_DNSLOG),--enable,--disable)-dnslog \
	$(if $(CONFIG_COOVACHILLI_MINIPORTAL),--enable,--disable)-miniportal \
	$(if $(CONFIG_COOVACHILLI_USERAGENT),--enable,--disable)-useragent \
	$(if $(CONFIG_COOVACHILLI_LARGELIMITS),--enable,--disable)-largelimits \
	$(if $(CONFIG_COOVACHILLI_UAMDOMAINFILE),--enable,--disable)-uamdomainfile \
	$(if $(CONFIG_COOVACHILLI_MULTILAN),--enable,--disable)-multilan \
	$(if $(CONFIG_COOVACHILLI_DATABASE),--enable,--disable)-database \
	$(if $(CONFIG_MOBILE_SUPPORT),--enable,--disable)-gsm \
	$(if $(CONFIG_COOVACHILLI_UBUS),--enable,--disable)-ubus \
	$(if $(CONFIG_IPV6),--with,--without)-ipv6 \
	$(if $(CONFIG_COOVACHILLI_OPENSSL),--with,--without)-openssl \
	$(if $(CONFIG_COOVACHILLI_CURL),--with,--without)-curl \
	$(if $(CONFIG_COOVACHILLI_KMOD),--with-nfcoova) \
	)
endef

define Package/coova-chilli/conffiles
/etc/config/chilli
/etc/chilli/users.db
endef

# This is needed to clear the 'Event Juggler' cache because the coova-chilli package is not installed by default on some devices.
# After installation, 'Event Juggler' will update and contain the latest cached data.
define RemoveEventJugglerCachedData
FILE_PATH="/tmp/event_juggler/plugin_data.json"

if [ -f "$${FILE_PATH}" ]; then
    rm -f "$${FILE_PATH}"
fi
endef

define Package/coova-chilli/postinst
#!/bin/sh

[ -z "$${IPKG_INSTROOT}" ] || exit 0

$(RemoveEventJugglerCachedData)

exit 0
endef

define Package/coova-chilli/postrm
#!/bin/sh

[ -z "$${IPKG_INSTROOT}" ] || exit 0

[ -f "/etc/config/snmptrap" ] && {
	. /lib/functions.sh
	. /lib/config/uci.sh

	check_snmptrap() {
		config_get type "$$1" type ""
		if [ "$$type" = "chilli" ]; then
			uci_remove snmptrap "$$1"			
		fi
	}
	config_load snmptrap
	config_foreach check_snmptrap trap
	uci_commit snmptrap
	/etc/init.d/snmptrap reload 2> /dev/null
}

$(RemoveEventJugglerCachedData)

exit 0
endef

define Package/coova-chilli/install
	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_CONF) $(PKG_INSTALL_DIR)/etc/chilli.conf $(1)/etc/
	$(INSTALL_DIR) $(1)/etc/chilli
	$(CP) $(PKG_INSTALL_DIR)/etc/chilli/* $(1)/etc/chilli/
	$(INSTALL_BIN) files/conup.sh $(1)/etc/chilli/
	$(INSTALL_BIN) files/condown.sh $(1)/etc/chilli/
	$(INSTALL_BIN) files/conrestart.sh $(1)/etc/chilli/
	$(INSTALL_BIN) files/macup.sh $(1)/etc/chilli/
	$(INSTALL_BIN) files/macdown.sh $(1)/etc/chilli/
	$(INSTALL_BIN) files/users.db $(1)/etc/chilli/
	$(INSTALL_DIR) $(1)/etc/hotplug.d/net
	$(INSTALL_DATA) ./files/chilli.hotplug $(1)/etc/hotplug.d/net/99-chilli
	$(INSTALL_DIR) $(1)/usr/sbin
	$(if $(filter m,$(CONFIG_PACKAGE_coova-chilli)), \
		$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/local/usr/sbin/chilli* $(1)/usr/sbin/, \
		$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/sbin/chilli* $(1)/usr/sbin/ \
	)
	$(eval DEST_DIR:=$$(1)$(if $(findstring m,$(CONFIG_PACKAGE_coova-chilli)),,/usr/local))
	$(INSTALL_DIR) $(DEST_DIR)/usr/lib/
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/lib*.so.* $(DEST_DIR)/usr/lib/
	$(if $(CONFIG_COOVACHILLI_KMOD), \
		$(INSTALL_DIR) $(DEST_DIR)/usr/lib/iptables; \
		$(CP) $(PKG_INSTALL_DIR)/usr/lib/iptables/lib*.so $(DEST_DIR)/usr/lib/iptables/ \
	)
	$(INSTALL_DIR) $(1)/etc/init.d $(1)/etc/config $(1)/lib/firewall \
		$(1)/lib/upgrade/keep.d $(1)/lib/troubleshoot $(1)/usr/share/acl.d
	$(INSTALL_BIN) files/chilli.init $(1)/etc/init.d/chilli
	$(INSTALL_CONF_USR) files/chilli.config $(1)/etc/config/chilli
	$(CP) $(PKG_BUILD_DIR)/conf/profiles/* $(1)/etc/chilli/
	$(INSTALL_BIN) files/wireless.sh $(1)/etc/chilli/
	$(INSTALL_DATA) files/chilli.upgrade $(1)/lib/upgrade/keep.d/chilli
	$(INSTALL_DATA) files/hotspot.sh $(1)/lib/troubleshoot/
	$(INSTALL_DATA) files/chilli.json $(1)/usr/share/acl.d/
	$(INSTALL_DIR) $(1)/etc/permtab.d
	$(INSTALL_DATA) files/chilli.permtab $(1)/etc/permtab.d/chilli
	$(if $(filter m,$(CONFIG_PACKAGE_coova-chilli)), \
		echo 1 > $(1)/etc/chilli/limit, \
		echo 5 > $(1)/etc/chilli/limit \
	)
endef

$(eval $(call BuildPackage,coova-chilli))
$(eval $(call KernelPackage,ipt-coova))
