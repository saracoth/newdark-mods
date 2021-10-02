#!/bin/sh

# Change to script location.
cd "${0%/*}"

quickErrorExit()
{
	if [ "$1" != "0" ]; then
		echo "$2" >&2
		exit 1
	fi
}

# Create a /tmp subdirectory, and be sure to remove it on termination.
MYTEMP=$(mktemp -d)
quickErrorExit "$?" "Failed to create a temporary directory."
TRAP_CLEAN='rm -Rf "'"$MYTEMP"'"'
trap "$TRAP_CLEAN" INT TERM EXIT

# This is for gathering all mod-related files.
MOD_FILES="$MYTEMP/current"
mkdir "$MOD_FILES"
quickErrorExit "$?" "Failed to create $MOD_FILES"

# This is for creating the mod archives.
LOOSE_FILES="$MYTEMP/loose"
mkdir "$LOOSE_FILES"
quickErrorExit "$?" "Failed to create $LOOSE_FILES"

# For package suffixes.
SUFFIX_GROUPS="$MYTEMP/groups"
mkdir "$SUFFIX_GROUPS"
quickErrorExit "$?" "Failed to create $SUFFIX_GROUPS"

# Process the targets file into something usable.
CLEAN_TARGETS="$MYTEMP/targets.txt"
# Reduce to just patterns, and turn the empty suffix into the word "null"
grep . package.targets | grep -v '^#' | sed -r 's#^(:.*)$#null\1#p' | LC_ALL=C sort > "$CLEAN_TARGETS"
# Split into one file per group. Separate include and exclude patterns.
awk '-F:' '{if ($2 ~ /^!/) { print substr($2,2) > "'"$SUFFIX_GROUPS/"'"$1"_ex.txt" } else { print $2 > "'"$SUFFIX_GROUPS/"'"$1"_in.txt" } }' "$CLEAN_TARGETS"

# Remove all old packages. So if targets are deleted or
# become empty, we don't keep old vesions around.
if [ ! -z "$(ls -A "./packaged")" ]; then
	rm "./packaged/"*.7z
	quickErrorExit "$?" "Failed to delete old packages."
fi

for PREFIX in keyring ghost_mode glowfairy radar summoner; do
	# Empty directory if needed
	if [ ! -z "$(ls -A "$MOD_FILES")" ]; then
		rm -r "$MOD_FILES"/*
		quickErrorExit "$?" "Failed to empty $MOD_FILES"
	fi
	
	# Copy over all files related to the current mod.
	rsync -am --exclude-from="./package.blocklist" --include "just4fun_$PREFIX*" --include "*/" --exclude "*" . "$MOD_FILES"
	quickErrorExit "$?" "Failed to copy mod-related files to $MOD_FILES"
	
	# TODO: reorganize handling of resources, once I get the keyhole peeping branch working
	if [ "$PREFIX" = "radar" ]; then
		cp "./j4fRes.crf" "$MOD_FILES/j4fRes.crf"
		quickErrorExit "$?" "Failed to copy j4fRes.crf to $MOD_FILES"
	fi
	
	# Check for matching files in all prefixes.
	find "$SUFFIX_GROUPS" -maxdepth 1 -type f -iname '*.txt' | sed -rn 's#^(.+)...\.txt#\1#p' | while read -r GROUP_MATCH; do
		GROUP_MATCH="$(basename "$GROUP_MATCH")"
		INCLUDE_EXTRA="$SUFFIX_GROUPS/${GROUP_MATCH}_in.txt"
		EXCLUDE_EXTRA="$SUFFIX_GROUPS/${GROUP_MATCH}_ex.txt"
		
		# Empty directory if needed
		if [ ! -z "$(ls -A "$LOOSE_FILES")" ]; then
			rm -r "$LOOSE_FILES"/*
			quickErrorExit "$?" "Failed to empty $LOOSE_FILES"
		fi
		
		if [ -f "$INCLUDE_EXTRA" ]; then
			if [ -f "$EXCLUDE_EXTRA" ]; then
				# We have both.
				rsync -am --exclude-from="$EXCLUDE_EXTRA" --include-from="$INCLUDE_EXTRA" --include "*/" --exclude "*" "$MOD_FILES/"* "$LOOSE_FILES"
				quickErrorExit "$?" "Failed to copy mod-related files to $LOOSE_FILES"
			else
				# We only have INCLUDE_EXTRA
				rsync -am --include-from="$INCLUDE_EXTRA" --include "*/" --exclude "*" "$MOD_FILES/"* "$LOOSE_FILES"
				quickErrorExit "$?" "Failed to copy mod-related files to $LOOSE_FILES"
			fi
		else
			# We only have EXCLUDE_EXTRA
			rsync -am --exclude-from="$EXCLUDE_EXTRA" --include "*" "$MOD_FILES/"* "$LOOSE_FILES"
			quickErrorExit "$?" "Failed to copy mod-related files to $LOOSE_FILES"
		fi
		
		# Create archive if there are any files for it.
		if [ ! -z "$(ls -A "$LOOSE_FILES")" ]; then
			ls -alR "$LOOSE_FILES"
			
			FILE_SUFFIX="$GROUP_MATCH"
			if [ "$FILE_SUFFIX" = "null" ]; then
				FILE_SUFFIX=""
			else
				FILE_SUFFIX="_$FILE_SUFFIX"
			fi
			
			DST="./packaged/J4F-$PREFIX$FILE_SUFFIX.7z"
			
			if [ -f "$DST" ]; then
				rm "$DST"
				quickErrorExit "$?" "Failed to remove old $DST"
			fi
			
			7z a -mx9 "$DST" "$LOOSE_FILES"/*
			quickErrorExit "$?" "Failed to compress $LOOSE_FILES to $DST"
		fi
	done
done
