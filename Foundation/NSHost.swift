// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


#if os(OSX) || os(iOS)
import Darwin
#elseif os(Linux)
import Glibc
#endif

import CoreFoundation

public class NSHost : NSObject {
    enum ResolveType {
        case Name
        case Address
        case Current
    }
    internal var _info: String?
    internal var _type: ResolveType
    internal var _resolved = false
    internal var _names = [String]()
    internal var _addresses = [String]()
    
    internal init(_ info: String?, _ type: ResolveType) {
        _info = info
        _type = type
    }
    
    static internal let current = NSHost(nil, .Current)
    
    public class func currentHost() -> NSHost {
        return NSHost.current
    }
    
    public convenience init(name: String?) {
        self.init(name, .Name)
    }
    
    public convenience init(address: String) {
        self.init(address, .Address)
    }
    
    public func isEqualToHost(aHost: NSHost) -> Bool {
        return false
    }
    
    internal func _resolveCurrent() {
        // TODO: cannot access getifaddrs here...
    }
    
    internal func _resolve() {
        if _resolved {
            return
        }
        if let info = _info {
            var flags: Int32 = 0
            switch (_type) {
            case .Name:
                flags = AI_PASSIVE | AI_CANONNAME
                break
            case .Address:
                flags = AI_PASSIVE | AI_CANONNAME | AI_NUMERICHOST
                break
            case .Current:
                _resolveCurrent()
                return
            }
            var hints = addrinfo()
            hints.ai_family = PF_UNSPEC
            hints.ai_socktype = _CF_SOCK_STREAM()
            hints.ai_flags = flags
            
            var res0: UnsafeMutablePointer<addrinfo> = nil
            let r = withUnsafeMutablePointers(&hints, &res0) { hintsPtr, res0Ptr in
                return getaddrinfo(info, nil, hintsPtr, res0Ptr)
            }
            if r != 0 {
                return
            }
            var res: UnsafeMutablePointer<addrinfo> = res0
            while res != nil {
                let family = res.memory.ai_family
                if family != AF_INET && family != AF_INET6 {
                    res = res.memory.ai_next
                    continue
                }
                let sa_len: socklen_t = socklen_t((family == AF_INET6) ? sizeof(sockaddr_in6) : sizeof(sockaddr_in))
                let lookupInfo = { (inout content: [String], flags: Int32) in
                    let hname = UnsafeMutablePointer<Int8>.alloc(1024)
                    if (getnameinfo(res.memory.ai_addr, sa_len, hname, 1024, nil, 0, flags) == 0) {
                        content.append(String(hname))
                    }
                    hname.destroy()
                    hname.dealloc(1024)
                }
                lookupInfo(&_addresses, NI_NUMERICHOST)
                lookupInfo(&_names, NI_NAMEREQD)
                lookupInfo(&_names, NI_NOFQDN|NI_NAMEREQD)
                res = res.memory.ai_next
            }
            
            freeaddrinfo(res0)
        }

    }
    
    public var name: String? {
        return names.first
    }
    
    public var names: [String] {
        _resolve()
        return _names
    }
    
    public var address: String? {
        return addresses.first
    }
    
    public var addresses: [String] {
        _resolve()
        return _addresses
    }
    
    public var localizedName: String? {
        return nil
    }
}

