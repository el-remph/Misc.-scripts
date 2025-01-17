#!/bin/sed -Ef
# SPDX-FileCopyrightText:  2025 The Remph <lhr@disroot.org>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Basic markdown->html converter in sed. Others may have done it, I wouldn't
# know; this one is mine. Garbage in, garbage out. Also, sometimes you may
# just get garbage out anyway.
# [TODO] ordered and unordered lists

# Handle fenced pre first, since it isn't like other paragraph-delimited formatting
s/^```[[:blank:]]*([[:alnum:]_]+)$/<pre class="\1">/
s/^```$/<pre>/
# Enter fence via gate
tgate
# else
bloop
:cont_fence
s/&/\&amp;/g
s/</\&lt;/g
s/>/\&gt;/g
:gate
p
s/.*//
$! {
	N
	s/^\n//
	/^```$/!bcont_fence
}
s|^```$|</pre>|
t
a\
</pre>
b

# Accumulate a paragraph
:loop
$! {
	N
	s/\n$//
	Tloop
}

# Catch preformatted blocks early, before they go through any formatting
/^(\t|    )/ {
	s;(^|\n)(\t|    );\1;g
	s/&/\&amp;/g
	s/</\&lt;/g
	s/>/\&gt;/g
	i\
<pre>
	a\
</pre>
	b
}

# Inline elements (nesting of `code` with others is janky)
# (^|[^\\]) is a non-PCRE equivalent of (?<!\\), as long as you remember to
# include its backreference into the replacement
# Likewise X([^X]*[^X\\])X selects a region bracketed by Xs, like
# X(.+?)(?<!\\)X, and is best preceded by the former pattern
s;(^|[^\\])\*\*([^*]*[^*\\])\*\*;\1<strong>\2</strong>;g
s;(^|[^\\])\*([^*]*[^*\\])\*;\1<em>\2</em>;g
s;(^|[^\\])`([^`]*[^`\\])`;\1<code>\2</code>;g
# egads! [FIXME] still no images in links
s;(^|[^\\])\[([^]!][^]]*[^]\\]|[^]!\\])\]\(([^)]*[^)\\])\);\1<a href="\3">\2</a>;g
s;(^|[^\\])\[!([^]]*[^]\\])\]\(([^)]*[^)\\])\);\1<img alt="\3" src="\2" />;g

# Literal links
s;<((\w+:/{,2})?([[:alnum:]_-]+@)?([[:alnum:]_-]+\.)+[[:alnum:]_-]+(/[^>]*)?)>;<a href="\1">\1</a>;g

# Entities ([TODO] what about &lt;, &gt;, and &amp;?)
s/(^|\s)--(\s|$)/\1\&ndash;\2/g
s/(^|[[:alnum:]_\n])---([[:alnum:]_\n]|$)/\1\&mdash;\2/g

# Determine block type

# Repetition here, a tragic necessity
/\n={3,}$/ {
	s/\n={3,}$//
	i\
<h1>
	a\
</h1>
	b
}
/\n-{3,}$/ {
	s/\n-{3,}$//
	i\
<h2>
	a\
</h2>
	b
}

# Oh no
/^#[^\n]*$/ {
	# Against the standard (which standard?) this requires header lines to
	# end with the same number of hashes they begin with, or none at all
	s|^(#{5})\s*(.*)\s*\1?$|<h5>\2</h5>|
	s|^(#{4})\s*(.*)\s*\1?$|<h4>\2</h4>|
	s|^(#{3})\s*(.*)\s*\1?$|<h3>\2</h3>|
	s|^(#{2})\s*(.*)\s*\1?$|<h2>\2</h2>|
	s|^(#{1})\s*(.*)\s*\1?$|<h1>\2</h1>|
	b
}

# else
i\
<p>
a\
</p>
