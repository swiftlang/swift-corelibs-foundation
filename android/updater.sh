#!/bin/bash
#
# Move freshly built dependencies for Foundation into
# build directory to be available to it's compilation.
#

cd "$(dirname $0)" &&

SWIFT_ROOT="$(dirname $(dirname $(which swiftc)))" &&
BUILD_DIR="$(dirname $SWIFT_ROOT)" &&

\cp -v ../../platform_external_libxml2/libxml2.so ../../curl/libcurl.so ../../swift-corelibs-libdispatch/libdispatch.so "${SWIFT_ROOT}/lib/swift/android" &&

\cp -v "${BUILD_DIR}/libdispatch-linux-x86_64/src/swift/Dispatch.swift"* "${SWIFT_ROOT}/lib/swift/android/armv7" &&

rsync -arv "../../swift-corelibs-libdispatch/dispatch" "${SWIFT_ROOT}/lib/swift/" &&

\cp -v "../../swift-corelibs-libdispatch/private/"*.h "${SWIFT_ROOT}/lib/swift/dispatch"
