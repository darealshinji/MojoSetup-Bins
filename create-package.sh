#!/usr/bin/env bash

scriptpath="$(dirname "$(readlink -f "$0")")"
defaultsplash=no
if [ "`uname -m`" = "x86_64" ]; then
  arch="x86_64"
else
  arch="x86"
fi

usage() {
cat << EOF

  Usage: $0 <directory>

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

case x"$1" in
  x|x--help|x-help|x-h|x-\?)
    usage ;;
esac
test -d "$1" || errorExit "\`$1' is not a directory"

size=$(du -bs "$1" | awk '{print $1}')

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
  read -p "Organization/vendor (w/o spaces): " VENDOR
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
if [ -z "$SPLASH" ] ; then
  echo ""
  echo "Path to a splash header image to be displayed during the"
  read -p "installation (leave empty if you don't want to use one): " SPLASH
  if [ x"$SPLASH" = x ]; then
    defaultsplash=yes
    splash_img=splash.png
  else
    splash_img="$SPLASH"
  fi
else
  splash_img="$SPLASH"
fi

tmp="$PWD/${SHORTNAME}~tmp.mojo"
readme="$tmp/data/README.mojo"
rm -rf "$tmp"
cp -r "$scriptpath/setup-files" "$tmp"
mkdir -p "$tmp/data"

if [ -z "$README" ] ; then
  touch $readme
  echo ""
  echo "Please add a more detailed description about the game in the text file"
  echo "\`$readme' and press any key to continue."
  read -p "" -n1 -s
else
  cp "$README" $readme
fi

sed -e "s|@SIZE@|$size|g; \
        s|@FULLNAME@|$FULLNAME|g; \
        s|@VENDOR@|$VENDOR|g; \
        s|@SHORTNAME@|$SHORTNAME|g; \
        s|@VERSION@|$VERSION|g; \
        s|@START@|$START|g; \
        s|@ICON@|$ICON|g; \
        s|@SPLASH@|$(basename "$splash_img")|g; \
" "$tmp/scripts/config.lua.in" > "$tmp/scripts/config.lua"
rm -f "$tmp/scripts/config.lua.in"

if [ $defaultsplash = no ]; then
  if [ -f "$splash_img" ]; then
    rm -f "$tmp/meta/splash.png"
    cp "$splash_img" "$tmp/meta"
  else
    errorExit "\`$splash_img' not found"
  fi
fi

echo ""
echo "Compress files..."
cd "$1" && tar cvfJ "$tmp/data/files.tar.xz" *
cd "$tmp" && tar cvfJ data.tar.xz bin meta scripts && rm -rf bin meta scripts
cd "$tmp/.."

"$scriptpath/bin/makeself.sh" \
  --header "$scriptpath/bin/makeself-header" \
  --nox11 \
  --nocomp \
  "$tmp" \
  "${SHORTNAME}-${VERSION}-install.sh" \
  "$FULLNAME - Setup" \
  ./setup.sh

rm -rf "$tmp"

