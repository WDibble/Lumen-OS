#!/bin/sh
echo $0 $*
progdir="$(dirname "$0")"
export LD_LIBRARY_PATH="$progdir:$LD_LIBRARY_PATH"

Lumen_Style=$(/mnt/SDCARD/System/bin/jq -r '.["LUMEN STYLE"]' "/mnt/SDCARD/System/etc/lumen.json")

if [ -d "$progdir/theme_$Lumen_Style" ]; then
	cd "$progdir/theme_$Lumen_Style"
else
	cd "$progdir"
fi

"$progdir/user_guide"
