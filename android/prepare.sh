#!/bin/bash
#
# Prepare swift sourcerelease to build Foundation for Android
#

BUILD_DIR="build/Ninja-ReleaseAssert/swift-linux-x86_64/lib/swift"

cd "$(dirname $0)" &&
TAR_FILE="$(pwd)/android_toolchain.tgz" &&

if [[ ! -f "${TAR_FILE}" ]]; then
echo "Fetching binaries and headers for libxml2, libcurl and libdispatch"
curl http://johnholdsworth.com/android_toolchain.tgz > "${TAR_FILE}"
fi

tar xfvz "${TAR_FILE}"

mkdir -p "../../${BUILD_DIR}/android/armv7" &&

cp -r swift-install/usr/lib/swift/android/{libxml2.so,libcurl.so,libdispatch.so} ../../${BUILD_DIR}/android
cp -r swift-install/usr/lib/swift/android/armv7/Dispatch.swiftmodule ../../${BUILD_DIR}/android/armv7
rm -rf swift-install
