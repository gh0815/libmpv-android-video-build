#!/bin/bash -e

. ../../include/depinfo.sh
. ../../include/path.sh

build=_build$ndk_suffix

if [ "$1" == "build" ]; then
	true
elif [ "$1" == "clean" ]; then
	rm -rf _build$ndk_suffix
	exit 0
else
	exit 255
fi

unset CC CXX # meson wants these unset

# Build libbluray (optional) - CC must be reconstructed after unset
if [ ! -d "$prefix_dir/lib/libbluray.a" ]; then
  BLURAY_SRC=deps/libbluray
  if [ ! -d "$BLURAY_SRC" ]; then
    mkdir -p deps
    wget --no-check-certificate -q https://download.videolan.org/pub/videolan/libbluray/1.3.4/libbluray-1.3.4.tar.bz2 -O /tmp/libbluray.tar.bz2 && tar -xf /tmp/libbluray.tar.bz2 -C deps && mv deps/libbluray-1.3.4 "$BLURAY_SRC" && rm /tmp/libbluray.tar.bz2 || echo "[bluray] dl fail"
  fi
  if [ -d "$BLURAY_SRC" ]; then
    # Reconstruct CC: ndk_triple=arm-linux-androideabi → CC=armv7a-linux-androideabi21-clang
    # For aarch64: ndk_triple=aarch64-linux-android → CC=aarch64-linux-android21-clang
    BLURAY_CC="${ndk_triple}21-clang"
    [[ "$ndk_triple" == "arm-linux"* ]] && BLURAY_CC="armv7a-linux-androideabi21-clang"
    (cd "$BLURAY_SRC" && ./configure --host=$ndk_triple --prefix="$prefix_dir" --enable-static --disable-shared --disable-examples --disable-bdjava-jar --without-freetype --without-fontconfig CC="$BLURAY_CC" AR="llvm-ar" RANLIB="llvm-ranlib" CFLAGS="-I$prefix_dir/include -Os -fPIC" LDFLAGS="-L$prefix_dir/lib" && make -j$cores && make install) || echo "[bluray] build fail"
  fi
fi

meson setup $build --cross-file "$prefix_dir"/crossfile.txt \
	--prefer-static \
	--default-library shared \
	-Dgpl=false \
	-Dlibmpv=true \
 	-Dlua=disabled \
 	-Dcplayer=false \
	-Diconv=disabled \
	-Dvulkan=disabled \
   	-Dlibplacebo=disabled \
	-Dlibbluray=enabled \
	-Dmanpage-build=disabled

ninja -C $build -j$cores
DESTDIR="$prefix_dir" ninja -C $build install

ln -sf "$prefix_dir"/lib/libmpv.so "$native_dir"
