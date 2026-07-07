require u-boot-spl-spacemit.inc

BRANCH ?= "k3-br-v1.0.y"
SRC_URI = "git://github.com/spacemit-com/uboot-2022.10.git;protocol=https;branch=${BRANCH}"
SRCREV ?= "6747f87ae4cd359ff6e22daa38b06c3ecc2fecb4"

UBOOT_SPL_MACHINE ?= "k3_defconfig"

COMPATIBLE_MACHINE = "(k3)"

do_deploy:append() {
	install -m 644 ${B}/bootinfo_block.bin ${DEPLOYDIR}/
}
