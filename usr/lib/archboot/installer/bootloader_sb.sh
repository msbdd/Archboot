#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# created by Tobias Powalowski <tpowa@archlinux.org>
_secureboot_keys() {
    _CN=""
    _MOK_PW=""
    _KEYDIR=""
    while [[ -z "${_KEYDIR}" ]]; do
        _dialog --title " Setup Keys " --no-cancel --inputbox "Enter the directory to store the keys on ${_DESTDIR}." 8 65 "/etc/secureboot/keys" 2>"${_ANSWER}" || return 1
        _KEYDIR=$(cat "${_ANSWER}")
        #shellcheck disable=SC2086,SC2001
        _KEYDIR="$(echo ${_KEYDIR} | sed -e 's#^/##g')"
    done
    if [[ ! -d "${_DESTDIR}/${_KEYDIR}" ]]; then
        while [[ -z "${_CN}" ]]; do
            _dialog --title " Setup Keys " --no-cancel --inputbox "Enter a common name(CN) for your keys, eg. Your Name" 8 65 "" 2>"${_ANSWER}" || return 1
            _CN=$(cat "${_ANSWER}")
        done
        secureboot-keys.sh -name="${_CN}" "${_DESTDIR}/${_KEYDIR}" &>"${_LOG}" || return 1
         _dialog --title " Setup Keys " --no-mouse --infobox "Common name(CN) ${_CN}\nused for your keys in ${_DESTDIR}/${_KEYDIR}" 4 60
         sleep 3
    else
         _dialog --title " Setup Keys " --no-mouse --infobox "-Directory ${_DESTDIR}/${_KEYDIR} exists\n-assuming keys are already created\n-trying to use existing keys now" 5 50
         sleep 3
    fi
}

_mok_sign () {
    _UEFI_BOOTLOADER_DIR="${_UEFISYS_MP}/EFI/BOOT"
    _INSTALL_MOK=""
    _MOK_PW=""
    while [[ -z "${_MOK_PW}" ]]; do
        _dialog --title " Machine Owner Key Password " --insecure --passwordbox "On reboot you will be asked for this password by mokmanager:" 8 65 2>"${_ANSWER}" || return 1
        _PASS=$(cat "${_ANSWER}")
        _dialog --title " Retype Machine Owner Key Password " --insecure --passwordbox "On reboot you will be asked for this password by mokmanager:" 8 65 2>"${_ANSWER}" || return 1
        _PASS2=$(cat "${_ANSWER}")
        if [[ "${_PASS}" == "${_PASS2}" && -n "${_PASS}" ]]; then
            _MOK_PW=${_PASS}
            echo "${_MOK_PW}" > /tmp/.password
            echo "${_MOK_PW}" >> /tmp/.password
            _MOK_PW=/tmp/.password
        else
            _dialog --title " ERROR " --no-mouse --infobox "Password didn't match or was empty, please enter again." 6 65
            sleep 3
        fi
    done
    mokutil -i "${_DESTDIR}"/"${_KEYDIR}"/MOK/MOK.cer < ${_MOK_PW} >"${_LOG}"
    rm /tmp/.password
    _dialog --title " Machine Owner Key " --no-mouse --infobox "Machine Owner Key has been installed successfully." 3 70
    sleep 3
    ${_NSPAWN} sbsign --key /"${_KEYDIR}"/MOK/MOK.key --cert /"${_KEYDIR}"/MOK/MOK.crt --output /boot/"${_VMLINUZ}" /boot/"${_VMLINUZ}" &>"${_LOG}"
    ${_NSPAWN} sbsign --key /"${_KEYDIR}"/MOK/MOK.key --cert /"${_KEYDIR}"/MOK/MOK.crt --output "${_UEFI_BOOTLOADER_DIR}"/grub"${_SPEC_UEFI_ARCH}".efi "${_UEFI_BOOTLOADER_DIR}"/grub"${_SPEC_UEFI_ARCH}".efi &>"${_LOG}"
    _dialog --title " Kernel And Bootloader Signing " --no-mouse --infobox "/boot/${_VMLINUZ} and ${_UEFI_BOOTLOADER_DIR}/grub${_SPEC_UEFI_ARCH}.efi\n\nhave been signed successfully." 5 60
    sleep 3
}
