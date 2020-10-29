//===--- NSValue.swift - Bridging things in NSValue -----------*- swift -*-===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import CoreGraphics


extension NSRange: _ObjectiveCBridgeable {
  public func _bridgeToObjectiveC() -> NSValue {
    var myself = self
    return NSValue(bytes: &myself, objCType: _getObjCTypeEncoding(NSRange.self))
  }

  public static func _forceBridgeFromObjectiveC(_ source: NSValue,
                                                result: inout NSRange?) {
    precondition(strcmp(source.objCType,
                        _getObjCTypeEncoding(NSRange.self)) == 0,
                 "NSValue does not contain the right type to bridge to NSRange")
    result = NSRange()
    if #available(OSX 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *) {
      source.getValue(&result!, size: MemoryLayout<NSRange>.size)
    } else {
      source.getValue(&result!)
    }
  }

  public static func _conditionallyBridgeFromObjectiveC(_ source: NSValue,
                                                        result: inout NSRange?)
      -> Bool {
    if strcmp(source.objCType, _getObjCTypeEncoding(NSRange.self)) != 0 {
      result = nil
      return false
    }
    result = NSRange()
    if #available(OSX 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *) {
      source.getValue(&result!, size: MemoryLayout<NSRange>.size)
    } else {
      source.getValue(&result!)
    }
    return true
  }

  public static func _unconditionallyBridgeFromObjectiveC(_ source: NSValue?)
      -> NSRange {
    let unwrappedSource = source!
    precondition(strcmp(unwrappedSource.objCType,
                        _getObjCTypeEncoding(NSRange.self)) == 0,
                 "NSValue does not contain the right type to bridge to NSRange")
    var result = NSRange()
    if #available(OSX 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *) {
      unwrappedSource.getValue(&result, size: MemoryLayout<NSRange>.size)
    } else {
      unwrappedSource.getValue(&result)
    }
    return result
  }
}


extension CGRect: _ObjectiveCBridgeable {
  public func _bridgeToObjectiveC() -> NSValue {
    var myself = self
    return NSValue(bytes: &myself, objCType: _getObjCTypeEncoding(CGRect.self))
  }

  public static func _forceBridgeFromObjectiveC(_ source: NSValue,
                                                result: inout CGRect?) {
    precondition(strcmp(source.objCType,
                        _getObjCTypeEncoding(CGRect.self)) == 0,
                 "NSValue does not contain the right type to bridge to CGRect")
    result = CGRect()
    if #available(OSX 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *) {
      source.getValue(&result!, size: MemoryLayout<CGRect>.size)
    } else {
      source.getValue(&result!)
    }
  }

  public static func _conditionallyBridgeFromObjectiveC(_ source: NSValue,
                                                        result: inout CGRect?)
      -> Bool {
    if strcmp(source.objCType, _getObjCTypeEncoding(CGRect.self)) != 0 {
      result = nil
      return false
    }
    result = CGRect()
    if #available(OSX 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *) {
      source.getValue(&result!, size: MemoryLayout<CGRect>.size)
    } else {
      source.getValue(&result!)
    }
    return true
  }

  public static func _unconditionallyBridgeFromObjectiveC(_ source: NSValue?)
      -> CGRect {
    let unwrappedSource = source!
    precondition(strcmp(unwrappedSource.objCType,
                        _getObjCTypeEncoding(CGRect.self)) == 0,
                 "NSValue does not contain the right type to bridge to CGRect")
    var result = CGRect()
    if #available(OSX 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *) {
      unwrappedSource.getValue(&result, size: MemoryLayout<CGRect>.size)
    } else {
      unwrappedSource.getValue(&result)
    }
    return result
  }
}


extension CGPoint: _ObjectiveCBridgeable {
  public func _bridgeToObjectiveC() -> NSValue {
    var myself = self
    return NSValue(bytes: &myself, objCType: _getObjCTypeEncoding(CGPoint.self))
  }

