#!/bin/sh
#
# Perform various static code analysis checks
#

. ${0%/*}/lib.sh

make coccicheck

set +x

fail=
for cocci_patch in contrib/coccinelle/*.patch
do
	if test -s "$cocci_patch"
	then
		echo "$(tput setaf 1)Coccinelle suggests the following changes in '$cocci_patch':$(tput sgr0)"
		cat "$cocci_patch"
		fail=UnfortunatelyYes
	fi
done

if test -n "$fail"
then
	echo "$(tput setaf 1)error: Coccinelle suggested some changes$(tput sgr0)"
	exit 1
fi

make hdr-check ||
exit 1

( make sparse 3>&2 2>&1 >&3 ) |
while IFS= read -r line
do
	case "$line" in
	GIT_VERSION*|"*new * flags") continue ;;
	esac
	filename="${line%%:*}"
	linum="${line#*:}"
	linum="${linum%%:*}"
	# ignore false positive struct foo val = { 0 }
	# need to look into file since `type *p = 0` has the same warning
	if ! sed -n "${linum}{p;q}" "$filename" | grep -q '= *{ *0 *}'
	then
		echo "$line"
	fi
done | grep . && exit 1

save_good_tree
