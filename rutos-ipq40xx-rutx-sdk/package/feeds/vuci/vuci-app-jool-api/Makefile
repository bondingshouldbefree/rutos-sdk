include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI API Support for the NAT64 (Jool)

APP_DEPENDS:=+jool

define Package/vuci-app-jool-api/prerm
  #!/bin/sh
  . /usr/share/libubox/jshn.sh
  . /lib/functions.sh

  id_array=""
  get_jool_rules() {
    local family
    local rule="$$1"
    config_get family "$$rule" "family"
    [ "$$family" = "ipv4" ] && {
      [ "$$id_array" = "" ] && id_array="\"$$rule\"" || id_array="$${id_array}, \"$${rule}\""
    }
  }

  config_load "firewall"
  config_foreach get_jool_rules "jool"

  [ "$$id_array" = "" ] && exit 0

  json_payload='{"data": ['$$id_array']}'

  api delete /jool/rules/config "$$json_payload" > /dev/null 2>&1

  exit 0
endef

include ../api.mk

# call BuildPackage - OpenWrt buildroot signature
