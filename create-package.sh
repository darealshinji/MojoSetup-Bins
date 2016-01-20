#!/usr/bin/env bash

# Copyright (c) 2015-2016, djcj <djcj@gmx.de>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

scriptpath="$(dirname "$(readlink -f "$0")")"

usage() {
cat << EOF

  Usage: $0 [options] <directory>

  Options:
    --compression=METHOD       compression method used for the app/game files
                               available: xz, gz(ip), bz(ip)2; default: xz
    --mojo-compression=METHOD  compression method used for the setup files
                               available: xz, gz(ip), bz(ip)2; default: bzip2
    --pause                    pause before compressing files to allow final
                               manual modifications
    --help, -h                 display this message

  Environment variables:
    FULLNAME     full name of the application
    SHORTNAME    short name, i.e. used as directory name
    VERSION      release version string
    VENDOR       copyright holder
    START        startup command inside the directory
    ICON         menu icon (inside the directory)
    SPLASH       splash header image to be displayed during the installation
    README       README file to use

EOF
exit 0
}

errorExit() {
  echo "error: $1"
  exit 1
}


# parse command line arguments
case x"$1" in
  x|x--help|x-help|x-h|x-\?)
    usage ;;
esac

pause="no"
compression="xz"
mojocompression="bz2"
for opt; do
  optarg="${opt#*=}"
  case "$opt" in
    --compression=*)
      compression="$optarg"
      ;;
    --mojo-compression=*)
      mojocompression="$optarg"
      ;;
    --pause)
      pause="yes"
      ;;
    *)
      dir="$optarg"
      ;;
  esac
done

test -n "$dir" || errorExit "no target directory specified"
test -d "$dir" || errorExit "\`$dir' is not a directory"
size=$(du -bs "$dir" | awk '{print $1}')

case $compression in
  bz*) z=j; ext=bz2 ;;
  xz*) z=J; ext=xz ;;
  *)   z=z; ext=gz ;;
esac
case $mojocompression in
  bz*) zm=j; extm=bz2 ;;
  xz*) zm=J; extm=xz ;;
  *)   zm=z; extm=gz ;;
esac


# get information about the program
if [ -z "$FULLNAME" -o -z "$SHORTNAME" -o -z "$VERSION" -o -z "$VENDOR" -o -z "$START" -o -z "$ICON" -o -z "$SPLASH" ] ; then
  echo "Please enter some information about the program"
  echo ""
fi
if [ -z "$FULLNAME" ] ; then
  read -p "Full name: " FULLNAME
  test x"$FULLNAME" = x && errorExit "Enter a full name"
fi
if [ -z "$SHORTNAME" ] ; then
  suggestion=$(echo $FULLNAME | sed -e 's/[^A-Za-z0-9._-]//g')
  read -p "Short name (i.e. $suggestion): " SHORTNAME
  test x"$SHORTNAME" = x && errorExit "Enter a short name"
fi
if [ -z "$VERSION" ] ; then
  read -p "Release version: " VERSION
  test x"$VERSION" = x && errorExit "Enter a version"
fi
if [ -z "$VENDOR" ] ; then
  read -p "Organization/vendor: " VENDOR
  test x"$VENDOR" = x && errorExit "Enter the name of the copyright holder"
fi
if [ -z "$START" ] ; then
  read -p "Startup command inside the directory: " START
  test x"$START" = x && errorExit "Enter the startup command"
fi
if [ -z "$ICON" ] ; then
  read -p "Menu icon (inside the directory): " ICON
  test x"$ICON" = x && errorExit "Enter an icon filename"
fi
defaultsplash=no
if [ -z "$SPLASH" ] ; then
  echo ""
  echo "Path to a splash header image to be displayed during the"
  read -p "installation (leave empty if you don't want to use one): " SPLASH
  if [ x"$SPLASH" = x ]; then
    defaultsplash=yes
  fi
fi


# create a temporary working directory
tmp="$PWD/${SHORTNAME}~tmp.mojo"
readme="$tmp/data/README.mojo"
rm -rf "$tmp"
cp -r "$scriptpath/setup-files" "$tmp"
mkdir -p "$tmp/data"


# copy the splash image file
if [ $defaultsplash = no ]; then
  if [ -f "$SPLASH" ]; then
    rm -f "$tmp/meta/splash.png"
    cp "$SPLASH" "$tmp/meta"
    SPLASH="$(basename "$SPLASH")"
  else
    errorExit "\`$SPLASH' not found"
  fi
else
  SPLASH="splash.png"
fi


# generate our lua config file
VENDOR="$(echo "$VENDOR" | tr -d -c '[:alnum:].+-')"
sed -e "s|@SIZE@|$size|g; \
        s|@FULLNAME@|$FULLNAME|g; \
        s|@VENDOR@|$VENDOR|g; \
        s|@SHORTNAME@|$SHORTNAME|g; \
        s|@VERSION@|$VERSION|g; \
        s|@START@|$START|g; \
        s|@ICON@|$ICON|g; \
        s|@SPLASH@|$SPLASH|g; \
        s|@COMPRESSION@|$ext|g; \
" "$scriptpath/config.lua.in" > "$tmp/scripts/config.lua"


# ask the user to write a readme
if [ -z "$README" ] ; then
  touch $readme
  echo ""
  echo "Please add a more detailed description about the game in the text file"
  echo "\`$readme' and press any key to continue."
  read -p "" -n1 -s
else
  cp "$README" $readme
fi


# pause if the script was run with `--pause'
if [ "$pause" = "yes" ] ; then
  echo ""
  echo "You can now add some manual modifications."
  echo "Press any key to continue."
  read -p "" -n1 -s
fi


# compress files
echo ""
echo "Create data/files.tar.$ext:"
cd "$dir" && tar cvf$z "$tmp/data/files.tar.$ext" *
echo ""
echo "Create data.tar.$extm:"
cd "$tmp" && tar cvf$zm data.tar.$extm bin meta scripts && rm -rf bin meta scripts
cd "$tmp/.."


# generate sfx archive with makeself
echo ""
echo ""
"$scriptpath/bin/makeself.sh" \
  --header "$scriptpath/bin/makeself-header" \
  --nox11 \
  --nocomp \
  "$tmp" \
  "${SHORTNAME}-${VERSION}-install.sh" \
  "$FULLNAME - Setup" \
  ./setup.sh

rm -rf "$tmp"

