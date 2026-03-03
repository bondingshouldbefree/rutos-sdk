#
# Copyright (C) 2024 Teltonika-Networks
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=tlt-fsb

PKG_VERSION:=1.0.0
PKG_RELEASE:=2

PKG_LICENSE:=GPL-2.0-only
PKG_LICENSE_FILES:=LICENSES/GPL-2.0

include $(INCLUDE_DIR)/package.mk

define KernelPackage/tlt-fsb
  CATEGORY:=Kernel modules
  TITLE:=Teltonika Failsafe Boot handler
  FILES:=$(PKG_BUILD_DIR)/tlt_fsb.ko
  DEPENDS:=@TLT_FAILSAFE_BOOT
  SUBMENU:=Other modules
#  MODPARAMS.tlt_fsb:=
  AUTOLOAD:=$(call AutoLoad,90,tlt_fsb)
endef

# A more refined config might come later
#
define KernelPackage/tlt-fsb/config
config TLT_FAILSAFE_BOOT
	bool 
#	"Enable Teltonika failsafe boot"
	default n
	select PACKAGE_kmod-tlt-fsb
endef

define Build/Compile
	$(MAKE) -C "$(LINUX_DIR)" V=1 \
		CROSS_COMPILE="$(TARGET_CROSS)" \
		ARCH="$(LINUX_KARCH)" \
		M="$(PKG_BUILD_DIR)" \
		modules
endef

define KernelPackage/tlt-fsb/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/failsafeboot $(1)/etc/init.d/
	$(INSTALL_DIR) $(1)/lib/functions
	$(INSTALL_BIN) ./files/lib/functions/failsafeboot.sh $(1)/lib/functions
endef

$(eval $(call KernelPackage,tlt-fsb))

