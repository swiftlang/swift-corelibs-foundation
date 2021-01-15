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

    open var operatingSystemVersionString: String {
        let fallback = "Unknown"
#if os(Linux)
        let version = try? String(contentsOf: URL(fileURLWithPath: "/proc/version_signature", isDirectory: false), encoding: .utf8)
        return version ?? fallback
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
        guard let ntdll = ("ntdll.dll".withCString(encodedAs: UTF16.self) {
          LoadLibraryExW($0, nil, DWORD(LOAD_LIBRARY_SEARCH_SYSTEM32)) 
        }) else {
            return OperatingSystemVersion(majorVersion: fallbackMajor, minorVersion: fallbackMinor, patchVersion: fallbackPatch)
        }
        defer { FreeLibrary(ntdll) }
        typealias RTLGetVersionTy = @convention(c) (UnsafeMutablePointer<RTL_OSVERSIONINFOW>) -> NTSTATUS
        guard let pfnRTLGetVersion = unsafeBitCast(GetProcAddress(ntdll, "RtlGetVersion"), to: Optional<RTLGetVersionTy>.self) else {
            return OperatingSystemVersion(majorVersion: fallbackMajor, minorVersion: fallbackMinor, patchVersion: fallbackPatch)
        }
        var osVersionInfo = RTL_OSVERSIONINFOW()
        osVersionInfo.dwOSVersionInfoSize = DWORD(MemoryLayout<RTL_OSVERSIONINFOW>.size)
        guard pfnRTLGetVersion(&osVersionInfo) == 0 else {
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

    internal let _processorCount: Int = Int(__CFProcessorCount())
    open var processorCount: Int { _processorCount }

#if os(Linux)
    // coreCount takes into account cgroup information eg if running under Docker
    // __CFActiveProcessorCount uses sched_getaffinity() and sysconf(_SC_NPROCESSORS_ONLN)
    internal let _activeProcessorCount: Int = ProcessInfo.coreCount() ?? Int(__CFActiveProcessorCount())
#else
    internal let _activeProcessorCount: Int = Int(__CFActiveProcessorCount())
#endif

    open var activeProcessorCount: Int { _activeProcessorCount }

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


#if os(Linux)
    // Support for CFS quotas for cpu count as used by Docker.
    // Based on swift-nio code, https://github.com/apple/swift-nio/pull/1518
    private static let cfsQuotaPath = "/sys/fs/cgroup/cpu/cpu.cfs_quota_us"
    private static let cfsPeriodPath = "/sys/fs/cgroup/cpu/cpu.cfs_period_us"
    private static let cpuSetPath = "/sys/fs/cgroup/cpuset/cpuset.cpus"

    private static func firstLineOfFile(path: String) throws -> Substring {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        if let string = String(data: data, encoding: .utf8), let line = string.split(separator: "\n").first {
            return line
        } else {
            return ""
        }
    }

    // These are internal access for testing
    static func countCoreIds(cores: Substring) -> Int {
        let ids = cores.split(separator: "-", maxSplits: 1)
        guard let first = ids.first.flatMap({ Int($0, radix: 10) }),
              let last = ids.last.flatMap({ Int($0, radix: 10) }),
              last >= first
        else { preconditionFailure("cpuset format is incorrect") }
        return 1 + last - first
    }

    static func coreCount(cpuset cpusetPath: String) -> Int? {
        guard let cpuset = try? firstLineOfFile(path: cpusetPath).split(separator: ","),
              !cpuset.isEmpty
        else { return nil }

        return cpuset.map(countCoreIds).reduce(0, +)
    }

    static func coreCount(quota quotaPath: String,  period periodPath: String) -> Int? {
        guard let quota = try? Int(firstLineOfFile(path: quotaPath)),
              quota > 0
        else { return nil }
        guard let period = try? Int(firstLineOfFile(path: periodPath)),
              period > 0
        else { return nil }

        return (quota - 1 + period) / period // always round up if fractional CPU quota requested
    }

    private static func coreCount() -> Int? {
        if let quota = coreCount(quota: cfsQuotaPath, period: cfsPeriodPath) {
            return quota
        } else if let cpusetCount = coreCount(cpuset: cpuSetPath) {
            return cpusetCount
        } else {
            return nil
        }
    }
#endif
}

// SPI for TestFoundation
internal extension ProcessInfo {
  var _processPath: String {
    return String(cString: _CFProcessPath())
  }
}
