#!/bin/sh
# SPDX-FileCopyrightText:  2024 The Remph <lhr@disroot.org>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Depends: POSIX sh, pacman (obviously), expac, POSIX awk (tested on GNU and
# BWK awks), non-POSIX sort with -h option for human-readable numbers (fairly
# common)

set ${BASH_VERSION+ -o pipefail} -efu -- $(pacman -Sp --print-format '%r/%n' --needed -- "$@")
if test $# -gt 0; then
	expac -S '%m\t%n' -- $@ | awk '
BEGIN {
	OFS = FS = "\t"
	total = 0

	# Metric prefixes (prefices?)
	unit[10]  = "K"
	unit[20]  = "M"
	unit[30]  = "G"
	unit[40]  = "T"
	unit[50]  = "P"
	unit[60]  = "E"
	unit[70]  = "Z"
	unit[80]  = "Y"
	unit[90]  = "R"
	unit[100] = "Q"
}

function byte_prefix(bytes,	threshold, i)
{
	for (i = 100; i; i -= 10) {
		threshold = 2 ^ i
		if (bytes >= threshold)
			return sprintf("%.2f%s", bytes / threshold, unit[i])
	}
	# default
	return bytes
}

{
	total += $1
	print byte_prefix($1), $2 | "sort -h"
}

END {
	close("sort -h")
	print byte_prefix(total), "Total"
}'
fi
