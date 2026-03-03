DESCRIPTION = "Hotspot landingpage core files"
SECTION = "web/ui"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://src/template_parser.h;beginline=1;endline=17;md5=eab4dbbc01d8ce93693c7ce3a511c77e"

inherit useradd

USERADD_PACKAGES = "${PN}"
USERADD_PARAM:${PN} = "-u 610 -d /var/run/landingpage -r -s /bin/false landingpage"

DEPENDS = "lua5.1"

FILESEXTRAPATHS:prepend = "${THISDIR}:"
SRC_URI = " \
    file://src/ \
    file://files/ \
"

S = "${WORKDIR}"
B = "${S}/src"

TARGET_CFLAGS:append = " -I${STAGING_INCDIR}/lua5.1"

FILES:${PN} += "${libdir}/lua"
CONFFILES:${PN} += "/etc/config/landingpage"

RDEPENDS:${PN} += "lua5.1"

PACKAGE_ARCH = "${MACHINE_ARCH}"

do_install() {
    install -d "${D}${libdir}/lua/luci/template"
    install -m 0755 "${B}/parser.so" "${D}${libdir}/lua/luci/template/parser.so"

    cp -a --no-preserve=ownership "${S}/files/." "${D}/"

    chmod 0755 "${D}${sysconfdir}/chilli/hotspotlogin/cgi-bin/hotspot"
}

pkg_postinst:${PN}() {
    chown landingpage:landingpage "$D${sysconfdir}/config/landingpage"
}

pkg_postinst_ontarget:${PN}() {
    #!/bin/sh
    http_dis=\$(uci -q get uhttpd.hotspot.disabled)
    [ "\$http_dis" = "1" ] || /etc/init.d/uhttpd reload
    exit 0
}

pkg_postrm:${PN}() {
    #!/bin/sh
    http_dis=\$(uci -q get uhttpd.hotspot.disabled)
    if [ "\$http_dis" = "0" ]; then
        uci -q set uhttpd.hotspot.disabled=1
        uci -q commit uhttpd
        /etc/init.d/uhttpd reload
    fi
    exit 0
}
