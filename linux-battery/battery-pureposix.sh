#!/bin/sh
# SPDX-FileCopyrightText:  2023-2024 The Remph <lhr@disroot.org>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Dependencies: POSIX: sh, printf (probably a builtin), cat (probably not)

cd /sys/class/power_supply || exit
for capacity in */capacity; do
	battery_dir=${capacity%/capacity}
	printf '%s:\t%d%%\t%s\n' "${battery_dir##*/}" $(cat "$capacity" "$battery_dir/status")
done
