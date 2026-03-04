SUMMARY = "Muse Pi Pro Linux Kernel"

inherit kernel
require recipes-kernel/linux/linux-yocto.inc

LINUX_KERNEL_TYPE = "custom"
LINUX_VERSION_EXTENSION:muse-pi-pro = "-muse-pi-pro"

DEPENDS:append:muse-pi-pro = " u-boot-tools-native"

LIC_FILES_CHKSUM:muse-pi-pro = "file://COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46"

BRANCH:muse-pi-pro = "k1-bl-v2.2.y"
SRCREV:muse-pi-pro = "0c505572f3e008843d6ca8fd13393c6e19d4a0b1"

LINUX_VERSION:muse-pi-pro = "6.6.63"
LINUX_VERSION_EXTENSION:append:muse-pi-pro = "-muse-pi-pro"

PV = "${LINUX_VERSION}+git${SRCPV}"

SRC_URI = "git://github.com/spacemit-com/linux-6.6;protocol=https;branch=${BRANCH}"
SRC_URI:append:muse-pi-pro = " \
                              file://muse-pi-pro.cfg \
                              file://0001-MUSE-Pi-Pro-disable-touchscreen-and-panel.patch \
                              "

INITRAMFS_IMAGE:muse-pi-pro = "core-image-minimal-initramfs"

KCONFIG_MODE = "alldefconfig"
KBUILD_DEFCONFIG:muse-pi-pro = "k1_defconfig"

KERNEL_FEATURES:remove:riscv32:muse-pi-pro = " ${KERNEL_FEATURES_RISCV}"
KERNEL_FEATURES:remove:riscv64:muse-pi-pro = " ${KERNEL_FEATURES_RISCV}"

do_install:append:muse-pi-pro() {
	sed -i -e 's#${S}##g' ${B}/drivers/tty/vt/consolemap_deftbl.c
}

do_deploy[depends] += "${INITRAMFS_IMAGE}:do_image_complete"

do_deploy:append:muse-pi-pro() {
	cd ${DEPLOY_DIR_IMAGE}
	mkimage -A riscv -O linux -T ramdisk -n "Initial Ram Disk" \
		-d ${INITRAMFS_IMAGE}-${MACHINE}.cpio.gz initramfs.img
}

COMPATIBLE_MACHINE = "(muse-pi-pro)"
