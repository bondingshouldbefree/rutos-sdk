DESCRIPTION = "Lua bindings for various regex libraries"
SECTION = "libs"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=ecf009fedc06b09acee8c29ea6f075fc"

DEPENDS = "lua5.1 libpcre2"

FILESEXTRAPATHS:append := "${THISDIR}:"

SRC_URI = "\
    file://src/ \
"

SRC_URI += "\
    file://001-link-with-lua51.patch \
    file://002-pass-ldflags.patch \
    file://003-drop-includes.patch \
"

S = "${WORKDIR}/src"
B = "${S}"

TARGET_CFLAGS:append = " -I${STAGING_INCDIR}/lua5.1"

# include files under /usr/lib/lua
FILES:${PN} += "${libdir}/lua"

do_install() {
    mkdir -p "${D}${libdir}/lua"
    install -Dm 0644 "${B}/rex_pcre2.so" "${D}${libdir}/lua"
}
