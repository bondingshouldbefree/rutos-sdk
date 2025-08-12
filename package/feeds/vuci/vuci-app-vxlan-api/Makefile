include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI API Support for VXLAN

APP_DEPENDS=+kmod-vxlan +vuci-app-network-devices-api

define Package/vuci-app-vxlan-api/prerm
  #!/bin/sh
  . /usr/share/libubox/jshn.sh
  . /lib/functions.sh

  id_array=""
  get_vxlans() {
    local type
    local device="$$1"
    config_get type "$$device" "type"
    [ "$$type" = "vxlan" ] && {
      [ "$$id_array" = "" ] && id_array="\"$$device\"" || id_array="$${id_array}, \"$${device}\""
    }
  }

  config_load "network"
  config_foreach get_vxlans "device"

  [ "$$id_array" = "" ] && exit 0  
                                
  json_payload='{"data": ['$$id_array']}'         
                                        
  api delete /network/devices/vxlan/config "$$json_payload" > /dev/null 2>&1

  exit 0
endef

include ../api.mk

# call BuildPackage - OpenWrt buildroot signature
