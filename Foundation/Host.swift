// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

open class Host: NSObject {
    enum ResolveType {
        case name
        case address
        case current
    }
    internal var _info: String?
    internal var _type: ResolveType
    internal var _resolved = false
    internal var _names = [String]()
    internal var _addresses = [String]()
    
#if os(Android)
    static internal let NI_MAXHOST = 1025
#endif
    
    static internal let _current = Host(currentHostName(), .current)
    
    internal init(_ info: String?, _ type: ResolveType) {
        _info = info
        _type = type
    }
    
    static internal func currentHostName() -> String {
#if os(Windows)
      var dwLength: DWORD = 0
      GetComputerNameExA(ComputerNameDnsHostname, nil, &dwLength)
      guard dwLength > 0 else { return "localhost" }

      guard let hostname: UnsafeMutablePointer<Int8> =
          UnsafeMutableBufferPointer<Int8>
              .allocate(capacity: Int(dwLength + 1))
              .baseAddress else {
        return "localhost"
      }
      defer { hostname.deallocate() }
      guard GetComputerNameExA(ComputerNameDnsHostname, hostname, &dwLength) != FALSE else {
        return "localhost"
      }
      return String(cString: hostname)
#else
        let hname = UnsafeMutablePointer<Int8>.allocate(capacity: Int(NI_MAXHOST))
        defer {
            hname.deallocate()
        }
        let r = gethostname(hname, Int(NI_MAXHOST))
        if r < 0 || hname[0] == 0 {
            return "localhost"
        }
        return String(cString: hname)
#endif
    }
    
    open class func current() -> Host {
        return _current
    }
    
    public convenience init(name: String?) {
        self.init(name, .name)
    }
    
    public convenience init(address: String) {
        self.init(address, .address)
    }
    
    open func isEqual(to aHost: Host) -> Bool {
        return false
    }
    
