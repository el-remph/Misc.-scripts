#!/bin/sed -Enf
# SPDX-FileCopyrightText:  2025 The Remph <lhr@disroot.org>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Wrote this to push selected countries to the top of the mirrorlist and use
# them. Not sure what was wrong with rankmirrors(1). Saving this so I can
# maintain my existing /etc/pacman.d/mirrorlist-arch (on Artix) and because
# I love sed. When things are bad, which they are, I write a sed script and
# it makes things feel better again like nothing else can. sed doesn't just
# solve sysadmin problems or packaging problems: sed solves *your* problems.

# As an extra bonus, trim out unsecured HTTP
\|^#*Server = http://|d

# For first paragraph
1,/^$/ {
	# At end (after it has been held)
	/^$/ {
		# Get hold space
		x
		# Unless it contains any non-comment lines,
		/\n[^#]/! {
			# Lose extraneous leading newline
			s/^\n//
			# Print hold space
			p
			# Erase hold space
			s/.*//
			x
			# Add a bit (including current empty line)
			a\
## Messed around by handhack-rankmirrors.sed\
##\

			# Continue
			bend
		}
		# else, put hold/pattern space back and pretend it never happened
		x
	}
}

# Anything here gets uncommented and printed first
/^## (Austria|Belarus|Belgium|Czechia|Denmark|Estonia|Finland|France|Georgia|Germany|Greece|Ireland|Italy|Luxembourg|Monaco|Netherlands|Norway|Spain|Sweden|Switzerland|United Kingdom)$/,/^$/ {
	s/^#//
	p
	bend
}

# If we aren't in the above block, accumulate in hold space
H

# Dump hold space at end
:end
$ {
	x
	p
}
