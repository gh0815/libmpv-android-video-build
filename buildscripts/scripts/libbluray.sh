#!/bin/bash -e

. ../../include/depinfo.sh
. ../../include/path.sh

if [ "$1" == "build" ]; then
	true
elif [ "$1" == "clean" ]; then
	rm -rf _build$ndk_suffix
	exit 0
else
	exit 255
fi

mkdir -p _build$ndk_suffix
cd _build$ndk_suffix

# libbluray uses autotools; cross-compile for Android
../configure \
	--host=$ndk_triple \
	--prefix="$prefix_dir" \
	--enable-static \
	--disable-shared \
	--disable-examples \
	--disable-bdjava-jar \
	--without-freetype \
	--without-fontconfig \
	--disable-doxygen-doc \
	--disable-doxygen-dot \
	CC="${CC}" \
	AR="${AR}" \
	RANLIB="${RANLIB}" \
	CFLAGS="-I$prefix_dir/include -Os -fPIC" \
	LDFLAGS="-L$prefix_dir/lib" \
	PKG_CONFIG_LIBDIR="$prefix_dir/lib/pkgconfig"

make -j$cores
make DESTDIR="$prefix_dir" install