    internal func _resolveCurrent() {
#if os(Android)
        return
#elseif os(Windows)
        var ulSize: ULONG = 0
        var ulResult: ULONG =
            GetAdaptersAddresses(ULONG(AF_UNSPEC), 0, nil, nil, &ulSize)

        let arAdapterInfo: UnsafeMutablePointer<IP_ADAPTER_ADDRESSES> =
            UnsafeMutablePointer<IP_ADAPTER_ADDRESSES_LH>
                .allocate(capacity: Int(ulSize) / MemoryLayout<IP_ADAPTER_ADDRESSES>.size)
        defer { arAdapterInfo.deallocate() }

        ulResult = GetAdaptersAddresses(ULONG(AF_UNSPEC), 0, nil, arAdapterInfo, &ulSize)

        var buffer: UnsafeMutablePointer<WCHAR> =
            UnsafeMutablePointer<WCHAR>.allocate(capacity: Int(NI_MAXHOST))
        defer { buffer.deallocate() }

        var arCurrentAdapterInfo: UnsafeMutablePointer<IP_ADAPTER_ADDRESSES>? =
          arAdapterInfo
        while arCurrentAdapterInfo != nil {
          var arAddress: UnsafeMutablePointer<IP_ADAPTER_UNICAST_ADDRESS>? =
              arCurrentAdapterInfo!.pointee.FirstUnicastAddress
          while arAddress != nil {
            let arCurrentAddress: IP_ADAPTER_UNICAST_ADDRESS = arAddress!.pointee
            switch arCurrentAddress.Address.lpSockaddr.pointee.sa_family {
            case ADDRESS_FAMILY(AF_INET), ADDRESS_FAMILY(AF_INET6):
              if GetNameInfoW(arCurrentAddress.Address.lpSockaddr,
                              arCurrentAddress.Address.iSockaddrLength,
                              buffer, DWORD(NI_MAXHOST),
                              nil, 0, NI_NUMERICHOST) == 0 {
                _addresses.append(String(decodingCString: buffer,
                                         as: UTF16.self))
              }
            default: break
            }
            arAddress = arCurrentAddress.Next
          }
          arCurrentAdapterInfo = arCurrentAdapterInfo!.pointee.Next
        }
        _resolved = true
#else
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) != 0 {
            return
        }
        var ifa: UnsafeMutablePointer<ifaddrs>? = ifaddr
        let address = UnsafeMutablePointer<Int8>.allocate(capacity: Int(NI_MAXHOST))
        defer {
            freeifaddrs(ifaddr)
            address.deallocate()
        }
        while let ifaValue = ifa?.pointee {
            if let ifa_addr = ifaValue.ifa_addr, ifaValue.ifa_flags & UInt32(IFF_LOOPBACK) == 0 {
                let family = ifa_addr.pointee.sa_family
                if family == sa_family_t(AF_INET) || family == sa_family_t(AF_INET6) {
                    let sa_len: socklen_t = socklen_t((family == sa_family_t(AF_INET6)) ? MemoryLayout<sockaddr_in6>.size : MemoryLayout<sockaddr_in>.size)
                    if getnameinfo(ifa_addr, sa_len, address, socklen_t(NI_MAXHOST), nil, 0, NI_NUMERICHOST) == 0 {
                        _addresses.append(String(cString: address))
                    }
                }
            }
            ifa = ifaValue.ifa_next
        }
        _resolved = true
#endif
    }
    
    internal func _resolve() {
        guard _resolved == false else { return }
#if os(Android)
        return
#elseif os(Windows)
        if let info = _info {
          if _type == .current { return _resolveCurrent() }

          var hints: ADDRINFOW = ADDRINFOW()
          memset(&hints, 0, MemoryLayout<ADDRINFOW>.size)

          switch (_type) {
          case .name:
            hints.ai_flags = AI_PASSIVE | AI_CANONNAME
          case .address:
            hints.ai_flags = AI_PASSIVE | AI_CANONNAME | AI_NUMERICHOST
          case .current:
            break
          }
          hints.ai_family = AF_UNSPEC
          hints.ai_socktype = SOCK_STREAM
          hints.ai_protocol = IPPROTO_TCP.rawValue

          var aiResult: UnsafeMutablePointer<ADDRINFOW>?
          var bSucceeded: Bool = false
          info.withCString(encodedAs: UTF16.self) {
            if GetAddrInfoW($0, nil, &hints, &aiResult) == 0 {
              bSucceeded = true
            }
          }
          guard bSucceeded == true else { return }
          defer { FreeAddrInfoW(aiResult) }

          let wszHostName =
              UnsafeMutablePointer<WCHAR>.allocate(capacity: Int(NI_MAXHOST))
          defer { wszHostName.deallocate() }

          while aiResult != nil {
            let aiInfo: ADDRINFOW = aiResult!.pointee
            var sa_len: socklen_t = 0

            switch aiInfo.ai_family {
            case AF_INET:
              sa_len = socklen_t(MemoryLayout<sockaddr_in>.size)
            case AF_INET6:
              sa_len = socklen_t(MemoryLayout<sockaddr_in6>.size)
            default:
              aiResult = aiInfo.ai_next
              continue
            }

            let lookup = { (content: inout [String], flags: Int32) in
              if GetNameInfoW(aiInfo.ai_addr, sa_len, wszHostName,
                              DWORD(NI_MAXHOST), nil, 0, flags) == 0 {
                content.append(String(decodingCString: wszHostName,
                                      as: UTF16.self))
              }
            }

            lookup(&_addresses, NI_NUMERICHOST)
            lookup(&_names, NI_NAMEREQD)
            lookup(&_names, NI_NOFQDN | NI_NAMEREQD)

            aiResult = aiInfo.ai_next
          }

          _resolved = true
        }
#else
        if let info = _info {
            var flags: Int32 = 0
            switch (_type) {
            case .name:
                flags = AI_PASSIVE | AI_CANONNAME
            case .address:
                flags = AI_PASSIVE | AI_CANONNAME | AI_NUMERICHOST
            case .current:
                _resolveCurrent()
                return
            }
            var hints = addrinfo()
            hints.ai_family = PF_UNSPEC
#if os(macOS) || os(iOS) || os(Android)
            hints.ai_socktype = SOCK_STREAM
#else
            hints.ai_socktype = Int32(SOCK_STREAM.rawValue)
#endif
    
            hints.ai_flags = flags
            
            var res0: UnsafeMutablePointer<addrinfo>? = nil
            let r = getaddrinfo(info, nil, &hints, &res0)
            defer {
                freeaddrinfo(res0)
            }
            if r != 0 {
                return
            }
            var res: UnsafeMutablePointer<addrinfo>? = res0
            let host = UnsafeMutablePointer<Int8>.allocate(capacity: Int(NI_MAXHOST))
            defer {
                host.deallocate()
            }
            while res != nil {
                let info = res!.pointee
                let family = info.ai_family
                if family != AF_INET && family != AF_INET6 {
                    res = info.ai_next
                    continue
                }
                let sa_len: socklen_t = socklen_t((family == AF_INET6) ? MemoryLayout<sockaddr_in6>.size : MemoryLayout<sockaddr_in>.size)
                let lookupInfo = { (content: inout [String], flags: Int32) in
                    if getnameinfo(info.ai_addr, sa_len, host, socklen_t(NI_MAXHOST), nil, 0, flags) == 0 {
                        content.append(String(cString: host))
                    }
                }
                lookupInfo(&_addresses, NI_NUMERICHOST)
                lookupInfo(&_names, NI_NAMEREQD)
                lookupInfo(&_names, NI_NOFQDN|NI_NAMEREQD)
                res = info.ai_next
            }
            _resolved = true
        }
#endif   
    }
    
    open var name: String? {
        return names.first
    }
    
    open var names: [String] {
        _resolve()
        return _names
    }
    
    open var address: String? {
        return addresses.first
    }
    
    open var addresses: [String] {
        _resolve()
        return _addresses
    }
    
    open var localizedName: String? {
        return nil
    }
}
