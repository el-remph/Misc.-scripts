#!/usr/bin/awk -f
# SPDX-FileCopyrightText:  2024 The Remph <lhr@disroot.org>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# takes input from xbps-install(1) -n. Tested on gawk, mawk, nawk, and
# busybox awk

BEGIN {
	units[0] = ""
	units[1] = "K"
	units[2] = "M"
	units[3] = "G"
	units[4] = "T"
	units[5] = "P"
	units[6] = "E"
	units[7] = "Z"
	units[8] = "R"
	units[9] = "Q"
	net_installed = 0
	total_download = 0

	OFS = "\t"
	if (!cachedir)
		cachedir = "/var/db/xbps"
}

function abs(n)
{
	return n < 0 ? -n : n
}

# printflags is optional
function humanise(size, printflags,	i)
{
	for (i = 0; abs(size) >= 2048.0 && i < 10; i++)
		size /= 1024.0
	return i ? sprintf("%"printflags".2f%s", size, units[i]) : size
}

function dehumanise(size,	i, n, unit)
{
	if (!match(size, /^[0-9]+(\.[0-9]+)?[BKMGTPEZRQ]/)) {
		print "Warning: malformed response from xbps-query(1):", size > "/dev/stderr"
		return
	}
	n	= substr(size, 1, RLENGTH)
	unit	= substr(size, RLENGTH, 1)
	if (unit == "B")
		return n
	for (i in units)
		if (units[i] == unit)
			return n * 1024 ^ i
}

# Performance bottleneck here, might benefit from async IO
function installsize_diff(pkg, action, size,	query, orig_size)
{
	if (action == "install")
		return size
	if (action == "remove")
		return -size

	# If we do this, we maybe lose when a package is reinstalled under
	# the same name and version, but with different contents of a
	# different size, such as during a build process. But such differences
	# would probably be swallowed by the rounding error that this branch
	# precludes anyway. Unfortunately xbps-query(1) insists on humanising
	if (action == "reinstall")
		return 0

	# else assume upgrade, or maybe downgrade?
	query = "xbps-query -p installed_size " pkg
	query | getline orig_size
	close(query)
	return size - dehumanise(orig_size)
}

function real_downloadsize(pkg_and_ver, arch, action, size)
{
	if (action == "remove")
		return 0
	# Oh this is not pretty
	if (system("test -e " cachedir "/" pkg_and_ver "." arch ".xbps") == 0)
		return 0
	return size
}

{
	if (!match($1, /-[0-9]+(\.[[:alnum:]]+)*(\+[0-9]+)?_[0-9]+$/))
		print "Warning: possibly malformed pkg name+ver:", $1 > "/dev/stderr"

	pkg = substr($1, 1, RSTART - 1)
	ver = substr($1, RSTART + 1)
	act = $2
	size_installed = installsize_diff(pkg, act, $5)
	size_download = real_downloadsize($1, $3, act, $6)

	net_installed += size_installed
	total_download += size_download
	size_installed = humanise(size_installed, "+")
	size_download = humanise(size_download)

	print pkg, ver, act, size_installed, size_download
}

END {
	print "Net installed:", humanise(net_installed, "+")
	print "Total download:", humanise(total_download)
}
