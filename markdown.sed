#!/bin/sed -Ef
# SPDX-FileCopyrightText:  2025 The Remph <lhr@disroot.org>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Basic markdown->html converter in sed. Others may have done it, I wouldn't
# know; this one is mine. Garbage in, garbage out. Also, sometimes you may
# just get garbage out anyway. Also also, this is about as safe as a saturday
# night special
#
# Surprisingly, some extensions are supported, like a class for a fenced pre
# block, and PHP Markdown Extra-style attributes on ATX-style headings
#
# [TODO] nest things in the blockquotes
# [TODO] automatic reference headers
# I don't think levels of nested lists is happening

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
s/^\n//
/./!d

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

# (un)ordered lists are practically inline, and if we process them first then
# asterisk <ul>s shouldn't conflict with <em>. [TODO] Make the ^ into (^|\n)
# and let them actually be inline
/^[-*]/{
	# noop branch to reset t state
	bul
	:ul
	s|^([-*])(.*)(\n\1)\s*|\1\2</li>\n<li>|
	tul
	s/^[-*]\s*/<ul><li>/
	s|$|</li></ul>|
}
/^[0-9]+[).]/ {
	s|\n[0-9]+[).]\s*|</li>\n<li>|g
	s/^[0-9]+[).]\s*/<ol><li>/
	s|$|</li></ol>|
}

# Inline elements (nesting of `code` with others is janky)
# (^|[^\\]) is a non-PCRE equivalent of (?<!\\), as long as you remember to
# include its backreference into the replacement
# Likewise X([^X]*[^X\\])X selects a region bracketed by Xs, like
# X(.+?)(?<!\\)X, and is best preceded by the former pattern
s;(^|[^\\])\*\*([^*]*[^*\\])\*\*;\1<strong>\2</strong>;g
s;(^|[^\\])\*([^*]*[^*\\])\*;\1<em>\2</em>;g
s;(^|[^\\])\b_([^_]*[^_\\])_\b;\1<em>\2</em>;g
s;(^|[^\\])`([^`]*[^`\\])`;\1<code>\2</code>;g
# egads! [FIXME] still no images in links
s;(^|[^\\])!\[([^]]*[^]\\])?\]\(([^)]*[^)\\])\);\1<img alt="\2" src="\3" />;g
s;(^|[^\\])\[([^]]*[^]\\])\]\(([^)]*[^)\\])\);\1<a href="\3">\2</a>;g

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
	s/^#{6}\s*/<h6>/
	s/^#{5}\s*/<h5>/
	s/^#{4}\s*/<h4>/
	s/^#{3}\s*/<h3>/
	s/^#{2}\s*/<h2>/
	s/^#{1}\s*/<h1>/
	s/\s*#*\s*\{((\s*([#.][[:alnum:]_-]+|[[:alnum:]_-]+=([[:alnum:]_-]+|"[^"]*")))*)\}\s*$/\n\1/
	/\n/ {
		# oh god, oh man
		bh_id
		:h_id
		s|^<(h[0-9])([^>]*)>(.*\n.*)#([[:alnum:]_-]+)|<\1\2 id="\4">\3|
		th_id
		# [TODO] not how class attributes work
		:h_class
		s|^<(h[0-9])([^>]*)>(.*\n.*)\.([[:alnum:]_-]+)|<\1\2 class="\4">\3|
		th_class
		:h_kv
		s;^<(h[0-9])([^>]*)>(.*\n.*).([[:alnum:]_-]+=([[:alnum:]_-]+|"[^"]*"));<\1\2 \4>\3;
		th_kv
		# Now properly quote values in kv
		:h_qkv
		s|^(<h[0-9] [^>]*)(\s[[:alnum:]_-]+=)([^>"])|\1\2"\3"|
		th_qkv
	}
	s/\s*$//
	s|^<(h[0-9]).*|&</\1>|
	b
}

/^>/ {
	s/(^|\n)>/\1/g
	i\
<blockquote>
	a\
</blockquote>
	b
}

# else
i\
<p>
a\
</p>
