#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# created by Tobias Powalowski <tpowa@archlinux.org>
rsync --delete --delete-before -L -a archboot.com:pkg ~/public_html/
rsync --delete --delete-before -L -a archboot.com:release ~/public_html/
for i in aarch64 riscv64 x86_64; do
    cd ~/public_html/release/${i}/ || exit 1
    _DIR="$(echo */ | sed -e 's#.* ##g')"
    ln -s "${_DIR}" latest
done
