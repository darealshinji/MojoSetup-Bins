#!/bin/sh -e

arch=`uname -m`
echo $arch | grep "i.86" >/dev/null && arch="x86"
echo $arch | grep "86pc" >/dev/null && arch="x86"
echo $arch | grep "amd64" >/dev/null && arch="x86_64"

args="$*"

if [ -f data.tar.bz2 ]; then
  tar xfj data.tar.bz2
elif [ -f data.tar.xz ]; then
  tar xfJ data.tar.xz
else
  tar xfz data.tar.gz
fi

if [ ! -d "./bin/$arch/" -a "$arch" != "x86" ]; then
  echo "Warning: No binaries for \`$arch' found, trying to default to x86..."
  arch="x86"
fi

echo "CPU Arch: $arch"

dir="bin/$arch"

cp "$dir/mojosetup" "`pwd`"
cp -r "$dir/guis" "`pwd`"
chmod +x mojosetup
"`pwd`/mojosetup" $args
