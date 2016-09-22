#!/bin/bash
#
# Simple script to move Android Foundation into toolchain
# To build it again after this, use install.sh -u to reset
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
