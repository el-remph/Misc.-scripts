#!/usr/bin/gawk -f
# SPDX-FileCopyrightText:  2024 The Remph <lhr@disroot.org>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Transforms python memory-profiler output *.dat files into a gnuplot
# graph, eg.
#	mprof2gnuplot.awk *.dat | gnuplot -e 'set format svg; set output "plot.svg"' -
#
# Depends on gawk, as it uses BEGINFILE, FILENAME and ENDFILE rules. Like
# most AWK scripts, garbage in -> garbage out.

BEGIN {
	print "\
set style data linespoints\n\
set multiplot\n\
set xlabel 'time elapsed (seconds)'\n\
set ylabel 'memory (MiB)'\n\
set grid\n"
	file_i = 1
	OFS = "\t"
}

BEGINFILE {
	sanitised[file_i] = FILENAME
	gsub(/\W/, "_", sanitised[file_i])
	print "$"sanitised[file_i]" << EOF"

	file_i++
	starttime = 0
}

$1 == "MEM" {
	# Maybe I should learn how to use gnuplot `time'
	tim = $3
	if (starttime)
		tim -= starttime
	else {
		starttime = tim
		tim = 0
	}

	print tim, $2
}

ENDFILE {
	print "EOF\n"
}

END {
	ORS = ""
	print "plot"
	for (i = 1; i < ARGC; i++) {
		if (i > 1)
			print ","
		print " $"sanitised[i]" title '"ARGV[i]"'"
	}
	print "\n\nunset multiplot\n"
}
