#@TYPE: SOC
#@NAME: Spacemit K3
#@SOC: Spacemit K3
#@DESCRIPTION: SoC configuration for the Spacemit K3 - vendor repo version

DEFAULTTUNE ?= "spacemit-x100"
require conf/machine/include/riscv/rva23/tune-spacemit-x100.inc
require conf/machine/include/riscv-common.inc
require conf/machine/include/soc-family.inc

SOC_FAMILY = "k3"

# For now, these are needed by both mainline and vendor K3 BSPs
PREFERRED_PROVIDER_virtual/bootloader ?= "u-boot-k3"
PREFERRED_PROVIDER_opensbi ?= "opensbi-k3"

SERIAL_CONSOLES = "115200;ttyS0"

# Add esos-k3 firmware as image dependency
EXTRA_IMAGEDEPENDS += "esos-k3 u-boot-k3 u-boot-spl-spacemit"

# match the UFS storage block size
EXTRA_IMAGECMD:ext4 ?= "-i 4096 -b 4096"

UBOOT_MACHINE = "k3_defconfig"

KERNEL_IMAGETYPE = "Image"

# The uncompressed wic is for runqemu (see qemuboot options below)
IMAGE_FSTYPES = "ext4 wic wic.bmap wic.gz"
IMAGE_CLASSES += " k3-image"
INITRAMFS_FSTYPES = "cpio.gz"
WKS_FILE ?= "spacemit-k3.wks"
WKS_FILE_DEPENDS:append = " u-boot-k3"

MACHINE_FEATURES:append = " usbhost usbgadget"

MACHINE_EXTRA_RRECOMMENDS += "\
        linux-firmware-rtl8851 \
        linux-firmware-rtl8852 \
        linux-firmware-rtl8922 \
        "

# FIT kernel load address for linux-yocto-fitimage: where the vendor U-Boot's
# booti relocates an Image to, i.e. its ram_base (DRAM at 0x100000000 plus
# a 32 MiB secure region) plus the Image's 2 MiB text_offset. DRAM is above
# 4 GiB, so FIT addresses need two cells.
FIT_ADDRESS_CELLS = "2"
UBOOT_ENTRYPOINT ?= "0x00000001 0x02200000"

# qemuboot options, for "runqemu <machine> nographic" with the spacemit-k3
# QEMU machine (see recipes-devtools/qemu/qemu-system-native_*.bbappend).
#
# QEMU emulates the bootrom (no -bios needed) and runs FSBL -> OpenSBI ->
# U-Boot from the boot media, so no kernel is passed to QEMU directly.
# K3_QEMU_BOOT_MEDIA selects the layout; k3-image.bbclass adapts the raw .wic
# (which only exists for runqemu) to it:
#
#   nor-ufs: like the real boards: boot firmware on SPI NOR
#            (<image>.nor.bin), and the wic, rewritten for 4096-byte
#            sectors, on UFS
#   sd:      everything on the SD card, using the wic padded to a power-of-2
#            size. Needs a U-Boot device tree with SD enabled.
K3_QEMU_BOOT_MEDIA ??= "nor-ufs"

K3_QB_ROOTFS_OPT_nor-ufs = "-drive if=scsi,format=raw,file=@ROOTFS@"
K3_QB_OPT_APPEND_nor-ufs = "-drive if=mtd,format=raw,file=@DEPLOY_DIR_IMAGE@/${IMAGE_LINK_NAME}.nor.bin"
K3_QB_ROOTFS_OPT_sd = "-drive if=sd,index=0,format=raw,file=@ROOTFS@"
K3_QB_OPT_APPEND_sd = ""

IMAGE_CLASSES += "qemuboot"
QB_SYSTEM_NAME = "qemu-system-riscv64"
QB_MACHINE = "-machine spacemit-k3"
QB_CPU = ""
# The model requires exactly 8 harts; RAM matches its 16 GiB default
QB_SMP = "-smp 8"
QB_MEM = "-m 16384"
QB_DEFAULT_KERNEL = "none"
QB_DEFAULT_FSTYPE = "wic"
# Treat the wic as a plain disk so that QB_ROOTFS_OPT is used for it
QB_FSINFO = "wic:no-kernel-in-fs"
QB_ROOTFS_OPT = "${K3_QB_ROOTFS_OPT_${K3_QEMU_BOOT_MEDIA}}"
QB_OPT_APPEND = "${K3_QB_OPT_APPEND_${K3_QEMU_BOOT_MEDIA}}"
# No networking, PCI or virtio devices are modelled
QB_NET = "none"
QB_RNG = ""