  public static func _forceBridgeFromObjectiveC(_ source: NSValue,
                                                result: inout CGPoint?) {
    precondition(strcmp(source.objCType,
                        _getObjCTypeEncoding(CGPoint.self)) == 0,
                 "NSValue does not contain the right type to bridge to CGPoint")
    result = CGPoint()
    if #available(OSX 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *) {
      source.getValue(&result!, size: MemoryLayout<CGPoint>.size)
    } else {
      source.getValue(&result!)
    }
  }

  public static func _conditionallyBridgeFromObjectiveC(_ source: NSValue,
                                                        result: inout CGPoint?)
      -> Bool {
    if strcmp(source.objCType, _getObjCTypeEncoding(CGPoint.self)) != 0 {
      result = nil
      return false
    }
    result = CGPoint()
    if #available(OSX 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *) {
      source.getValue(&result!, size: MemoryLayout<CGPoint>.size)
    } else {
      source.getValue(&result!)
    }
    return true
  }

  public static func _unconditionallyBridgeFromObjectiveC(_ source: NSValue?)
      -> CGPoint {
    let unwrappedSource = source!
    precondition(strcmp(unwrappedSource.objCType,
                        _getObjCTypeEncoding(CGPoint.self)) == 0,
                 "NSValue does not contain the right type to bridge to CGPoint")
    var result = CGPoint()
    if #available(OSX 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *) {
      unwrappedSource.getValue(&result, size: MemoryLayout<CGPoint>.size)
    } else {
      unwrappedSource.getValue(&result)
    }
    return result
  }
}


extension CGVector: _ObjectiveCBridgeable {
  public func _bridgeToObjectiveC() -> NSValue {
    var myself = self
    return NSValue(bytes: &myself, objCType: _getObjCTypeEncoding(CGVector.self))
  }

  public static func _forceBridgeFromObjectiveC(_ source: NSValue,
                                                result: inout CGVector?) {
    precondition(strcmp(source.objCType,
                        _getObjCTypeEncoding(CGVector.self)) == 0,
                 "NSValue does not contain the right type to bridge to CGVector")
    result = CGVector()
    if #available(OSX 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *) {
      source.getValue(&result!, size: MemoryLayout<CGVector>.size)
    } else {
      source.getValue(&result!)
    }
  }

  public static func _conditionallyBridgeFromObjectiveC(_ source: NSValue,
                                                        result: inout CGVector?)
      -> Bool {
    if strcmp(source.objCType, _getObjCTypeEncoding(CGVector.self)) != 0 {
      result = nil
      return false
    }
    result = CGVector()
    if #available(OSX 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *) {
      source.getValue(&result!, size: MemoryLayout<CGVector>.size)
    } else {
      source.getValue(&result!)
    }
    return true
  }

  public static func _unconditionallyBridgeFromObjectiveC(_ source: NSValue?)
      -> CGVector {
    let unwrappedSource = source!
    precondition(strcmp(unwrappedSource.objCType,
                        _getObjCTypeEncoding(CGVector.self)) == 0,
                 "NSValue does not contain the right type to bridge to CGVector")
    var result = CGVector()
    if #available(OSX 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *) {
      unwrappedSource.getValue(&result, size: MemoryLayout<CGVector>.size)
    } else {
      unwrappedSource.getValue(&result)
    }
    return result
  }
}


extension CGSize: _ObjectiveCBridgeable {
  public func _bridgeToObjectiveC() -> NSValue {
    var myself = self
    return NSValue(bytes: &myself, objCType: _getObjCTypeEncoding(CGSize.self))
  }

