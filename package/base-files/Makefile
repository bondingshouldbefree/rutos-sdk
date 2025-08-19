#
# Copyright (C) 2007-2021 OpenWrt.org
# Copyright (C) 2010 Vertical Communications
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/version.mk
include $(INCLUDE_DIR)/feeds.mk

PKG_NAME:=base-files
PKG_FLAGS:=nonshared
PKG_RELEASE:=$(COMMITCOUNT)

PKG_FILE_DEPENDS:=$(PLATFORM_DIR)/ $(GENERIC_PLATFORM_DIR)/base-files/
PKG_BUILD_DEPENDS:=ucert/host
PKG_LICENSE:=GPL-2.0-only
PKG_LICENSE_FILES:=LICENSES/GPL-2.0

PKG_ORIGIN_URL:=https://github.com/openwrt/openwrt/blob/openwrt-21.02/package/base-files

# Extend depends from version.mk
PKG_CONFIG_DEPENDS += \
	CONFIG_SIGNED_PACKAGES \
	CONFIG_TARGET_INIT_PATH \
	CONFIG_NAND_SUPPORT \
	CONFIG_CLEAN_IPKG \
	CONFIG_PER_FEED_REPO \
	CONFIG_USE_PROCD \
	CONFIG_USE_OPENRC \
	$(foreach feed,$(FEEDS_AVAILABLE),CONFIG_FEED_$(feed))

include $(INCLUDE_DIR)/package.mk

ifneq ($(DUMP),1)
  STAMP_CONFIGURED:=$(strip $(STAMP_CONFIGURED))_$(shell echo $(CONFIG_TARGET_INIT_PATH) | $(MKHASH) md5)
  TARGET:=-$(BOARD)
endif

define Package/base-files
  SECTION:=base
  CATEGORY:=Base system
  DEPENDS:=+netifd +libc +jsonfilter +SIGNATURE_CHECK:usign +SIGNATURE_CHECK:openwrt-keyring +NAND_SUPPORT:ubi-utils +fstools +!BUILD_FACTORY_TEST_IMAGE:fwtool
  TITLE:=Base filesystem for OpenWrt
  URL:=http://openwrt.org/
  VERSION:=$(PKG_RELEASE)-$(REVISION)
endef

define Package/base-files/conffiles
/etc/config/
/etc/config/network
/etc/config/system
/etc/crontabs/
/etc/dropbear/
/etc/ethers
/etc/group
/etc/hosts
/etc/inittab
/etc/iproute2/rt_protos
/etc/iproute2/rt_tables
/etc/passwd
/etc/profile
/etc/profile.d
/etc/protocols
/etc/rc.local
/etc/services
/etc/shadow
/etc/shells
/etc/shinit
/etc/sysctl.conf
/etc/sysupgrade.conf
$(call $(TARGET)/conffiles)
endef

define Package/base-files/description
 This package contains a base filesystem and system scripts for OpenWrt.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Compile/Default

endef
Build/Compile = $(Build/Compile/Default)

ifeq ($(CONFIG_NAND_SUPPORT),)
  define Package/base-files/nand-support
	rm -f $(1)/lib/upgrade/nand.sh
  endef
endif

ifeq ($(CONFIG_EMMC_SUPPORT),)
  define Package/base-files/emmc-support
	rm -f $(1)/lib/upgrade/emmc.sh
  endef
endif

ifdef CONFIG_INSTALL_LOCAL_KEY
  define Package/base-files/install-local-key
	mkdir -p $(1)/etc/opkg/keys
	$(CP) $(BUILD_KEY).pub $(1)/etc/opkg/keys/`$(STAGING_DIR_HOST)/bin/usign \
		-F -p $(BUILD_KEY).pub`
  endef
endif

ifneq ($(CONFIG_USE_OPENRC),)
OPENRC_RUNLEVEL_DEFAULT:=adb rclocal done
OPENRC_RUNLEVEL_SHUTDOWN:=umount
endif

