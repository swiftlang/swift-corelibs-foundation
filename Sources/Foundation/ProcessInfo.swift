// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

public struct OperatingSystemVersion {
    public var majorVersion: Int
    public var minorVersion: Int
    public var patchVersion: Int
    public init() {
        self.init(majorVersion: 0, minorVersion: 0, patchVersion: 0)
    }
    
    public init(majorVersion: Int, minorVersion: Int, patchVersion: Int) {
        self.majorVersion = majorVersion
        self.minorVersion = minorVersion
        self.patchVersion = patchVersion
    }
}



open class ProcessInfo: NSObject {
    
    public static let processInfo = ProcessInfo()
    
    internal override init() {
        
    }
    
    open var environment: [String : String] {
        let equalSign = Character("=")
        let strEncoding = String.defaultCStringEncoding
        let envp = _CFEnviron()
        var env: [String : String] = [:]
        var idx = 0

        while let entry = envp.advanced(by: idx).pointee {
            if let entry = String(cString: entry, encoding: strEncoding),
               let i = entry.firstIndex(of: equalSign) {
                let key = String(entry.prefix(upTo: i))
                let value = String(entry.suffix(from: i).dropFirst())
                env[key] = value
            }
            idx += 1
        }
        return env
    }
    
    open var arguments: [String] {
        return CommandLine.arguments // seems reasonable to flip the script here...
    }
    
    open var hostName: String {
        if let name = Host.current().name {
            return name
        } else {
            return "localhost"
        }
    }
    
    open var processName: String = _CFProcessNameString()._swiftObject
    
    open var processIdentifier: Int32 {
#if os(Windows)
        return Int32(GetProcessId(GetCurrentProcess()))
#else
        return Int32(getpid())
#endif
    }
    
    open var globallyUniqueString: String {
        let uuid = CFUUIDCreate(kCFAllocatorSystemDefault)
        return CFUUIDCreateString(kCFAllocatorSystemDefault, uuid)._swiftObject
    }

#if os(Windows)
    internal var _rawOperatingSystemVersionInfo: RTL_OSVERSIONINFOEXW? {
        guard let ntdll = ("ntdll.dll".withCString(encodedAs: UTF16.self) {
            LoadLibraryExW($0, nil, DWORD(LOAD_LIBRARY_SEARCH_SYSTEM32))
        }) else {
            return nil
        }
        defer { FreeLibrary(ntdll) }
        typealias RTLGetVersionTy = @convention(c) (UnsafeMutablePointer<RTL_OSVERSIONINFOEXW>) -> NTSTATUS
        guard let pfnRTLGetVersion = unsafeBitCast(GetProcAddress(ntdll, "RtlGetVersion"), to: Optional<RTLGetVersionTy>.self) else {
            return nil
        }
        var osVersionInfo = RTL_OSVERSIONINFOEXW()
        osVersionInfo.dwOSVersionInfoSize = DWORD(MemoryLayout<RTL_OSVERSIONINFOEXW>.size)
        guard pfnRTLGetVersion(&osVersionInfo) == 0 else {
            return nil
        }
        return osVersionInfo
    }
#endif

    open var operatingSystemVersionString: String {
        let fallback = "Unknown"
#if os(Linux)
        var utsNameBuffer = utsname()
        guard uname(&utsNameBuffer) == 0 else {
            return fallback
        }
        let release = withUnsafePointer(to: &utsNameBuffer.release.0) { String(cString: $0) }

        return release
#elseif os(Windows)
        guard let osVersionInfo = self._rawOperatingSystemVersionInfo else {
            return fallback
        }

        // Windows has no canonical way to turn the fairly complex `RTL_OSVERSIONINFOW` version info into a string. We
        // do our best here to construct something consistent. Unfortunately, to provide a useful result, this requires
        // hardcoding several of the somewhat ambiguous values in the table provided here:
        //  https://docs.microsoft.com/en-us/windows-hardware/drivers/ddi/wdm/ns-wdm-_osversioninfoexw#remarks
        var versionString = ""
        switch (osVersionInfo.dwMajorVersion, osVersionInfo.dwMinorVersion) {
            case (5, 0): versionString += "Windows 2000"
            case (5, 1): versionString += "Windows XP"
            case (5, 2) where osVersionInfo.wProductType == VER_NT_WORKSTATION: versionString += "Windows XP Professional x64"
            case (5, 2) where osVersionInfo.wSuiteMask == VER_SUITE_WH_SERVER: versionString += "Windows Home Server"
            case (5, 2): versionString += "Windows Server 2003"
            case (6, 0) where osVersionInfo.wProductType == VER_NT_WORKSTATION: versionString += "Windows Vista"
            case (6, 0): versionString += "Windows Server 2008"
            case (6, 1) where osVersionInfo.wProductType == VER_NT_WORKSTATION: versionString += "Windows 7"
            case (6, 1): versionString += "Windows Server 2008 R2"
            case (6, 2) where osVersionInfo.wProductType == VER_NT_WORKSTATION: versionString += "Windows 8"
            case (6, 2): versionString += "Windows Server 2012"
            case (6, 3) where osVersionInfo.wProductType == VER_NT_WORKSTATION: versionString += "Windows 8.1"
            case (6, 3): versionString += "Windows Server 2012 R2" // We assume the "10,0" numbers in the table for this are a typo
            case (10, 0) where osVersionInfo.wProductType == VER_NT_WORKSTATION: versionString += "Windows 10"
            case (10, 0): versionString += "Windows Server 2019" // The table gives identical values for 2016 and 2019, so we just assume 2019 here
            default: return fallback
        }
        versionString += " (build \(osVersionInfo.dwBuildNumber))"
        // For now we ignore the `szCSDVersion`, `wServicePackMajor`, and `wServicePackMinor` values.
        return versionString
#else
        return CFCopySystemVersionString()?._swiftObject ?? fallback
#endif
    }
    