  public static func _forceBridgeFromObjectiveC(_ source: NSValue,
                                                result: inout CGSize?) {
    precondition(strcmp(source.objCType,
                        _getObjCTypeEncoding(CGSize.self)) == 0,
                 "NSValue does not contain the right type to bridge to CGSize")
    result = CGSize()
    if #available(OSX 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *) {
      source.getValue(&result!, size: MemoryLayout<CGSize>.size)
    } else {
      source.getValue(&result!)
    }
  }

  public static func _conditionallyBridgeFromObjectiveC(_ source: NSValue,
                                                        result: inout CGSize?)
      -> Bool {
    if strcmp(source.objCType, _getObjCTypeEncoding(CGSize.self)) != 0 {
      result = nil
      return false
    }
    result = CGSize()
    if #available(OSX 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *) {
      source.getValue(&result!, size: MemoryLayout<CGSize>.size)
    } else {
      source.getValue(&result!)
    }
    return true
  }

  public static func _unconditionallyBridgeFromObjectiveC(_ source: NSValue?)
      -> CGSize {
    let unwrappedSource = source!
    precondition(strcmp(unwrappedSource.objCType,
                        _getObjCTypeEncoding(CGSize.self)) == 0,
                 "NSValue does not contain the right type to bridge to CGSize")
    var result = CGSize()
    if #available(OSX 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *) {
      unwrappedSource.getValue(&result, size: MemoryLayout<CGSize>.size)
    } else {
      unwrappedSource.getValue(&result)
    }
    return result
  }
}


extension CGAffineTransform: _ObjectiveCBridgeable {
  public func _bridgeToObjectiveC() -> NSValue {
    var myself = self
    return NSValue(bytes: &myself, objCType: _getObjCTypeEncoding(CGAffineTransform.self))
  }

  public static func _forceBridgeFromObjectiveC(_ source: NSValue,
                                                result: inout CGAffineTransform?) {
    precondition(strcmp(source.objCType,
                        _getObjCTypeEncoding(CGAffineTransform.self)) == 0,
                 "NSValue does not contain the right type to bridge to CGAffineTransform")
    result = CGAffineTransform()
    if #available(OSX 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *) {
      source.getValue(&result!, size: MemoryLayout<CGAffineTransform>.size)
    } else {
      source.getValue(&result!)
    }
  }

  public static func _conditionallyBridgeFromObjectiveC(_ source: NSValue,
                                                        result: inout CGAffineTransform?)
      -> Bool {
    if strcmp(source.objCType, _getObjCTypeEncoding(CGAffineTransform.self)) != 0 {
      result = nil
      return false
    }
    result = CGAffineTransform()
    if #available(OSX 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *) {
      source.getValue(&result!, size: MemoryLayout<CGAffineTransform>.size)
    } else {
      source.getValue(&result!)
    }
    return true
  }

  public static func _unconditionallyBridgeFromObjectiveC(_ source: NSValue?)
      -> CGAffineTransform {
    let unwrappedSource = source!
    precondition(strcmp(unwrappedSource.objCType,
                        _getObjCTypeEncoding(CGAffineTransform.self)) == 0,
                 "NSValue does not contain the right type to bridge to CGAffineTransform")
    var result = CGAffineTransform()
    if #available(OSX 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *) {
      unwrappedSource.getValue(&result, size: MemoryLayout<CGAffineTransform>.size)
    } else {
      unwrappedSource.getValue(&result)
    }
    return result
  }
}


extension NSValue {
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func value<StoredType>(of type: StoredType.Type) -> StoredType? {
        if StoredType.self is AnyObject.Type {
            let encoding = String(cString: objCType)
            // some subclasses of NSValue can return @ and the default initialized variant returns ^v for encoding
            guard encoding == "^v" || encoding == "@" else {
                return nil
            }
            return nonretainedObjectValue as? StoredType
        } else if _isPOD(StoredType.self) {
            var storedSize = 0
            var storedAlignment = 0
            NSGetSizeAndAlignment(objCType, &storedSize, &storedAlignment)
            guard MemoryLayout<StoredType>.size == storedSize && MemoryLayout<StoredType>.alignment == storedAlignment else {
                return nil
            }
            let allocated = UnsafeMutablePointer<StoredType>.allocate(capacity: 1)
            defer { allocated.deallocate() }
            getValue(allocated, size: storedSize)
            return allocated.pointee
        }
        return nil
    }
}
