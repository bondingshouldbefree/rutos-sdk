# SPDX-License-Identifier: GPL-2.0-or-later
#
# Copyright (C) 2006-2021 OpenWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=busybox
PKG_VERSION:=1.34.1
PKG_RELEASE:=$(AUTORELEASE).12
PKG_FLAGS:=essential

PKG_SOURCE_VERSION:=1.34.1
PKG_SOURCE:=$(PKG_NAME)-$(PKG_SOURCE_VERSION).tar.bz2
PKG_SOURCE_URL:=https://www.busybox.net/downloads \
		http://sources.buildroot.net

PKG_HASH:=415fbd89e5344c96acf449d94a6f956dbed62e18e835fc83e064db33a34bd549

PKG_BUILD_DEPENDS:=BUSYBOX_CONFIG_PAM:libpam
PKG_BUILD_PARALLEL:=1
PKG_BUILD_FLAGS:=lto
PKG_CHECK_FORMAT_SECURITY:=0

# Busybox use it's own PIE config flag and LDFLAGS are used with ld, not gcc.
PKG_ASLR_PIE:=0

PKG_LICENSE:=GPL-2.0-only
PKG_LICENSE_FILES:=LICENSE archival/libarchive/bz/LICENSE
PKG_CPE_ID:=cpe:/a:busybox:busybox

BUSYBOX_SYM=$(if $(CONFIG_BUSYBOX_CUSTOM),CONFIG,DEFAULT)
BUSYBOX_IF_ENABLED=$(if $(CONFIG_BUSYBOX_$(BUSYBOX_SYM)_$(1)),$(2))

include $(INCLUDE_DIR)/package.mk

ifeq ($(DUMP),)
  STAMP_CONFIGURED:=$(strip $(STAMP_CONFIGURED))_$(shell grep '^CONFIG_BUSYBOX_' $(TOPDIR)/.config | $(MKHASH) md5)
endif

# All files provided by busybox will serve as fallback alternatives by opkg.
# There should be no need to enumerate ALTERNATIVES entries here
define Package/busybox/Default
  SECTION:=base
  CATEGORY:=Base system
  MAINTAINER:=Felix Fietkau <nbd@nbd.name>
  TITLE:=Core utilities for embedded Linux
  URL:=http://busybox.net/
  DEPENDS:=+BUSYBOX_CONFIG_PAM:libpam +BUSYBOX_CONFIG_NTPD:jsonfilter +libubus +libubox +BUSYBOX_CONFIG_FEATURE_IP_BLOCKD:liblog +BUSYBOX_CONFIG_PASSWD:liblog +BUSYBOX_CONFIG_FEATURE_NETIFD:libnetifd +BUSYBOX_CONFIG_FEATURE_PASSWORD_POLICY:libuci
ifneq ($(CONFIG_BUSYBOX_$(BUSYBOX_SYM)_FEATURE_SUID),)
  FATTRS:=/bin/busybox:root::y:
endif
endef

define Package/busybox
  $(call Package/busybox/Default)
  VARIANT:=default
endef

define Package/telnet
  SECTION:=base
  CATEGORY:=Base system
  TITLE:=Telnet server
  DEPENDS:=+BUSYBOX_CONFIG_PAM:libpam +BUSYBOX_CONFIG_NTPD:jsonfilter +libubus +libubox +BUSYBOX_CONFIG_FEATURE_IP_BLOCKD:liblog +BUSYBOX_CONFIG_PASSWD:liblog +BUSYBOX_CONFIG_FEATURE_NETIFD:libnetifd +BUSYBOX_CONFIG_FEATURE_PASSWORD_POLICY:libuci
  USERID:=telnetd:telnetd
  FATTRS:=/usr/sbin/telnetd::::cap_net_bind_service=ep
endef

define Package/busybox/description
 The Swiss Army Knife of embedded Linux.
 It slices, it dices, it makes Julian Fries.
endef

define Package/telnet/description
 This package contains a telnet server.
endef

define Package/busybox/config
	source "$(SOURCE)/Config.in"
endef

define Package/telnet/conffiles
/etc/config/telnetd
endef

define Package/busybox/conffiles
/etc/config/telnetd
ifdef CONFIG_BUSYBOX_CONFIG_FEATURE_SYSLOG
/etc/syslog.conf
endif
endef

define Package/untpd
  SECTION:=base
  CATEGORY:=Base system
  TITLE:=Stripped down NTPD (busybox) version
  USERID:=ntp=547:ntp=547
  FATTRS:=/usr/sbin/untpd::::cap_net_bind_service=ep
endef

define Package/untpd/conffiles
/etc/config/ntpserver
endef

ifndef CONFIG_USE_MUSL
LDLIBS:=m crypt
endif

LDLIBS += $(call BUSYBOX_IF_ENABLED,PAM,pam pam_misc pthread)
ifeq ($(CONFIG_USE_GLIBC),y)
  LDLIBS += $(call BUSYBOX_IF_ENABLED,NSLOOKUP_OPENWRT,resolv)
endif

ifdef BUSYBOX_CONFIG_FEATURE_NETIFD
LDLIBS += -lnetifd
endif

MAKE_VARS :=
MAKE_FLAGS += \
	EXTRA_CFLAGS="$(TARGET_CFLAGS) $(TARGET_CPPFLAGS)" \
	EXTRA_LDFLAGS="$(TARGET_LDFLAGS)" \
	LDLIBS="$(LDLIBS)" \
	LD="$(TARGET_CC)" \
	SKIP_STRIP=y
