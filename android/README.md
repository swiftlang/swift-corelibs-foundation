
## Android Port of Foundation module

This directory contains scripts used in the port of Foundation to
an Android toolchain. The short version of the story is that after
downloading the swift sources use the script "prepare.sh" in this
directory to install prebuilt binaries and headers for libxml,
libcurl and libdispatch then run the script "builder.sh".

This build requires the path to a [r12 Android NDK](http://developer.android.com/ndk/downloads/index.html) in the
`ANDROID_NDK_HOME` environment variable and the path to the
android port of the "icu" libraries in `ANDROID_ICU_UC`
downloaded from [here](https://github.com/SwiftAndroid/libiconv-libicu-android/releases/download/android-ndk-r12/libiconv-libicu-armeabi-v7a-ubuntu-15.10-ndk-r12.tar.gz).
The port was tested against api 21 on a Android v5.1.1 LG K4 Phone (Lollipop)
and requires an Ubuntu 15 host with the Android NDK Gold linker from
`toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/arm-linux-androideabi/bin` installed as /usr/bin/ld.gold.

The pre-built binaries were built from the following repos:

[https://github.com/curl/curl](https://github.com/curl/curl)

[https://github.com/android/platform_external_libxml2](https://github.com/android/platform_external_libxml2)

[https://github.com/apple/swift-corelibs-libdispatch](https://github.com/apple/swift-corelibs-libdispatch)

[https://github.com/mheily/libpwq](https://github.com/mheily/libpwq)

[https://github.com/mheily/libkqueue](https://github.com/mheily/libkqueue)

To build these the recipe was generally the same. autogen or configure
for Linux then alter their Makefiles to have CFLAGS = include: --target=armv7-none-linux-androideabi --sysroot=$(ANDROID_NDK_HOME)/platforms/android-21/arch-arm.

There is a known issue when libdispatch background tasks exit
they will cause an exception as DetachCurrentThread has not
been called. To avoid this your app must include the line:

   DispatchGroup.threadCleanupCallback = JNI_DetachCurrentThread

JNI_DetachCurrentThread is available in the package java_swift
available here: https://github.com/SwiftJava/java_swift

Pre-built binaries of an Swift compiler with support for Android
including Foundation available here:

http://johnholdsworth.com/android_toolchain.tgz

### Other resources

Check out the [SwiftAndroid](https://github.com/SwiftAndroid) and
[SwiftJava](https://github.com/SwiftJava) github projects for
starter Android applications and resources.
