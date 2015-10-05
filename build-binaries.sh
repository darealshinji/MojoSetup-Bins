#!/bin/sh -e

# Written by djcj <djcj@gmx.de> and released into the Public Domain.

build () {
  reltype="$1"
  rev="$2"
  CFLAGS="$3"
  LDFLAGS="$4"

  cmake ../src \
    -DCMAKE_BUILD_TYPE="$reltype" \
    -DCMAKE_C_FLAGS="$CFLAGS" \
    -DCMAKE_EXE_LINKER_FLAGS="$LDFLAGS" \
    -DCMAKE_SHARED_LINKER_FLAGS="$LDFLAGS -Wl,-Bsymbolic-functions -Wl,-z,noexecstack" \
    -DCMAKE_VERBOSE_MAKEFILE="ON"

  sed -i "s|-lgtk-x11-2\.0|`pkg-config --libs gtk+-2.0`|" CMakeFiles/mojosetupgui_gtkplus2.dir/link.txt

  for f in `find CMakeFiles -type f -name flags.make`; do
    sed -i "s|-DAPPREV=\"???\"|-DAPPREV=\"hg-$rev\"|" $f
  done

  make -j4
  chmod 0644 *.so
}

if [ ! -d "src" ]; then
  hg clone "https://hg.icculus.org/icculus/mojosetup" src
  cd src && hg id -n > ../bin/mojosetup-hg-revision
  cd ..
fi
rm -rf build build-minsize
mkdir build build-minsize

rev="$(cat bin/mojosetup-hg-revision)"
CFLAGS_common="-Wformat -Werror=format-security -fno-strict-aliasing -D_FORTIFY_SOURCE=2 $(pkg-config --cflags-only-I gtk+-2.0)"
LDFLAGS_common="-Wl,-O1 -Wl,-z,defs -Wl,--as-needed"

cd build
CFLAGS="$CFLAGS_common -fstack-protector-all"
LDFLAGS="-s $LDFLAGS_common -Wl,-z,relro"
build Release $rev "$CFLAGS" "$LDFLAGS"

cd ../build-minsize
CFLAGS="$CFLAGS_common -ffunction-sections -fdata-sections"
LDFLAGS="$LDFLAGS_common -Wl,--gc-sections"
build MinSizeRel $rev "$CFLAGS" "$LDFLAGS"

strip --strip-all --remove-section=.comment --remove-section=.note \
  libmojosetupgui_gtkplus2.so libmojosetupgui_ncurses.so \
  make_self_extracting mojoluac mojosetup

