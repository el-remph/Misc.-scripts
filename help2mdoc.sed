#!/bin/sed -Enf
# SPDX-FileCopyrightText:  2025 The Remph <lhr@disroot.org>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This is a really dodgy script in the same vein as GNU help2man, but
# targeting mdoc(7) (see also groff_mdoc(7)) instead of generic man(7) (or
# groff_man(7)). At present it only does the OPTIONS/DESCRIPTION section,
# so is best used as part of a manpage.1.in template. Or not at all
#
# Depends mostly on POSIX sed, though some GNU extensions may have snuck in

#1e date ".Dd %Y-%m-%d"

:start

1i\
.Bl -tag -width indent

# Option and argument are prepended to pattern space, separated by vertical
# tabs (so please don't have vtabs in your --help output:). This makes for
# a way of having multiple variables in sed, instead of one big pattern space;
# they can be compared using backreferences
s/^\s+(--?[^-[:space:]]+(, *)?)+((\[)?[= ](\w+)\]?)?(\t|$)/.It Fl \1 \4\5\n\1\v\5\v\6/
#     ^Option            ^comma  ^Argument
tmatch
d
:match

h
# Save post-option stuff
s/.*\n//
x
# Focus on option+arg
s/\n.*//

# Trailing space means \4\5 was nothing, so noarg
/ $/ {
	s/ $//
	b noarg
}

s/\w+$/Ar &/
s/ \[/ Op /

: noarg
s/(\s)-/\1/g
s/,/ ,/g
s/\n$//

# Print option+arg; now, the post-option stuff
p
x

# If multiple options were specified, separate them
/.*,.*\v/ {
	h
	# Isolate options
	s/\v.*\v.*/\v/
	# Separate options
	s/\s*,\s*/\v/g
	# Prepend them, replacing where they were
	x
	s/\v.*//
	x
	G
	s/\n//
}

# Accumulate lines...
:opt_desc_nextline
$bend
N
# ...until we find a line that either is not indentated, or is a new option
# description
/.*\n\t[[:blank:]]*[^-\n][^\n]*$/bopt_desc_nextline

:end
# Begin the same shuffle as before; used to print all lines except the one
# that ended the above loop
h
s/\n[^\n]*$//

# In the mix, we also mark all instances of any arg
/^\v/! {
	:mark_args
	# Oh my god the horror. No lookbehinds, and \b doesn't work right. .XX
	# is a placeholder directive
	s/(\v|^)([^\v]+)\v([^\n]*\n?|.*\n[^.]([^\n]*\W)?)\2(\W|$)/\1\2\v\3\n.Xx \2\n\5/
	#       ^Opt/Arg   ^Line 1   ^Other lines        ^Opt/Arg
	tmark_args
	# Remove placeholders: differentiate flags from optargs
	# If the last vtab-separated field is nonempty, then opt should take an arg
	/\v\v[^\v]*$/!s/(\n\.)Xx -([^\n]*)\n\s*(\w+)\s*/\1Fl \2 Ar \3\n/g
	s/(\n\.)Xx -/\1Fl /g
	s/(\n\.)Xx/\1Ar/g
}

# Remove leading whitespace
s/(^|[\n\v])[[:blank:]]*/\1/g
# Lose preset arg
s/^.*\v//

# Complete the shuffle
p
x
# This is a awkward way of restarting with the line that ended the loop, as
# long as the N command worked ($ doesn't work we get to $ with previous
# lines still in pattern space). In the spirit of D, but removing all leading
# lines rather than just one, so like a big D
/\n/ {
	s/.*\n//
	bstart
}
