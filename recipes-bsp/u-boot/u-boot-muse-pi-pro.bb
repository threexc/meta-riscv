require recipes-bsp/u-boot/u-boot.inc
require recipes-bsp/u-boot/u-boot-common.inc

DEPENDS += "u-boot-tools-native"
DEPENDS:append:muse-pi-pro = " opensbi"

LIC_FILES_CHKSUM:muse-pi-pro = "file://Licenses/README;md5=2ca5f2c35c8cc335f0a19756634782f1"

BRANCH:muse-pi-pro = "k1-bl-v2.2.y"
SRCREV:muse-pi-pro = "d61c8c77e241314438dce31d9ff1b1cbd9d53688"

SRC_URI = "git://github.com/spacemit-com/uboot-2022.10;protocol=https;branch=${BRANCH}"

SRC_URI:append:muse-pi-pro = " \
                              file://boot.cmd \
			      file://env_k1-x.txt \
			      file://0001-spacemit-k1-x-spl-fix-relative-include.patch \
			      "

SRC_URI:remove:riscv32:muse-pi-pro = " ${SRC_URI_RISCV}"
SRC_URI:remove:riscv64:muse-pi-pro = " ${SRC_URI_RISCV}"

do_configure:prepend:muse-pi-pro() {
	mkimage -A riscv -O linux -T script -C none -n "U-Boot boot script" \
		-d ${UNPACKDIR}/${UBOOT_ENV}.${UBOOT_ENV_SRC_SUFFIX} ${UNPACKDIR}/${UBOOT_ENV_BINARY}
}

do_deploy:append:muse-pi-pro() {
        # bootinfo_sd.bin and bootinfo_emmc.bin are deployed by u-boot-spl-k1
        # Build U-Boot FDT FIT image
        mkdir -p ${B}/its
        mkdir -p ${B}/dtb
        for dtb in ${B}/arch/riscv/dts/*.dtb; do
                cp ${dtb} ${B}/dtb/
        done
        cp ${S}/board/spacemit/k1-x/configs/uboot_fdt.its ${B}/its/
        cd ${B}/its
        mkimage -f uboot_fdt.its -r u-boot-fdt.itb
        install -m 644 u-boot-fdt.itb ${DEPLOYDIR}/
	install -m 644 ${UNPACKDIR}/env_k1-x.txt ${DEPLOYDIR}/
}

do_deploy[depends] += "opensbi:do_deploy u-boot-spl-k1:do_deploy"

COMPATIBLE_MACHINE = "(muse-pi-pro)"
