#!/bin/bash
#
# Simple script to move Android Foundation into toolchain
# To build it again after this, use install.sh -u to reset
#
# libxml2.so built from the android platform port:
# https://github.com/android/platform_external_libxml2
#
# This is the most useful page found but it's not complete
# http://stackoverflow.com/questions/12052089/using-libxml-for-android
# Don't set CFLAGS or LDFLAGS and use ./autogen.sh instead of "configure"
# Remove HTMLparser.lo and HTMLtree.lo from the Makefile and make sure
# LIBXML_HTML_ENABLED and LIBXML_ICONV_ENABLED were not enabled in file
# "include/libxml/xmlversion.h". Add the following to CFLAGS in Makefile:
# -nostdlib --target=armv7-none-linux-androideabi
# --sysroot=$ANDROID_NDK/platforms/android-21/arch-arm
#

cd "$(dirname $0)"

SWIFT_ROOT="$(dirname $(dirname $(which swiftc)))"
BUILD_DIR="$(dirname $SWIFT_ROOT)"

if [[ "$1" == "-u" ]]; then
    rm -rf "${SWIFT_ROOT}/lib/swift/CoreFoundation"
    exit
fi

\cp -v "${BUILD_DIR}/foundation-linux-x86_64/Foundation/libFoundation.so" "${SWIFT_ROOT}/lib/swift/android" &&

\cp -v "${BUILD_DIR}/foundation-linux-x86_64/Foundation/Foundation.swift"* "${SWIFT_ROOT}/lib/swift/android/armv7" &&

rsync -arv "${BUILD_DIR}/foundation-linux-x86_64/Foundation/usr/lib/swift/CoreFoundation" "${SWIFT_ROOT}/lib/swift/"
