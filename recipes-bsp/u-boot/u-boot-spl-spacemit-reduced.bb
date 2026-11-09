SUMMARY = "Reduced SpacemiT K3 vendor U-Boot SPL"
DESCRIPTION = "U-Boot SPLs built from the SpacemiT K3 vendor BSP as described \
in the \"Guide to build reduced SpacemiT K3 vendor BSP\". They initialise DRAM \
and load u-boot.itb over serial YMODEM after being staged through BootROM USB \
download mode (FDL button), and cannot boot from NOR, SD or UFS on their own."
HOMEPAGE = "https://lore.kernel.org/u-boot/20261029003327.1890979-1-e@freeshell.de/"
SECTION = "bootloaders"
LICENSE = "GPL-2.0-or-later"
LIC_FILES_CHKSUM = "file://Licenses/README;md5=2ca5f2c35c8cc335f0a19756634782f1"

inherit deploy

DEPENDS += "flex-native bison-native python3-setuptools-native"

COMPATIBLE_MACHINE = "(k3-mainline)"

PV = "2022.10+git"

# The vendor tree builds the SPLs; mainline U-Boot only provides mkimage, as
# the vendor mkimage lacks the smtimage type used to package them.
SRC_URI = " \
    git://github.com/spacemit-com/uboot-2022.10.git;protocol=https;branch=k3-br-v1.0.y;name=vendor \
    git://git.u-boot-project.org/u-boot/u-boot.git;protocol=https;branch=main;name=mainline;destsuffix=mainline-u-boot \
    file://0001-Add-support-for-OpenSSL-Provider-API.patch \
    file://0001-reduced-SpacemiT-K3-vendor-BSP-use-MKIMAGE-build-env.patch \
    file://0002-reduced-SpacemiT-K3-vendor-BSP-add-guards-around-con.patch \
    file://0003-reduced-SpacemiT-K3-vendor-BSP-add-fallback-fastboot.patch \
    file://0004-reduced-SpacemiT-K3-vendor-BSP-force-UART-boot-when-.patch \
    file://0005-reduced-SpacemiT-K3-vendor-BSP-add-UART-SPI-defconfi.patch \
    file://0006-reduced-SpacemiT-K3-vendor-BSP-add-UART-no-SPI-defco.patch \
    file://0007-reduced-SpacemiT-K3-vendor-BSP-set-uart-compatible-f.patch \
    "

# k3-br-v1.0.10, the base of the guide's patches
SRCREV_vendor = "289dc2b7bd25bf9d88ce9e7e263e95234868ca14"
# Same revision as the mainline u-boot for k3-mainline machines
SRCREV_mainline = "03e45557e1f38a39a0c80fe30483130ff376cf92"
SRCREV_FORMAT = "vendor_mainline"

B = "${WORKDIR}/build"

UBOOT_SPL_REDUCED_CONFIGS = "uart_spi uart_nospi"

EXTRA_OEMAKE = "\
    CROSS_COMPILE=${TARGET_PREFIX} \
    ARCH=riscv \
    HOSTCC='${BUILD_CC} ${BUILD_CFLAGS} ${BUILD_LDFLAGS}' \
    HOSTCXX='${BUILD_CXX}' \
"

do_configure[noexec] = "1"

do_compile() {
    # Mainline mkimage, without libcrypto (signing), kwbimage (which selects
    # libcrypto) and mkeficapsule, none of which are needed for -T smtimage.
    mainline_make="${MAKE} -C ${UNPACKDIR}/mainline-u-boot O=${B}/mkimage HOSTCC='${BUILD_CC} ${BUILD_CFLAGS} ${BUILD_LDFLAGS}'"
    eval $mainline_make tools-only_defconfig
    sed -i -e 's/^CONFIG_TOOLS_LIBCRYPTO=.*/# CONFIG_TOOLS_LIBCRYPTO is not set/' \
           -e 's/^CONFIG_TOOLS_KWBIMAGE=.*/# CONFIG_TOOLS_KWBIMAGE is not set/' \
           -e 's/^CONFIG_TOOLS_MKEFICAPSULE=.*/# CONFIG_TOOLS_MKEFICAPSULE is not set/' \
           -e 's/^CONFIG_CMD_LICENSE=.*/# CONFIG_CMD_LICENSE is not set/' \
           ${B}/mkimage/.config
    eval $mainline_make olddefconfig
    eval $mainline_make ${PARALLEL_MAKE} NO_SDL=1 tools-only

    LIBGCC_PATH=$(${CC} ${CFLAGS} ${LDFLAGS} -print-libgcc-file-name)
    for cfg in ${UBOOT_SPL_REDUCED_CONFIGS}; do
        oe_runmake -C ${S} O=${B}/$cfg spacemit_k3_${cfg}_defconfig
        oe_runmake -C ${S} O=${B}/$cfg PLATFORM_LIBGCC="${LIBGCC_PATH}" \
            MKIMAGE=${B}/mkimage/tools/mkimage spl/u-boot-spl-mkimage.bin
    done
}

do_install[noexec] = "1"

do_deploy() {
    install -d ${DEPLOYDIR}
    for cfg in ${UBOOT_SPL_REDUCED_CONFIGS}; do
        install -m 644 ${B}/$cfg/spl/u-boot-spl-mkimage.bin \
            ${DEPLOYDIR}/u-boot-spl-mkimage-$(echo $cfg | tr _ -).bin
    done
}

addtask deploy before do_build after do_compile
