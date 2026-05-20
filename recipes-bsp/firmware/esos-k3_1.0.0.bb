SUMMARY = "K3 ESOS firmware (prebuilt)"
DESCRIPTION = "Prebuilt ESOS firmware for K3: rt24 RCPU .elf files and esos.itb boot image. \
The .elf files are loaded by the kernel from /lib/firmware, and esos.itb is loaded by FSBL before U-Boot."
LICENSE = "CLOSED"

inherit deploy

COMPATIBLE_MACHINE = "(k3)"

SRC_URI = " \
    file://rt24_os0_rcpu.elf \
    file://rt24_os1_rcpu.elf \
    file://esos.itb \
"

S = "${UNPACKDIR}"

do_install() {
    install -d ${D}${nonarch_base_libdir}/firmware
    install -m 0644 ${UNPACKDIR}/rt24_os0_rcpu.elf ${D}${nonarch_base_libdir}/firmware/
    install -m 0644 ${UNPACKDIR}/rt24_os1_rcpu.elf ${D}${nonarch_base_libdir}/firmware/
}

do_deploy() {
    install -d ${DEPLOYDIR}
    install -m 0644 ${UNPACKDIR}/esos.itb ${DEPLOYDIR}/
}

addtask deploy after do_install

FILES:${PN} = "${nonarch_base_libdir}/firmware"

INSANE_SKIP:${PN} = "arch already-stripped buildpaths"
