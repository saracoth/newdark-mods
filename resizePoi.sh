#!/bin/sh

find "${0%/*}/j4fRes/" -maxdepth 1 -iname 'Radar*64.png' -print0 | while IFS= read -r -d '' BIG_FILE; do
	echo "$BIG_FILE"
	OUT_DIR="$(dirname "$BIG_FILE")"
	NAME_PRE="$(basename "$BIG_FILE" | sed -rn 's#^([^0-9]+)[0-9]+[^0-9]+$#\1#p')"
	NAME_POST="$(basename "$BIG_FILE" | sed -rn 's#^[^0-9]+[0-9]+([^0-9]+)$#\1#p')"
	for NEW_SIZE in 56 48 40 32 24 16 8; do
		magick convert "$BIG_FILE" -resize "$NEW_SIZE"x "$OUT_DIR/$NAME_PRE$NEW_SIZE$NAME_POST"
	done
done