ifneq ($(findstring c,$(OPENWRT_VERBOSE)),)
  MAKE_FLAGS += V=1
endif

define Build/Configure
	rm -f $(PKG_BUILD_DIR)/.config
	touch $(PKG_BUILD_DIR)/.config
ifeq ($(DEVICE_TYPE),nas)
	echo "CONFIG_HDPARM=y" >> $(PKG_BUILD_DIR)/.config
endif
	grep 'CONFIG_BUSYBOX_$(BUSYBOX_SYM)' $(TOPDIR)/.config | sed -e "s,\\(# \)\\?CONFIG_BUSYBOX_$(BUSYBOX_SYM)_\\(.*\\),\\1CONFIG_\\2,g" >> $(PKG_BUILD_DIR)/.config
	yes 'n' | $(MAKE) -C $(PKG_BUILD_DIR) $(MAKE_FLAGS) oldconfig
endef

define Build/Compile
	$(call Build/Compile/Default, \
		CONFIG_PREFIX="$(PKG_INSTALL_DIR)" \
		all install \
	)
	cd $(PKG_BUILD_DIR) && \
	cp .config .config.orig && \
	sed -i 's/^# CONFIG_TELNET is not set/CONFIG_TELNET=y/' .config || true; \
	sed -i 's/^# CONFIG_FEATURE_TELNET_TTYPE is not set/CONFIG_FEATURE_TELNET_TTYPE=y/' .config || true; \
	sed -i 's/^# CONFIG_FEATURE_TELNET_AUTOLOGIN is not set/CONFIG_FEATURE_TELNET_AUTOLOGIN=y/' .config || true; \
	sed -i 's/^# CONFIG_FEATURE_TELNET_WIDTH is not set/CONFIG_FEATURE_TELNET_WIDTH=y/' .config || true; \
	./make_single_applets.sh TELNET && \
	cp busybox_config_TELNET .config && \
	$(MAKE) -C $(PKG_BUILD_DIR) $(MAKE_FLAGS) && \
	mv busybox busybox_TELNET; \
	sed -i 's/^# CONFIG_TELNETD is not set/CONFIG_TELNETD=y/' .config || true; \
	sed -i 's/^# CONFIG_FEATURE_TELNETD_STANDALONE is not set/CONFIG_FEATURE_TELNETD_STANDALONE=y/' .config || true; \
	sed -i 's/^# CONFIG_FEATURE_TELNETD_INETD_WAIT is not set/CONFIG_FEATURE_TELNETD_INETD_WAIT=y/' .config || true; \
	./make_single_applets.sh TELNETD && \
	cp busybox_config_TELNETD .config && \
	$(MAKE) -C $(PKG_BUILD_DIR) $(MAKE_FLAGS) && \
	mv busybox busybox_TELNETD && \
	sed -i 's/^# CONFIG_UNTPD is not set/CONFIG_UNTPD=y/' .config || true; \
	./make_single_applets.sh UNTPD && \
	cp busybox_config_UNTPD .config && \
	$(MAKE) -C $(PKG_BUILD_DIR) $(MAKE_FLAGS) && \
	mv busybox busybox_UNTPD; \
	cp .config.orig .config
endef

define Package/telnet/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF_USR) ./files/telnetd.conf $(1)/etc/config/telnetd
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/telnetd $(1)/etc/init.d/telnetd
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/busybox_TELNETD $(1)/usr/sbin/telnetd
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/busybox_TELNET $(1)/usr/bin/telnet
	$(INSTALL_DIR) $(1)/etc/permtab.d
	$(INSTALL_DATA) ./files/telnetd.permtab $(1)/etc/permtab.d/telnetd
endef

define Package/untpd/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/config $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/busybox_UNTPD $(1)/usr/sbin/untpd
	$(INSTALL_BIN) ./files/ntpserver.init $(1)/etc/init.d/ntpserver
	$(INSTALL_BIN) ./files/ntpserver.conf $(1)/etc/config/ntpserver
endef

define Package/busybox/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/usr/sbin
	$(CP) $(PKG_INSTALL_DIR)/* $(1)/
ifneq ($(CONFIG_BUSYBOX_$(BUSYBOX_SYM)_CROND),)
	$(INSTALL_BIN) ./files/cron $(1)/etc/init.d/cron
endif
ifneq ($(CONFIG_BUSYBOX_$(BUSYBOX_SYM)_NTPD),)
	$(INSTALL_BIN) ./files/ntpd-hotplug $(1)/usr/sbin/ntpd-hotplug
	$(INSTALL_DIR) $(1)/etc/capabilities $(1)/usr/share/acl.d
	$(INSTALL_DATA) ./files/ntpd.capabilities $(1)/etc/capabilities/ntpd.json
	$(INSTALL_DATA) ./files/ntpd_acl.json $(1)/usr/share/acl.d/ntpd.json
endif
ifneq ($(CONFIG_BUSYBOX_$(BUSYBOX_SYM)_FEATURE_PASSWORD_POLICY),)
	$(INSTALL_DIR) $(1)/etc/profile.d
	$(INSTALL_DATA) ./files/password_policy.conf $(1)/etc/config/password_policy
	$(INSTALL_BIN) ./files/check_password_expiration.sh $(1)/etc/profile.d/check_password_expiration.sh
endif
	-rm -rf $(1)/lib64
endef

$(eval $(call BuildPackage,telnet))
$(eval $(call BuildPackage,untpd))
$(eval $(call BuildPackage,busybox))
