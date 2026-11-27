# Add the SpacemiT K3 machine model (-machine spacemit-k3), which can boot the
# images built for the k3* MACHINEs (see conf/machine/include/k3-common.inc).
#
# 0001-0002: UFS sysbus frontend from QEMU master, needed by the K3 UFS model
# 0003-0010: the K3 series (v1 posted at
#   https://lore.kernel.org/qemu-riscv/20261124-spacemit_k3-v1-0-e911d6e88542@oss.tenstorrent.com/),
#   taken from the author's v2 work in progress
#   (https://github.com/asrinivasanTT/qemu/tree/b4/spacemit_k3) and backported
#   to 11.1.3
# 0011: report two UFS lanes, which Linux needs on K3 (not yet upstream)
#
# Drop these once the series lands in a QEMU release that OE-core picks up.

FILESEXTRAPATHS:prepend := "${THISDIR}/qemu-system-native:"

SRC_URI += " \
    file://0001-hw-ufs-Separate-the-controller-core-from-the-PCI-fro.patch \
    file://0002-hw-ufs-Add-a-generic-SysBus-frontend.patch \
    file://0003-target-riscv-Add-Spacemit-X100-CPU-type.patch \
    file://0004-hw-ufs-Add-Spacemit-K3-UFS-controller.patch \
    file://0005-hw-ssi-Add-Spacemit-K3-SPI-controller.patch \
    file://0006-hw-misc-Add-a-model-for-Spacemit-K3-syscons.patch \
    file://0007-riscv-Add-Spacemit-K3-machine.patch \
    file://0008-hw-riscv-spacemit-k3-Load-next-stage-from-boot-media.patch \
    file://0009-hw-riscv-spacemit-k3-SMP-support-for-Spacemit-K3-mac.patch \
    file://0010-docs-Document-spacemit-k3-machine.patch \
    file://0011-hw-ufs-Make-the-number-of-reported-lanes-configurabl.patch \
"
