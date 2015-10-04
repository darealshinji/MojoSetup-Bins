#!/bin/sh -e

os=`uname | tr '[A-Z]' '[a-z]'`
arch=`uname -m`
echo $arch | grep "i.86" >/dev/null && arch="x86"
echo $arch | grep "86pc" >/dev/null && arch="x86"
echo $arch | grep "amd64" >/dev/null && arch="x86_64"

args="$*"

tar xfJ data.tar.xz

if [ ! -d "./bin/$os/" -a "$os" != "linux" ]; then
  echo "Warning: No binaries for \`$os' found, trying to default to Linux..."
  os="linux"
fi
if [ ! -d "./bin/$os/$arch/" -a "$arch" != "x86" ]; then
  echo "Warning: No binaries for \`$arch' found, trying to default to x86..."
  arch="x86"
fi

echo "Operating system: $os"
echo "CPU Arch: $arch"

dir="bin/$os/$arch"
mojobin="$dir/mojosetup"

cp "$mojobin" "`pwd`"
cp -r "$dir/guis" "`pwd`"
chmod +x mojosetup
"`pwd`/mojosetup" $args

