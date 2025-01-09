#!/bin/sh
set ${BASH_VERSION:+ -o pipefail} -e

sep_str='~*~*~' # very unlikely or impractical to appear in argv

have() {
	command -v "$@"  >/dev/null 2>&1
}

if have wget2; then
	dl_cmd='wget2 -O -'
elif have wget; then
	dl_cmd='wget -O -'
else
	dl_cmd='curl -L'
fi

readonly sep_str dl_cmd

set -- "$@" "$sep_str"

while [ "$1" != "$sep_str" ]; do
	set -- "$@" "https://gnu.org/s/$1/manual/$1.info.tar.gz"
	shift
done
shift # lose sep_str

# It may be wise not to use tar's z option instead of gzip, since
# gzip can handle concatenated gzip streams and I'm not sure about
# tar
$dl_cmd -- "$@" | gzip -dc | tar xvf -