    open var operatingSystemVersion: OperatingSystemVersion {
        // The following fallback values match Darwin Foundation
        let fallbackMajor = -1
        let fallbackMinor = 0
        let fallbackPatch = 0
        let versionString: String

#if canImport(Darwin)
        guard let systemVersionDictionary = _CFCopySystemVersionDictionary() else {
            return OperatingSystemVersion(majorVersion: fallbackMajor, minorVersion: fallbackMinor, patchVersion: fallbackPatch)
        }
        
        let productVersionKey = unsafeBitCast(_kCFSystemVersionProductVersionKey, to: UnsafeRawPointer.self)
        guard let productVersion = unsafeBitCast(CFDictionaryGetValue(systemVersionDictionary, productVersionKey), to: NSString?.self) else {
            return OperatingSystemVersion(majorVersion: fallbackMajor, minorVersion: fallbackMinor, patchVersion: fallbackPatch)
        }
        versionString = productVersion._swiftObject
#elseif os(Windows)
        guard let osVersionInfo = self._rawOperatingSystemVersionInfo else {
            return OperatingSystemVersion(majorVersion: fallbackMajor, minorVersion: fallbackMinor, patchVersion: fallbackPatch)
        }

        return OperatingSystemVersion(
            majorVersion: Int(osVersionInfo.dwMajorVersion),
            minorVersion: Int(osVersionInfo.dwMinorVersion),
            patchVersion: Int(osVersionInfo.dwBuildNumber)
        )
#else
        var utsNameBuffer = utsname()
        guard uname(&utsNameBuffer) == 0 else {
            return OperatingSystemVersion(majorVersion: fallbackMajor, minorVersion: fallbackMinor, patchVersion: fallbackPatch)
        }
        let release = withUnsafePointer(to: &utsNameBuffer.release.0) {
            return String(cString: $0)
        }
        let idx = release.firstIndex(of: "-") ?? release.endIndex
        versionString = String(release[..<idx])
#endif
        let versionComponents = versionString.split(separator: ".").map(String.init).compactMap({ Int($0) })
        let majorVersion = versionComponents.dropFirst(0).first ?? fallbackMajor
        let minorVersion = versionComponents.dropFirst(1).first ?? fallbackMinor
        let patchVersion = versionComponents.dropFirst(2).first ?? fallbackPatch
        return OperatingSystemVersion(majorVersion: majorVersion, minorVersion: minorVersion, patchVersion: patchVersion)
    }
    
    internal let _processorCount = __CFProcessorCount()
    open var processorCount: Int {
        return Int(_processorCount)
    }
    
    internal let _activeProcessorCount = __CFActiveProcessorCount()
    open var activeProcessorCount: Int {
        return Int(_activeProcessorCount)
    }
    
    internal let _physicalMemory = __CFMemorySize()
    open var physicalMemory: UInt64 {
        return _physicalMemory
    }
    
    open func isOperatingSystemAtLeast(_ version: OperatingSystemVersion) -> Bool {
        let ourVersion = operatingSystemVersion
        if ourVersion.majorVersion < version.majorVersion {
            return false
        }
        if ourVersion.majorVersion > version.majorVersion {
            return true
        }
        if ourVersion.minorVersion < version.minorVersion {
            return false
        }
        if ourVersion.minorVersion > version.minorVersion {
            return true
        }
        if ourVersion.patchVersion < version.patchVersion {
            return false
        }
        if ourVersion.patchVersion > version.patchVersion {
            return true
        }
        return true
    }
    
    open var systemUptime: TimeInterval {
        return CFGetSystemUptime()
    }
    
    open var userName: String {
        return NSUserName()
    }
    
    open var fullUserName: String {
        return NSFullUserName()
    }
}

// SPI for TestFoundation
internal extension ProcessInfo {
  var _processPath: String {
    return String(cString: _CFProcessPath())
  }
}
