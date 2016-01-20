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

  # from a comment in CMakeLists.txt:
  #  # In order to reduce the GTK2 library dependencies at link time, we only link against 'gtk-x11-2.0'.
  #  # This is more portable, as the dynamic linker/loader will take care of the other library dependencies at run time.
  #
  # I'm very skeptical about this and wouldn't rely on ld.so to resolve all
  # symbols through gtk-x11-2.0's dependencies. Afaik GTK+2 is quite downwards
  # compatible and usually installed by default on all typical desktop distributions.
  # And if something doesn't work right, a Mojo installer can still be run from command line.
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
CFLAGS_common="-Wformat -Werror=format-security -fstack-protector-all -fno-strict-aliasing -D_FORTIFY_SOURCE=2"
LDFLAGS_common="-Wl,-O1 -Wl,-z,defs -Wl,--as-needed"

cd build
CFLAGS="$CFLAGS_common"
LDFLAGS="-s $LDFLAGS_common -Wl,-z,relro"
build Release $rev "$CFLAGS" "$LDFLAGS"

cd ../build-minsize
CFLAGS="$CFLAGS_common -ffunction-sections -fdata-sections"
LDFLAGS="$LDFLAGS_common -Wl,-z,norelro -Wl,--gc-sections"
build MinSizeRel $rev "$CFLAGS" "$LDFLAGS"

strip --strip-all --remove-section=.comment --remove-section=.note \
  libmojosetupgui_gtkplus2.so libmojosetupgui_ncurses.so \
  make_self_extracting mojoluac mojosetup
cd ..

arch="$(file -b build/mojosetup | cut -d, -f2)"
if [ "$arch" = " Intel 80386" ]; then
  target="x86"
elif [ "$arch" = " x86-64" ]; then
  target="x86_64"
else
  echo "error: unknown or unsupported architecture"
  exit 1
fi

set -v

cp -f build/make_self_extracting bin/make_self_extracting.$target
cp -f build/mojoluac bin/mojoluac.$target
mkdir -p setup-files/bin/$target/guis
cp -f build-minsize/*.so setup-files/bin/$target/guis
cp -f build-minsize/mojosetup setup-files/bin/$target

