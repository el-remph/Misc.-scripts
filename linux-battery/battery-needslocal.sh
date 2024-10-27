#!/bin/sh
# SPDX-FileCopyrightText:  2023-2024 The Remph <lhr@disroot.org>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Dependencies:
#	POSIX: sh, printf (probably a builtin), cat (probably not)
#	non-POSIX: `local' builtin, which is permitted but not mandated by POSIX

# set IFS to facilitate word-splitting correctly parsing $battery_uevent contents
IFS='
'

print_battery() {
	local $(cat "$1")	# word splitting allowed
	if [ "$POWER_SUPPLY_TYPE" = Battery ]; then
		printf '%s:\t%d%%\t%s\n' "$POWER_SUPPLY_NAME" "$POWER_SUPPLY_CAPACITY" "$POWER_SUPPLY_STATUS"
	fi
}

for battery_uevent in /sys/class/power_supply/*/uevent; do
	print_battery "$battery_uevent"
done
