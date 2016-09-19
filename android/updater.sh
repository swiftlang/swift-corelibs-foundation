#!/bin/bash
#
# Move freshly built dependencies for Foundation into
# build directory to be available for it's compilation.
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
# libcurl.so is built similarly from https://github.com/curl/curl
#
# libdispatch.so is a difficult build soon to be automated by another PR.
#

ANDROID_ICU_UC="${ANDROID_ICU_UC:-$HOME/libiconv-libicu-android}"

cd "$(dirname $0)" &&

SWIFT_ROOT="$(dirname $(dirname $(which swiftc)))" &&
BUILD_DIR="$(dirname $SWIFT_ROOT)" &&

\cp -v ../../platform_external_libxml2/libxml2.so ../../curl/libcurl.so ../../swift-corelibs-libdispatch/libdispatch.so "$ANDROID_ICU_UC"/armeabi-v7a/libicu*.so "${SWIFT_ROOT}/lib/swift/android" &&

\cp -v "${BUILD_DIR}/libdispatch-linux-x86_64/src/swift/Dispatch.swift"* "${SWIFT_ROOT}/lib/swift/android/armv7" &&

rsync -arv "../../swift-corelibs-libdispatch/dispatch" "${SWIFT_ROOT}/lib/swift/" &&

\cp -v "../../swift-corelibs-libdispatch/private/"*.h "${SWIFT_ROOT}/lib/swift/dispatch" &&

rpl -R -e libicu libscu "${SWIFT_ROOT}/lib/swift/android"/lib{icu,swift,Foundation,xml2}*.so &&

for i in "${SWIFT_ROOT}/lib/swift/android"/libicu*.so; do \mv -f $i ${i/libicu/libscu}; done
