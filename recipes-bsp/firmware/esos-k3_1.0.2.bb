SUMMARY = "K3 ESOS firmware (prebuilt)"
DESCRIPTION = "Prebuilt ESOS firmware (esos.itb) for K3 boot image, loaded by FSBL before U-Boot."
# The spacemit-firmware repository uses a simple copyright notice allowing use
# and redistribution of firmware binaries as-is and without modification, but
# it does not otherwise follow typical open-source licensing terms.
LICENSE = "CLOSED"

inherit deploy

COMPATIBLE_MACHINE = "(k3)"

BRANCH = "master"
SRC_URI = " \
    git://github.com/spacemit-com/spacemit-firmware.git;protocol=https;branch=${BRANCH} \
"

SRCREV = "5969642a5b46fee5ba7f21ca54c3129bff7bb049"

do_deploy() {
    install -d ${DEPLOYDIR}
    install -m 0644 ${S}/k3/k3-br-v${PV}/esos.itb ${DEPLOYDIR}/
}

addtask deploy after do_compile