define Package/base-files/install
	$(CP) ./files/* $(1)/
	$(Package/base-files/install-local-key)
	$(Package/base-files/nand-support)
	$(Package/base-files/emmc-support)
	if [ -d $(GENERIC_PLATFORM_DIR)/base-files/. ]; then \
		$(CP) $(GENERIC_PLATFORM_DIR)/base-files/* $(1)/; \
	fi
	if [ -d $(PLATFORM_DIR)/base-files/. ]; then \
		$(CP) $(PLATFORM_DIR)/base-files/* $(1)/; \
	fi
	$(if $(filter-out $(PLATFORM_DIR),$(PLATFORM_SUBDIR)), \
		if [ -d $(PLATFORM_SUBDIR)/base-files/. ]; then \
			$(CP) $(PLATFORM_SUBDIR)/base-files/* $(1)/; \
		fi; \
	)

	$(VERSION_SED_SCRIPT) \
		$(1)/etc/openwrt_version \
		$(1)/usr/lib/os-release

	$(VERSION_SED_SCRIPT) \
		$(1)/etc/openwrt_release \
		$(1)/usr/lib/os-release

	$(SED) "s#%PATH%#$(TARGET_INIT_PATH)#g" \
		$(1)/sbin/hotplug-call \
		$(1)/etc/preinit \
		$(1)/etc/profile

	mkdir -p $(1)/CONTROL
	mkdir -p $(1)/dev
	mkdir -p $(1)/etc/config
	mkdir -p $(1)/etc/crontabs
	mkdir -p $(1)/etc/rc.d
	mkdir -p $(1)/overlay
	mkdir -p $(1)/lib/firmware
	$(if $(LIB_SUFFIX),-$(LN) lib $(1)/lib$(LIB_SUFFIX))
	mkdir -p $(1)/proc
	mkdir -p $(1)/tmp
	mkdir -p $(1)/usr/lib
	$(if $(LIB_SUFFIX),-$(LN) lib $(1)/usr/lib$(LIB_SUFFIX))
	mkdir -p $(1)/usr/bin
	mkdir -p $(1)/sys
	mkdir -p $(1)/www
	mkdir -p $(1)/rom/etc
	$(LN) /proc/mounts $(1)/etc/mtab
	rm -f $(1)/var
	$(LN) tmp $(1)/var
	$(LN) /var/run $(1)/run
	mkdir -p $(1)/etc
	$(if $(CONFIG_TARGET_x86_64), \
		mkdir -p $(1)/usr/local/log; \
		$(LN) /usr/local/log $(1)/overlay/log; \
		$(LN) overlay/log $(1)/log \
	, \
		mkdir -p $(1)/log \
	)
	mkdir -p $(1)/ext
	mkdir -p $(1)/usr/local/usr/lib
	mkdir -p $(1)/usr/local/mnt
	mkdir -p $(1)/usr/local/home/root
	$(LN) /etc $(1)/usr/local/etc
	$(LN) /usr/local/usr/lib $(1)/usr/local/lib
	$(LN) usr/local/mnt $(1)/mnt
	$(LN) usr/local/home $(1)/home
	$(LN) usr/local/home/root $(1)/root
	$(LN) /tmp/resolv.conf /tmp/TZ /tmp/localtime $(1)/etc/

	chmod 0770 $(1)/usr/local/home/root
	chmod 1777 $(1)/usr/local/mnt
	chmod 0640 $(1)/etc/shadow
	chmod 1777 $(1)/tmp
	chmod 0664 $(1)/etc/config/system
	chmod 0660 $(1)/etc/config/buttons

	$(call Package/base-files/install-target,$(1))
	for conffile in $(1)/etc/config/*; do \
		if [ -f "$$$$conffile" ]; then \
			grep "$$$${conffile##$(1)}" $(1)/CONTROL/conffiles || \
				echo "$$$${conffile##$(1)}" >> $(1)/CONTROL/conffiles; \
		fi \
	done

	$(if $(CONFIG_INCLUDE_CONFIG), \
		echo -e "# Build configuration for board $(BOARD)/$(SUBTARGET)/$(PROFILE)\n" >$(1)/etc/build.config; \
		cat $(BIN_DIR)/config.buildinfo >>$(1)/etc/build.config; \
		cat $(BIN_DIR)/feeds.buildinfo >>$(1)/etc/build.feeds; \
		cat $(BIN_DIR)/version.buildinfo >>$(1)/etc/build.version)

	$(if $(CONFIG_CLEAN_IPKG),, \
		mkdir -p $(1)/etc/opkg/openwrt; \
		$(call FeedSourcesAppend,$(1)/etc/opkg/openwrt/distfeeds.conf); \
		$(VERSION_SED_SCRIPT) $(1)/etc/opkg/openwrt/distfeeds.conf)

	# set target name
	$(SED) "s#%%NAME%%#$(TLT_PLATFORM_NAME)#g" \
		$(1)/etc/init.d/system

	# set lan ip
	$(SED) "s#%%LAN_IP%%#$(CONFIG_DEVICE_DEFAULT_IP)#g" $(1)/etc/board.d/1-board_json

	# add compile time timestamp
	date +%s > $(1)/etc/firmware-date

	# --prod / --gpl flags
	$(if $(CONFIG_PROD_IMAGE)$(CONFIG_GPL_BUILD),\
		$(RM) $(1)/etc/profile.d/rwrootfs.sh \
		$(1)/etc/init.d/memleak_watcher \
		$(1)/sbin/memleak_watcher \
	)

	if [ $(CONFIG_BUILD_FACTORY_TEST_IMAGE) ]; then \
		$(RM) $(1)/etc/rc.local $(1)/usr/libexec/login.sh; \
	fi;

	if [ ! $(CONFIG_SMP_SUPPORT) ]; then \
		$(RM) $(1)/lib/functions/smp.sh; \
	fi;

	$(if $(CONFIG_RESET_BUTTON_SUPPORT),, \
		$(RM) $(1)/etc/rc.button/reset $(1)/etc/config/buttons \
	)

	$(if $(CONFIG_BASEBAND_SUPPORT),,$(RM) $(1)/etc/init.d/adbd)

	for svc in $(1)/etc/init.d/*.openrc; do \
		$(if $(CONFIG_USE_OPENRC), \
			svc_name="$$$$(basename $$$${svc} .openrc)"; \
			runlevel="sysinit"; \
			echo "$(OPENRC_RUNLEVEL_DEFAULT)" | grep -q "$$$${svc_name}" && runlevel="default"; \
			echo "$(OPENRC_RUNLEVEL_SHUTDOWN)" | grep -q "$$$${svc_name}" && runlevel="shutdown"; \
			$(OPENRC_INSTALL) $$$${runlevel} $$$${svc_name} $$$${svc} $(1); \
		) \
		$(RM) $$$${svc}; \
	done
endef

ifneq ($(DUMP),1)
  -include $(PLATFORM_DIR)/base-files.mk
  -include $(PLATFORM_SUBDIR)/base-files.mk
endif

$(eval $(call BuildPackage,base-files))
