#!/bin/sh

cd "$(dirname "$(readlink -f "$0")")"

make -C helloworld

export FULLNAME="Hello World"
export SHORTNAME=helloworld
export VERSION=1.0
export VENDOR=Public-Domain
export START=./helloworld
export ICON=icon.png
export SPLASH=helloworld/splash.png
export README=helloworld/README

../create-package.sh helloworld

