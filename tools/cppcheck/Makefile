include $(TOPDIR)/rules.mk

PKG_NAME:=cppcheck
PKG_VERSION:=2.17.1

PKG_SOURCE_URL:=https://github.com/danmar/cppcheck.git
PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=$(PKG_VERSION)
PKG_MIRROR_HASH:=715ea1309c71f21ca35f40f99cfb53c9122f690582ad63d56ce25297f0688398

HOST_BUILD_PARALLEL:=1
HOST_BUILD_DIR:=$(BUILD_DIR_HOST)/$(PKG_NAME)-$(PKG_VERSION)

PKG_LICENSE:=GPL-3.0-or-later
PKG_LICENSE_FILES:=COPYING

include $(INCLUDE_DIR)/host-build.mk
include $(INCLUDE_DIR)/gpl.mk

HOSTCC := $(HOSTCC_NOCACHE)

HOST_MAKE_FLAGS += FILESDIR=$(if $(EXT_STAGING_DIR),$(EXT_STAGING_DIR)/host,$(STAGING_DIR_HOST))/share/cppcheck/

define Host/Install
	$(INSTALL_DIR) $(STAGING_DIR_HOST)/share/cppcheck $(STAGING_DIR_HOST)/bin
	$(INSTALL_BIN) $(HOST_BUILD_DIR)/cppcheck $(STAGING_DIR_HOST)/bin/
	$(CP) $(HOST_BUILD_DIR)/addons $(STAGING_DIR_HOST)/share/cppcheck/addons
	$(CP) $(HOST_BUILD_DIR)/cfg $(STAGING_DIR_HOST)/share/cppcheck/cfg
	$(CP) $(HOST_BUILD_DIR)/platforms $(STAGING_DIR_HOST)/share/cppcheck/platforms
endef

define Host/Clean
	$(RM) -f $(STAGING_DIR_HOST)/bin/cppcheck
	$(RM) -rf $(STAGING_DIR_HOST)/share/cppcheck
endef

$(eval $(call HostBuild))
