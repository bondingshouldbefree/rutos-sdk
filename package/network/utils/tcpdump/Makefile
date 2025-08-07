#
# Copyright (C) 2007-2011 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=tcpdump
PKG_VERSION:=4.99.5
PKG_RELEASE:=1

PKG_SOURCE_VERSION:=4.99.5
PKG_SOURCE:=$(PKG_NAME)-$(PKG_SOURCE_VERSION).tar.gz
PKG_SOURCE_URL:=https://www.tcpdump.org/release/

PKG_HASH:=8c75856e00addeeadf70dad67c9ff3dd368536b2b8563abf6854d7c764cd3adb

PKG_MAINTAINER:=Felix Fietkau <nbd@nbd.name>
PKG_LICENSE:=BSD-3-Clause
PKG_CPE_ID:=cpe:/a:tcpdump:tcpdump

PKG_INSTALL:=1
PKG_BUILD_FLAGS:=gc-sections
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/tcpdump/default
  SECTION:=net
  CATEGORY:=Network
  DEPENDS:=+libpcap
  TITLE:=Network monitoring and data acquisition tool
  URL:=http://www.tcpdump.org/
endef

define Package/tcpdump
  $(Package/tcpdump/default)
  VARIANT:=full
endef

define Package/tcpdump-mini
  $(Package/tcpdump/default)
  TITLE+= (minimal version)
  VARIANT:=mini
endef

# Remove TCPdump configuration from system config file
define Package/tcpdump/prerm
  #!/bin/sh
  . /lib/functions.sh
  config_load system
  for opt in dump dump_interface dump_filter inout host port mount; do
	uci_remove system system "tcp_$${opt}" 2>/dev/null
  done
  uci_commit system
endef

CONFIGURE_ARGS += \
	--without-cap-ng \
	--without-crypto \
	$(call autoconf_bool,CONFIG_IPV6,ipv6)

ifeq ($(BUILD_VARIANT),mini)
  TARGET_CFLAGS += -DTCPDUMP_MINI
  CONFIGURE_ARGS += --disable-smb
  MAKE_FLAGS += TCPDUMP_MINI=1
endif

define Package/tcpdump/install
  $(eval DEST_DIR:=$$(1)$(if $(findstring m,$(CONFIG_PACKAGE_tcpdump)),,/usr/local))
	$(INSTALL_DIR) $(DEST_DIR)/usr/sbin $(1)/etc/init.d/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/tcpdump $(DEST_DIR)/usr/sbin/
	$(INSTALL_BIN) ./files/tcpdebug.init $(1)/etc/init.d/tcpdebug
endef

Package/tcpdump-mini/install = $(Package/tcpdump/install)

$(eval $(call BuildPackage,tcpdump))
$(eval $(call BuildPackage,tcpdump-mini))
