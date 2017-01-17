#!/bin/bash
#
# Prepare binary package used to build Foundation for Android
#

cd "$(dirname $0)" &&
TAR_FILE="$(pwd)/android_dispatch" &&

cd "../../platform_external_libxml2/include" &&
tar cf "$TAR_FILE.tar" libxml &&

cd "../../curl/include" &&
tar rf "$TAR_FILE.tar" curl &&

cd "$(dirname $(dirname $(which swiftc)))/lib/swift" &&

tar rf "$TAR_FILE.tar" dispatch android/lib{xml2,curl,dispatch}.so android/armv7/Dispatch.swift* &&

gzip "$TAR_FILE.tar" &&
\mv "$TAR_FILE.tar.gz" "$TAR_FILE.tgz" &&

tar tfvz "$TAR_FILE.tgz"
