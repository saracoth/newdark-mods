#!/bin/sh

# Given a folder with files like miss1.mis.dml, etc., rename and move files into
# appropriate dbmods subfolders. For example, if told to use an xyzzy prefix,
# will move ./miss1.mis.dml into ./dbmods/miss1.mis/xyzzy.dml
#
# This may be useful to combine non-conflicting mods into a single directory
# structure, reducing the total number of mod directories, improving the speed
# of disk operations by cutting down on the number of directories that must
# be checked to find a file.
# 
# This script makes no backups. Either keep a copy of the original mod .zip or
# .7z file, or make your own backups as needed.

simplePrompt()
{
	ON_YES=0
	ON_NO=1
	if [ "$3" != "" -a "$3" != "0" ]; then
		ON_YES=1
		ON_NO=0
	fi
	while true; do
		echo -n "$1"
		read PROMPT_RESULT
		if [ "$PROMPT_RESULT" = "" ]; then
			PROMPT_RESULT="$2"
		fi
		
		if [ "$PROMPT_RESULT" != "${PROMPT_RESULT#[Yy]}" ]; then
			return $ON_YES
		elif [ "$PROMPT_RESULT" != "${PROMPT_RESULT#[Nn]}" ]; then
			return $ON_NO
		fi
	done
}

quickErrorExit()
{
	if [ "$1" != "0" ]; then
		echo "$2" >&2
		exit 1
	fi
}

IN_DIR="$1"
PREFIX="$2"

if [ -z "$IN_DIR" ]; then
	echo "Script expects a directory as its first parameter." >&2
	exit 2
elif [ ! -d "$IN_DIR" ]; then
	echo "\"$IN_DIR\" is not a directory." >&2
	exit 2
fi

if [ -z "$PREFIX" ]; then
	echo "Script expects a filename prefix as its second parameter." >&2
	exit 3
fi

# Cleanup, if needed.
# For really simple filenames, we'll skip this.
if echo "$PREFIX" | grep -qE '[^0-9A-Za-z_-]'; then
	which uname 2>&1 > /dev/null
	if [ "$?" != "0" ]; then
		echo "Cannot find inline-detox utility to sanitize prefix." >&2
		exit 4
	fi
	PREFIX="$(echo "$PREFIX" | inline-detox)"
fi

OUT_DIR="$IN_DIR/dbmods"

echo "Moving $IN_DIR files into $OUT_DIR/$PREFIX*.dml files."
if [ -d "$OUT_DIR" ]; then
	if simplePrompt "$OUT_DIR already exists. Proceed anyway? [y/N] " "n" 1; then
		echo "Aborting." >&2
		exit 5
	fi
else
	if simplePrompt "Is that okay? [y/n] " "" 1; then
		echo "Aborting." >&2
		exit 5
	fi
	
	mkdir "$OUT_DIR"
	quickErrorExit "$?" "Failed to create $OUT_DIR"
fi

find "$IN_DIR" -maxdepth 1 -type f -iname '*.dml' -print0 | while IFS= read -r -d '' IN_PATH; do
	IN_FILE="$(basename "$IN_PATH" .dml)"
	
	if echo "$IN_FILE" | grep -qiE -e '\.mis$'; then
		SUB_DIR="$OUT_DIR/$IN_FILE"
		mkdir -p "$SUB_DIR"
		quickErrorExit "$?" "Failed to create $SUB_DIR"
		
		OUT_PATH="$SUB_DIR/$PREFIX.dml"
	elif echo "$IN_FILE" | grep -qiE -e '\.gam$'; then
		echo "Specific-gamesys file $IN_FILE should be fingerprinted."
		echo ""
		echo "FINGERPRINT"
		echo "{"
		echo "	GAM $IN_FILE"
		echo "}"
		echo ""
		if simplePrompt "Ready to edit file? [Y/n] " "" 1; then
			echo "Skipping file. It will be left in place." >&2
			continue
		fi
		OUT_PATH="$OUT_DIR/$PREFIX-$(basename "$$IN_FILE" .gam)-gamesys.dml"
	else
		OUT_PATH="$OUT_DIR/$PREFIX-$IN_FILE.dml"
	fi
	
	mv -i "$IN_PATH" "$OUT_PATH"
	quickErrorExit "$?" "Failed to move $IN_PATH to $OUT_PATH"
done

