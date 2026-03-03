include $(TOPDIR)/rules.mk

PKG_NAME:=grpcurl
PKG_VERSION:=1.9.3
PKG_RELEASE:=1

PKG_HASH:=skip

PKG_SOURCE_VERSION:=$(PKG_VERSION)
PKG_SOURCE:=$(PKG_NAME)-$(PKG_SOURCE_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/fullstorydev/$(PKG_NAME)/archive/refs/tags/v$(PKG_SOURCE_VERSION)

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
PKG_BUILD_FLAGS:=no-mips16

GO_PKG:=github.com/fullstorydev/grpcurl
GO_PKG_BUILD_PKG:=github.com/fullstorydev/grpcurl/cmd/grpcurl

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/package/lang/golang/golang-package.mk

define Package/grpcurl
  SECTION:=net
  CATEGORY:=Network
  TITLE:=grpcurl
  URL:=https://github.com/fullstorydev/grpcurl
  DEPENDS:=$(GO_ARCH_DEPENDS)
endef

define Package/grpcurl/description
  grpcurl is a command-line tool that lets you interact with gRPC servers.
endef

define Package/grpcurl/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(GO_PKG_BUILD_BIN_DIR)/grpcurl $(1)/usr/sbin/
endef

$(eval $(call BuildPackage,grpcurl))
