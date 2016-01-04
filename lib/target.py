# This source file is part of the Swift.org open source project
#
# Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
#
# See http://swift.org/LICENSE.txt for license information
# See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
#

from .config import Configuration
import platform

class ArchType:
    UnknownArch = 0
    arm         = 1
    armeb       = 2
    aarch64     = 3
    aarch64_be  = 4
    bpfel       = 5
    bpfeb       = 6
    hexagon     = 7
    mips        = 8
    mipsel      = 9
    mips64      = 10
    mips64el    = 11
    msp430      = 12
    ppc         = 13
    ppc64       = 14
    ppc64le     = 15
    r600        = 16
    amdgcn      = 17
    sparc       = 18
    sparcv9     = 19
    sparcel     = 20
    systemz     = 21
    tce         = 22
    thumb       = 23
    thumbeb     = 24
    x86         = 25
    x86_64      = 26
    xcore       = 27
    nvptx       = 28
    nvptx64     = 29
    le32        = 30
    le64        = 31
    amdil       = 32
    amdil64     = 33
    hsail       = 34
    hsail64     = 35
    spir        = 36
    spir64      = 37
    kalimba     = 38
    shave       = 39
# Do not assume that these are 1:1 mapping.  This should follow
# canonical naming conventions for arm, etc. architectures.
# See apple/swift PR #608    
    @staticmethod
    def to_string(value):
        if value == ArchType.arm:
            return "armv7"
        if value == ArchType.armeb:
            return "armeb"
        if value == ArchType.aarch64:
            return "aarch64"
        if value == ArchType.aarch64_be:
            return "aarch64_be"
        if value == ArchType.bpfel:
            return "bpfel"
        if value == ArchType.bpfeb:
            return "bpfeb"
        if value == ArchType.hexagon:
            return "hexagon"
        if value == ArchType.mips:
            return "mips"
        if value == ArchType.mipsel:
            return "mipsel"
        if value == ArchType.mips64:
            return "mips64"
        if value == ArchType.mips64el:
            return "mips64el"
        if value == ArchType.msp430:
            return "msp430"
        if value == ArchType.ppc:
            return "ppc"
        if value == ArchType.ppc64:
            return "ppc64"
        if value == ArchType.ppc64le:
            return "ppc64le"
        if value == ArchType.r600:
            return "r600"
        if value == ArchType.amdgcn:
            return "amdgcn"
        if value == ArchType.sparc:
            return "sparc"
        if value == ArchType.sparcv9:
            return "sparcv9"
        if value == ArchType.sparcel:
            return "sparcel"
        if value == ArchType.systemz:
            return "systemz"
        if value == ArchType.tce:
            return "tce"
        if value == ArchType.thumb:
            return "armv7"
        if value == ArchType.thumbeb:
            return "thumbeb"
        if value == ArchType.x86:
            return "i386"
        if value == ArchType.x86_64:
            return "x86_64"
        if value == ArchType.xcore:
            return "xcore"
        if value == ArchType.nvptx:
            return "nvptx"
        if value == ArchType.nvptx64:
            return "nvptx64"
        if value == ArchType.le32:
            return "le32"
        if value == ArchType.le64:
            return "le64"
        if value == ArchType.amdil:
            return "amdil"
        if value == ArchType.amdil64:
            return "amdil64"
        if value == ArchType.hsail:
            return "hsail"
        if value == ArchType.hsail64:
            return "hsail64"
        if value == ArchType.spir:
            return "spir"
        if value == ArchType.spir64:
            return "spir64"
        if value == ArchType.kalimba:
            return "kalimba"
        if value == ArchType.shave:
            return "shave"
        return "unknown"
# Not 1:1, See to_string
    @staticmethod
    def from_string(string):
        # Match big endian arm first
        if string == "armeb":
            return ArchType.armeb
        # Catch-all for little endian arm
        if "arm" in string:
            return ArchType.arm
        if string == "aarch64":
            return ArchType.aarch64
        if string == "aarch64_be":
            return ArchType.aarch64_be
        if string == "bpfel":
            return ArchType.bpfel
        if string == "bpfeb":
            return ArchType.bpfeb
        if string == "hexagon":
            return ArchType.hexagon
        if string == "mips":
            return ArchType.mips
        if string == "mipsel":
            return ArchType.mipsel
        if string == "mips64":
            return ArchType.mips64
        if string == "mips64el":
            return ArchType.mips64el
        if string == "msp430":
            return ArchType.msp430
        if string == "ppc":
            return ArchType.ppc
        if string == "ppc64":
            return ArchType.ppc64
        if string == "ppc64le":
            return ArchType.ppc64le
        if string == "r600":
            return ArchType.r600
        if string == "amdgcn":
            return ArchType.amdgcn
        if string == "sparc":
            return ArchType.sparc
        if string == "sparcv9":
            return ArchType.sparcv9
        if string == "sparcel":
            return ArchType.sparcel
        if string == "systemz":
            return ArchType.systemz
        if string == "tce":
            return ArchType.tce
        if string == "thumb":
            return ArchType.thumb
        if string == "thumbeb":
            return ArchType.thumbeb
        if string == "x86":
            return ArchType.x86
        if string == "x86_64":
            return ArchType.x86_64
        if string == "xcore":
            return ArchType.xcore
        if string == "nvptx":
            return ArchType.nvptx
        if string == "nvptx64":
            return ArchType.nvptx64
        if string == "le32":
            return ArchType.le32
        if string == "le64":
            return ArchType.le64
        if string == "amdil":
            return ArchType.amdil
        if string == "amdil64":
            return ArchType.amdil64
        if string == "hsail":
            return ArchType.hsail
        if string == "hsail64":
            return ArchType.hsail64
        if string == "spir":
            return ArchType.spir
        if string == "spir64":
            return ArchType.spir64
        if string == "kalimba":
            return ArchType.kalimba
        if string == "shave":
            return ArchType.shave

        return ArchType.UnknownArch


