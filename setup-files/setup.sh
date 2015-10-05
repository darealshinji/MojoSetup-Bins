#!/bin/sh -e

arch=`uname -m`
echo $arch | grep "i.86" >/dev/null && arch="x86"
echo $arch | grep "86pc" >/dev/null && arch="x86"
echo $arch | grep "amd64" >/dev/null && arch="x86_64"

args="$*"

tar xfJ data.tar.xz

if [ ! -d "./bin/$arch/" -a "$arch" != "x86" ]; then
  echo "Warning: No binaries for \`$arch' found, trying to default to x86..."
  arch="x86"
fi

echo "CPU Arch: $arch"

dir="bin/$arch"
mojobin="$dir/mojosetup"

cp "$mojobin" "`pwd`"
cp -r "$dir/guis" "`pwd`"
chmod +x mojosetup
"`pwd`/mojosetup" $args

