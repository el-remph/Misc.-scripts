#!/bin/sh
# SPDX-FileCopyrightText:  2024 The Remph <lhr@disroot.org>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Depends: POSIX sh, pacman (obviously), expac, GNU awk

set ${BASH_VERSION+ -o pipefail} -efmu -- $(pacman -Sp --print-format '%r/%n' --needed -- "$@")
if test $# -gt 0; then
	expac -S '%m\t%n' -- $@ | gawk '
BEGIN {
	OFS = FS = "\t"
	total = 0
	PROCINFO["sorted_in"] = "@val_num_desc"

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

{
	total += $1
	sizes[NR] = $1
	packages[NR] = $2
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

END {
	for (i in sizes)
		print byte_prefix(sizes[i]), packages[i]
	print byte_prefix(total), "Total"
}'
fi
