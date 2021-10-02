#!/bin/sh

# Change to script location.
cd "${0%/*}"

# Create a /tmp subdirectory, and be sure to remove it on termination.
MYTEMP=$(mktemp -d)
TRAP_CLEAN='rm -Rf "'"$MYTEMP"'"'
trap "$TRAP_CLEAN" INT TERM EXIT

quickErrorExit()
{
	if [ "$1" != "0" ]; then
		echo "$2" >&2
		exit 1
	fi
}

# TODO: Add support for other packages.
for PREFIX in keyring; do
	DST="./packaged/J4F-$PREFIX.7z"
	
	if [ -f "$DST" ]; then
		rm "$DST"
		quickErrorExit "$?" "Failed to remove old $DST"
	fi
	
	# Empty $MYTEMP if needed
	if [ ! -z "$(ls -A "$MYTEMP")" ]; then
		rm -r "$MYTEMP"/*
		quickErrorExit "$?" "Failed to empty $MYTEMP"
	fi
	
	rsync -am --include "just4fun_$PREFIX*" --include "*/" --exclude "*" . "$MYTEMP"
	quickErrorExit "$?" "Failed to copy mod-related files to $MYTEMP"
	
	7z a -mx9 "$DST" "$MYTEMP"/*
	quickErrorExit "$?" "Failed to compress $MYTEMP to $DST"
done
