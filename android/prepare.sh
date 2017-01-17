#!/bin/bash
#
# Prepare swift sourcerelease to build Foundation for Android
#

BUILD_DIR="build/Ninja-ReleaseAssert/swift-linux-x86_64/lib/swift"

cd "$(dirname $0)" &&
TAR_FILE="$(pwd)/android_dispatch.tgz" &&

if [[ ! -f "${TAR_FILE}" ]]; then
    echo "Fetching binaries and headers for libxml2, libcurl and libdispatch"
    curl "https://raw.githubusercontent.com/SwiftJava/SwiftJava/master/android_dispatch.tgz" > "${TAR_FILE}"
fi

cd "../.." && mkdir -p "${BUILD_DIR}" &&
cd "${BUILD_DIR}" && tar xfvz "${TAR_FILE}"
