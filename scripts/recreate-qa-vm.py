#!/usr/bin/env python3
"""Recrea exclusivamente black-ice-4-dev-qa a partir de una definición revisada."""
import argparse
import subprocess
import uuid
import xml.etree.ElementTree as ET
from pathlib import Path

NAME = "black-ice-4-dev-qa"


def run(*args):
    return subprocess.run(args, capture_output=True, text=True, check=True).stdout.strip()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--template", type=Path, required=True)
    parser.add_argument("--iso", type=Path, required=True)
    parser.add_argument("--work", type=Path, required=True)
    parser.add_argument("--width", type=int, required=True)
    parser.add_argument("--height", type=int, required=True)
    parser.add_argument("--confirm", required=True)
    args = parser.parse_args()
    if args.confirm != NAME or not 640 <= args.width <= 7680 or not 480 <= args.height <= 4320:
        parser.error("Confirmación o resolución inválidas")
    args.work.mkdir(parents=True, exist_ok=True, mode=0o700)
    root = ET.parse(args.template).getroot()
    if root.findtext("name") != NAME:
        parser.error("La plantilla no pertenece a la VM de QA")
    disk = Path(root.find("./devices/disk[@device='disk']/source").get("file"))
    expected = Path.home() / "KVM-Machines/BLACK-ICE-4-QA/system.qcow2"
    if disk != expected or disk.is_symlink() or not disk.is_file():
        parser.error("El disco no coincide con el recurso desechable autorizado")
    virsh = ["virsh", "-c", "qemu:///system"]
    if run(*virsh, "domstate", NAME) != "shut off":
        parser.error("Apaga limpiamente la VM antes de recrearla")
    iso = args.iso.resolve(strict=True)
    label = run("blkid", "-p", "-s", "LABEL", "-o", "value", str(iso))
    for name, member in (("vmlinuz-linux", "arch/boot/x86_64/vmlinuz-linux"), ("initramfs-linux.img", "arch/boot/x86_64/initramfs-linux.img")):
        with (args.work / name).open("wb") as stream:
            subprocess.run(["bsdtar", "-xOf", str(iso), member], stdout=stream, check=True)
    root.attrib.pop("id", None)
    root.find("uuid").text = str(uuid.uuid4())
    os_element = root.find("os")
    for element in list(os_element):
        if element.tag in {"boot", "kernel", "initrd", "cmdline"}:
            os_element.remove(element)
    ET.SubElement(os_element, "kernel").text = str(args.work / "vmlinuz-linux")
    ET.SubElement(os_element, "initrd").text = str(args.work / "initramfs-linux.img")
    ET.SubElement(os_element, "cmdline").text = f"archisobasedir=arch archisolabel={label} console=ttyS0,115200n8"
    cd = root.find("./devices/disk[@device='cdrom']")
    cd_source = cd.find("source")
    if cd_source is None:
        cd_source = ET.SubElement(cd, "source")
    cd_source.attrib.clear()
    cd_source.set("file", str(iso))
    model = root.find("./devices/video/model")
    resolution = model.find("resolution")
    if resolution is None:
        resolution = ET.SubElement(model, "resolution")
    resolution.set("x", str(args.width))
    resolution.set("y", str(args.height))
    root.find("./pm/suspend-to-mem").set("enabled", "no")
    root.find("./pm/suspend-to-disk").set("enabled", "no")
    for alias in root.findall(".//alias"):
        for parent in root.iter():
            if alias in list(parent):
                parent.remove(alias)
                break
    xml = args.work / "fresh-vm.xml"
    ET.ElementTree(root).write(xml, encoding="unicode")
    run("virt-xml-validate", str(xml))
    run(*virsh, "undefine", NAME, "--nvram", "--tpm")
    disk.unlink()
    run("qemu-img", "create", "-f", "qcow2", "-o", "lazy_refcounts=on", str(disk), "64G")
    run(*virsh, "define", str(xml))
    run(*virsh, "start", NAME)
    print(f"VM nueva: {NAME}; disco vacío 64 GiB; resolución {args.width}×{args.height}")


if __name__ == "__main__":
    main()
