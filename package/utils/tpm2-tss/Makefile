include $(TOPDIR)/rules.mk

PKG_NAME:=tpm2-tss
PKG_VERSION:=4.1.3
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/tpm2-software/tpm2-tss.git
PKG_SOURCE_VERSION:=4.1.3
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_SOURCE_VERSION)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_SOURCE_SUBDIR).tar.gz
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_SOURCE_SUBDIR)

PKG_LICENSE:=BSD-2-Clause
PKG_LICENSE_FILES:=LICENSE

PKG_INSTALL:=1
PKG_FIXUP:=autoreconf

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  SUBMENU:=TPM2
  TITLE:=TPM2-TSS
  URL:=https://github.com/tpm2-software/tpm2-tss
  DEPENDS:= +libgcrypt +libcurl +libjson-c +libusb-1.0 +libuuid +libopenssl
endef

define Package/$(PKG_NAME)/description
OSS implementation of the TCG TPM2 Software Stack (TSS2)
endef

CONFIGURE_ARGS += \
	  --disable-doxygen-doc \
	  --disable-tcti-cmd \
	  --disable-tcti-libtpms \
	  --disable-tcti-mssim \
	  --disable-tcti-pcap \
	  --disable-tcti-spi-lt2go \
	  --disable-tcti-spi-ftdi \
	  --disable-tcti-swtpm

TARGET_CFLAGS += -DFALSE=0 -DTRUE=1

define Build/Prepare
$(call Build/Prepare/Default)
	( cd $(PKG_BUILD_DIR) ; \
		[ -f ./configure ] || { \
			PKG_VERSION=$(PKG_SOURCE_VERSION) \
			./bootstrap ; \
		} \
	)
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/tss2-mu/.libs/libtss2-mu.so* $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/tss2-fapi/.libs/libtss2-fapi.so* $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/tss2-sys/.libs/libtss2-sys.so* $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/tss2-policy/.libs/libtss2-policy.so* $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/tss2-rc/.libs/libtss2-rc.so* $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/tss2-esys/.libs/libtss2-esys.so* $(1)/usr/lib/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/tss2-tcti/.libs/libtss2-tcti-device.so* $(1)/usr/lib/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/tss2-tcti/.libs/libtss2-tctildr.so* $(1)/usr/lib/
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include
	$(CP) $(PKG_BUILD_DIR)/include/tss2 $(1)/usr/include/

	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/tss2-mu/.libs/libtss2-mu.so* $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/tss2-fapi/.libs/libtss2-fapi.so* $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/tss2-sys/.libs/libtss2-sys.so* $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/tss2-policy/.libs/libtss2-policy.so* $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/tss2-rc/.libs/libtss2-rc.so* $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/tss2-esys/.libs/libtss2-esys.so* $(1)/usr/lib/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/tss2-tcti/.libs/libtss2-tcti-device.so* $(1)/usr/lib/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/tss2-tcti/.libs/libtss2-tctildr.so* $(1)/usr/lib/
	$(INSTALL_DIR) $(1)/usr/lib/pkgconfig/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/*.pc $(1)/usr/lib/pkgconfig/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
