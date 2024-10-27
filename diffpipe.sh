#!/bin/sh
# SPDX-FileCopyrightText:  2023-2024 The Remph <lhr@disroot.org>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# In true POSIX shellscript, with a little help from mktemp(1) and mkfifo(1p)
# Example: diffpipe -U 2 foo.gz bar.gz zcat

# Really ugly option parsing, just to make sure we don't lose option
# arguments of the form `-o ARG' rather than `-oARG'. Long option arguments
# of the form `--option ARG' are not handled; use `--option=ARG' instead
sep=':://:://::' # separator very unlikely to be a real argument
set -efm -- "$@" "$sep"
while getopts 'qscC:uU:enyW:pF:tTlrNx:X:S:iEZbwBI:aD:d-:' o; do
	set -- "$@" "-$o$OPTARG"
done
set -u # OPTARG may be unbound, but hereafter unbound variables are errors
shift $(( OPTIND - 1 ))

die() {
	echo >&2 "$0: $*"
	exit -1
}

# Now parse positional parameters
i=0 a= b= xformer=
while test "$1" != "$sep"; do
	case $(( i++ )) in
	0)	a=$1 ;;
	1)	b=$1 ;;
	2)	xformer=$1 ;;
	3)	die 'Too many arguments' ;;
	*)	die 'panic!' ;;
	esac
	shift
done
test $i -eq 3 || die "expected 3 arguments, got $i"
shift	# lose $sep


## Main ##

oldpwd=$PWD

xform() (
	case $1 in
	-)	;;	# read from stdin, which is the default so noop
	/*)	exec <$1 ;;
	*)	exec <$oldpwd/$1 ;;	# Poor man's logical realpath -- even works for ./* and ../*
	esac
	eval exec "$xformer" >./$1
)

tmpd=`mktemp -d`
trap 'cd /; rm -r "$tmpd"' 0 # cd / because I think / is always guaranteed to be a readable dir
cd "$tmpd"

for i in "$a" "$b"; do
	case $i in
	*?/*)	mkdir -p "./${i%/*}" ;;
	esac
done

mkfifo -m600 "./$a" "./$b"
xform "$a" &
xform "$b" &
diff --color "$@" -- "./$a" "./$b"
