#!/bin/sh
# Supermodel's sources at the commit of supermodel.version, in
# supermodel-src/, the iOS patch applied; Musashi's generated 68K emulator
# in supermodel-src/musashi/ (made by m68kmake, built for this machine).
set -eu
here=$(cd "$(dirname "$0")" && pwd)
commit=$(cat "$here/supermodel.version")
src="$here/supermodel-src"

if [ ! -d "$src/.git" ]; then
	git init -q "$src"
	git -C "$src" remote add origin https://github.com/trzy/supermodel.git
fi
git -C "$src" fetch -q --depth 1 origin "$commit"
git -C "$src" checkout -q -f FETCH_HEAD
git -C "$src" clean -q -fdx
for patch in "$here"/patches/*.patch; do
	git -C "$src" apply --whitespace=nowarn "$patch"
	echo "applied $(basename "$patch")"
done

mkdir -p "$src/musashi"
cc -O2 -o "$src/musashi/m68kmake" "$src/Src/CPU/68K/Musashi/m68kmake.c"
"$src/musashi/m68kmake" "$src/musashi" "$src/Src/CPU/68K/Musashi/m68k_in.c" >/dev/null
echo "Supermodel $commit ready in $src"