class ArchSubType:
    NoSubArch         = 0
    ARMSubArch_v8_1a  = 1
    ARMSubArch_v8     = 2
    ARMSubArch_v7     = 3
    ARMSubArch_v7em   = 4
    ARMSubArch_v7m    = 5
    ARMSubArch_v7s    = 6
    ARMSubArch_v6     = 7
    ARMSubArch_v6m    = 8
    ARMSubArch_v6k    = 9
    ARMSubArch_v6t2   = 10
    ARMSubArch_v5     = 11
    ARMSubArch_v5te   = 12
    ARMSubArch_v4t    = 13
    KalimbaSubArch_v3 = 14
    KalimbaSubArch_v4 = 15
    KalimbaSubArch_v5 = 16


class OSType:
    UnknownOS = 0
    CloudABI  = 1
    Darwin    = 2 
    DragonFly = 3
    FreeBSD   = 4
    IOS       = 5
    KFreeBSD  = 6
    Linux     = 7
    Lv2       = 8
    MacOSX    = 9
    NetBSD    = 10
    OpenBSD   = 11
    Solaris   = 12
    Win32     = 13
    Haiku     = 14
    Minix     = 15
    RTEMS     = 16
    NaCl      = 17
    CNK       = 18
    Bitrig    = 19
    AIX       = 20
    CUDA      = 21
    NVCL      = 22
    AMDHSA    = 23
    PS4       = 24


class ObjectFormat:
    UnknownObjectFormat = 0
    COFF                = 1
    ELF                 = 2
    MachO               = 3


class EnvironmentType:
    UnknownEnvironment = 0
    GNU                = 1
    GNUEABI            = 2
    GNUEABIHF          = 3
    GNUX32             = 4
    CODE16             = 5
    EABI               = 6
    EABIHF             = 7
    Android            = 8
    MSVC               = 9
    Itanium            = 10
    Cygnus             = 11
 

class Vendor:
    UnknownVendor           = 0
    Apple                   = 1
    PC                      = 2
    SCEI                    = 3
    BGP                     = 4
    BGQ                     = 5
    Freescale               = 6
    IBM                     = 7
    ImaginationTechnologies = 8
    MipsTechnologies        = 9
    NVIDIA                  = 10
    CSR                     = 11


class Target:
    triple = None
    sdk = None
    arch = None
    executable_suffix = ""
    dynamic_library_prefix = "lib"
    dynamic_library_suffix = ".dylib"
    static_library_prefix = "lib"
    static_library_suffix = ".a"

    def __init__(self, triple):
        if "linux" in triple:
            self.sdk = OSType.Linux
            self.dynamic_library_suffix = ".so"
        elif "freebsd" in triple:
            self.sdk = OSType.FreeBSD
            self.dynamic_library_suffix = ".so"
        elif "windows" in triple or "win32" in triple:
            self.sdk = OSType.Win32
            self.dynamic_library_suffix = ".dll"
            self.executable_suffix = ".exe"
        elif "darwin" in triple:
            self.sdk = OSType.MacOSX
        else:
            print("Unknown platform")

        self.triple = triple

        comps = triple.split('-')
        self.arch = ArchType.from_string(comps[0])

    @staticmethod
    def default():
        arch = ArchType.from_string(platform.machine())
        triple = ArchType.to_string(arch)
        if platform.system() == "Linux":
            if arch == ArchType.arm:
                triple += "-linux-gnueabihf"
            else: 
                triple += "-linux-gnu"
        elif platform.system() == "Darwin":
            triple += "-apple-darwin"
        elif platform.system() == "FreeBSD":
            # Make this work on 10 as well.
            triple += "-freebsd11.0"
        else:
            # TODO: This should be a bit more exhaustive
            print("unknown host os")
            return None
        return triple

    @property
    def swift_triple(self):
        triple = ArchType.to_string(self.arch)
        if self.sdk == OSType.MacOSX:
            return None
        elif self.sdk == OSType.Linux:
            # FIXME: It would be nice to detect the host ABI here
            if self.arch == ArchType.arm:
                triple += "-unknown-linux-gnueabihf"
            else:
                triple += "-unknown-linux"
        elif self.sdk == OSType.FreeBSD:
            triple += "-unknown-freebsd"
        else:
            print("unknown sdk for swift")
            return None

        return triple

    @property
    def swift_sdk_name(self):
        if self.sdk == OSType.MacOSX:
            return "macosx"
        elif self.sdk == OSType.Linux:
            return "linux"
        elif self.sdk == OSType.FreeBSD:
            return "freebsd"
        else:
            print("unknown sdk for swift")
            return None
    
    
    @property
    def swift_arch(self):
        return ArchType.to_string(self.arch) 

class TargetConditional:
    _sdk = None
    _arch = None
    _default = None
    def __init__(self, sdk = None, arch = None, default = None):
        self._sdk = sdk
        self._arch = arch
        self._default = default

    def evalulate(self, target):
        if self._sdk is not None and target.sdk in self._sdk:
            return self._sdk[target.sdk]
        if self._arch is not None and target.arch in self._arch:
            return self._arch[target.arch]
        return self._default

    @staticmethod
    def value(value):
        if type(value) is TargetConditional:
            return value.evalulate(Configuration.current.target)
        return value
