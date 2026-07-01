SUMMARY = "Mainline Linux Kernel for SpacemiT K1 boards"

require recipes-kernel/linux/linux-mainline-common.inc

DEPENDS += "u-boot-tools-native"

BRANCH = "master"
SRC_URI = "git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git;protocol=https;branch=${BRANCH} \
           file://misc.cfg \
           file://k1-i2c.cfg \
          "

SRC_URI:append:bananapi-cm6-io = " \
           file://0001-dt-bindings-riscv-spacemit-Add-Banana-Pi-BPI-CM6-com.patch \
           file://0002-riscv-dts-spacemit-k1-Split-gmac_clk_ref-into-indepe.patch \
           file://0003-riscv-dts-spacemit-k1-Add-Banana-Pi-BPI-CM6-IO-board.patch \
          "

SRCREV = "dc59e4fea9d83f03bad6bddf3fa2e52491777482"
LINUX_VERSION = "7.2-rc1"

COMPATIBLE_MACHINE = "(k1)"
