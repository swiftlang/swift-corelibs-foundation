# Installed Bundles on UNIX-like Systems

This document covers {CF,NS,}Bundle behavior on Linux, with an eye to keeping things working for non-Linux OSes that have similar POSIX-y setups (in particular, the BSD family.) It covers _two_ different styles of bundle, which are suitable both for things that are installed systemwide (e.g. as part of a platform-supplied package manager), and for freestanding bundles that are embedded (e.g. resource bundles) or executed (e.g. app bundles) but not installed systemwide.

The aim of this proposal is to provide idiomatic ways for POSIX-y systems to use bundle API, including resource access, in a way equivalent to what Darwin OSes do for bundles installed in `/System` or `/Library`.

## Installed bundles

An installed bundle is intended to be installed in a directory hierarchy that models the use of `--prefix=…` in autoconf-like configuration tools. This is suitable for the kind of bundles that we would install in `/System/Library` or in `/Applications`, systemwide, on Darwin OSes: system frameworks, apps installed for all users, and so on.

This setup complies with the [Filesystem Hierarchy Standard (FHS) 3.0](https://refspecs.linuxfoundation.org/fhs.shtml), used by most Linux distributions. It also fits with the intent of the `/usr` and `/usr/local` directories of many BSD systems (e.g. from FreeBSD's [hier(7)][].)

[hier(7)]: https://www.freebsd.org/cgi/man.cgi?hier(7)

### Definition

An installed bundle exists if there is:

 - A directory with the `.resources` extension;
 - contained in a directory named `share`.

The base name of this bundle is the name of this directory, removing the extension. (E.g., for `/usr/share/MyFramework.resources`, the base name is `MyFramework`.)

### Bundle Paths

The bundle's `.resources` directory contains resources much like an [iOS-style flat bundle](https://developer.apple.com/library/content/documentation/CoreFoundation/Conceptual/CFBundles/BundleTypes/BundleTypes.html#//apple_ref/doc/uid/10000123i-CH101-SW1). Unlike on iOS, however, executables are not contained directly inside this directory. Instead, given that the bundle exists in `share/MyFramework.resources`, then an installed bundle will source from the following additional paths within the prefix the bundle is installed in (the parent directory of the `share` directory):

 - The main executable will be searched in the `bin`, `sbin`, or `lib…` directories.
	 - Executable bundles will search `bin`, then `sbin`, for an executable with the same base name as the resources folder, plus any platform prefix or suffix for executables. e.g.: `bin/MyApp`.
	 - Framework bundles will search the appropriate `lib…` directories for a library of the same name, adding appropriate platform prefixes or suffixes for shared library file (falling back to just `lib` otherwise). e.g.: `lib/libMyFramework.so`.
 - Auxiliary executables and libraries will be in, or in subdirectories of, `libexec/MyFramework.executables`;
 - For framework bundles, `include/MyFramework` will contain headers, though this directory does affect the return values of the runtime API.

Both paths are optional. If they don't exist, the API will behave much like on Darwin platforms.

For installed bundles, the bundle's main executable is not searched within its `.resources` path. Instead, we expect that it be installed in the `bin` or `sbin` directory, if executable, or the appropriate `lib…` directory, if a shared library file. These files should be named the same as the main executable name (from Info.plist, or the framework's base name as a default value) plus any appropriate executable or library suffixes or prefixes for the platform. For example:

```
share/MyApp.resources
bin/MyApp
```

or:

```
share/MyFramework.resources
lib64/libMyFramework.so
```

The bundle path for an installed bundle is the same as its resources path. That's the path that needs to be passed into `CFBundleCreate()` and equivalents for the bundle to be successfully created; passing associated directory names will return `NULL`. [⊗](#nullForInnerPaths)

As an example, the following values are produced by invoking these functions on the bundle created with `CFBundleCreate(NULL, …(…"/usr/local/share/MyFramework.resources"))`:

Function | Path returned
---|---
`CFBundleCopyBundleURL` | `/usr/local/share/MyFramework.resources`
`CFBundleCopyExecutableURL` | `/usr/local/lib/libMyFramework.so`
`CFBundleCopyResourcesDirectoryURL` | `/usr/local/share/MyFramework.resources`
`CFBundleCopySharedSupportURL` |`/usr/local/share/MyFramework.resources/SharedSupport`
`CFBundleCopyPrivateFrameworksURL` | `/usr/local/libexec/MyFramework.executables/Frameworks`
`CFBundleCopySharedFrameworksURL` | `/usr/local/libexec/MyFramework.executables/SharedFrameworks`
`CFBundleCopyBuiltInPlugInsURL` | `/usr/local/libexec/MyFramework.executables/PlugIns`
`CFBundleCopyAuxiliaryExecutableURL(…, CFSTR("myexec"))` | `/usr/local/libexec/MyFramework.executables/myexec`
`CFBundleCopyResourceURL(…, CFSTR("Welcome"), CFSTR("txt") …)` | `/usr/local/share/MyFramework.resources/en.lproj/Welcome.txt`

