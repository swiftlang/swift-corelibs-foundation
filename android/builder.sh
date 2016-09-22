#!/bin/bash -x
#
# Build Android toolchain including Foundation
#

cd "$(dirname $0)" &&
#./prepare.sh &&
./install.sh -u &&

pushd "../../swift" &&
./utils/build-script \
    -R --skip-build-libdispatch --foundation \
    --android \
    --android-ndk "${ANDROID_NDK_HOME:?Please set ANDROID_NDK_HOME to path to an Android NDK downloaded from http://developer.android.com/ndk/downloads/index.html}" \
    --android-api-level 21 \
    --android-icu-uc "${ANDROID_ICU_UC:?Please set ANDROID_ICU_UC to path to Android ICU downloaded from https://github.com/SwiftAndroid/libiconv-libicu-android/releases/download/android-ndk-r12/libiconv-libicu-armeabi-v7a-ubuntu-15.10-ndk-r12.tar.gz}/armeabi-v7a" \
    --android-icu-uc-include "${ANDROID_ICU_UC}/armeabi-v7a/icu/source/common" \
    --android-icu-i18n "${ANDROID_ICU_UC}/armeabi-v7a" \
    --android-icu-i18n-include "${ANDROID_ICU_UC}/armeabi-v7a/icu/source/i18n" &&

popd && ./install.sh
