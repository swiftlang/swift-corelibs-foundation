#!/bin/bash
#
# Move freshly built dependencies for Foundation into
# build directory to be available for it's compilation.
#

cd "$(dirname $0)" &&

SWIFT_ROOT="$(dirname $(dirname $(which swiftc)))" &&
BUILD_DIR="$(dirname $SWIFT_ROOT)" &&

\cp -v ../../platform_external_libxml2/libxml2.so ../../curl/libcurl.so ../../swift-corelibs-libdispatch/libdispatch.so "$ANDROID_ICU"/armeabi-v7a/libicu*.so "${SWIFT_ROOT}/lib/swift/android" &&

rpl -R -e libicu libscu "${SWIFT_ROOT}/lib/swift/android"/lib{icu,swift,Foundation,xml2}*.so &&

for i in "${SWIFT_ROOT}/lib/swift/android"/libicu*.so; do \mv -f $i ${i/libicu/libscu}; done

\cp -v "${BUILD_DIR}/libdispatch-linux-x86_64/src/swift/Dispatch.swift"* "${SWIFT_ROOT}/lib/swift/android/armv7" &&

rsync -arv "../../swift-corelibs-libdispatch/dispatch" "${SWIFT_ROOT}/lib/swift/" &&

\cp -v "../../swift-corelibs-libdispatch/private/"*.h "${SWIFT_ROOT}/lib/swift/dispatch"