The structure inside any of these paths is the same as that of an iOS bundle containing the appropriate subset of files for its location; for example, the resources folder contains localization `.lproj` subdirectories, the `Frameworks` directory inside the `….executables` contains frameworks, and so on.

## Freestanding bundles

We will also support freestanding bundles on platforms that also support installed bundles. These bundles are structured much like their Windows counterparts, where there is a binary and a `.resources` directory on the side, like so:

```
./MyFramework.resources
./libMyFramework.so
```

### Bundle Paths

The bundle path for an installed bundle is the same as its resources path. That's the path that needs to be passed into `CFBundleCreate()` and equivalents for the bundle to be successfully created; passing associated paths, including the path to the executable, will return `NULL`. [⊗](#nullForInnerPaths)

The `.resources` directory functions exactly like an iOS bundle, returning the same paths. By way of example, for a freestanding bundle created with `CFBundleCreate(NULL, …(…"/opt/myapp/MyFramework.resources"))`:

Function | Path returned
---|---
`CFBundleCopyBundleURL` | `/opt/myapp/MyFramework.resources`
`CFBundleCopyExecutableURL` | `/opt/myapp/libMyFramework.so`
`CFBundleCopyResourcesDirectoryURL` | `/opt/myapp/MyFramework.resources`
`CFBundleCopySharedSupportURL` |`/opt/myapp/MyFramework.resources/SharedSupport`
`CFBundleCopyPrivateFrameworksURL` | `/opt/myapp/MyFramework.resources/Frameworks`
`CFBundleCopySharedFrameworksURL` | `/opt/myapp/MyFramework.resources/SharedFrameworks`
`CFBundleCopyBuiltInPlugInsURL` | `/opt/myapp/MyFramework.resources/PlugIns`
`CFBundleCopyAuxiliaryExecutableURL(…, CFSTR("myexec"))` | `/opt/myapp/MyFramework.resources/myexec`
`CFBundleCopyResourceURL(…, CFSTR("Welcome"), CFSTR("txt") …)` | `/opt/myapp/MyFramework.resources/en.lproj/Welcome.txt`

### Embedded Frameworks

The two formats interact in the case of embedded bundles. Since the inside of any bundle is not compliant with the [LHS](https://refspecs.linuxfoundation.org/fhs.shtml), bundles inside other bundles _must_ be freestanding frameworks. This includes frameworks in the private or shared frameworks paths, built-in plug-ins, and so on.

## Alternatives considered

### XDG

There are two filesystem specs that are relevant to Linux distribution: the Filesystem Hierarchy Specification (FHS), maintained by the Linux Foundation; and the XDG Base Directory Specification, maintained by freedesktop.org.

While both define where files can be installed on a Linux system, they differ substantially:

- The FHS defines the directory structure for `/`, the root directory. In particular, it dictates where software and libraries are installed and the structure of `/usr` and `/usr/local`, which is where autoconf-style installations end up by default, and whose structure is mimicked when using `./configure --prefix=…` to isolate app and library environments to a new prefix.

- The XDG spec defines the directory structure for _user data_, such as preferences, within a single user's home directory. Compatible desktop systems will set environment variables to guide an application to write and read per-user information in paths the current user can read and write to. No part of this spec defines where _code_ should be located, though we will have to heed it for such things as `NSSearchPathsFor…` and current-user defaults reading and writing.

In comparing the two, I produced a bundle structure suitable for use with the FHS so that it can be incorporated mostly as-is into the lifecycle of autoconf or CMake-driven development on Linux (i.e., making `make install` mostly just work).

Applications, both UI and server, are usually installed systemwide on Linux (in `/usr` or `/usr/local`), or in appropriate prefixes (generally under `/opt`) for specialized needs, and there isn't a concept of a standalone bundle that may end up in the home directory as it may happen with Mac apps, so the XDG spec becomes a little less relevant.

### Use the executable's path as the bundle location

We tried this as our first attempt to avoid using the containing directory path for installed bundles, since all bundles would then have the same location. We moved away from this to the use of the `.resources` directory because it is likely that code will hardcode the assumption of a bundle location being a directory.

## Footnotes

<span id="shouldWeFallBack">⊖</span>: Should we mandate that an executable that _could_ be in an installed bundle (because the binary is in a bin or lib… directory) _must_ be in an installed bundle, e.g. that we won't fall back to searching for a freestanding bundle?

<span id="nullForInnerPaths">⊗</span>: This is consistent with Darwin OSes' behavior of returning `NULL` for any path beside the bundle path, even if that path _is_ the auxiliary or main executable path for some bundle.