// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

internal let kCFRunLoopEntry = CFRunLoopActivity.entry.rawValue
internal let kCFRunLoopBeforeTimers = CFRunLoopActivity.beforeTimers.rawValue
internal let kCFRunLoopBeforeSources = CFRunLoopActivity.beforeSources.rawValue
internal let kCFRunLoopBeforeWaiting = CFRunLoopActivity.beforeWaiting.rawValue
internal let kCFRunLoopAfterWaiting = CFRunLoopActivity.afterWaiting.rawValue
internal let kCFRunLoopExit = CFRunLoopActivity.exit.rawValue
internal let kCFRunLoopAllActivities = CFRunLoopActivity.allActivities.rawValue

extension RunLoop {
    public struct Mode : RawRepresentable, Equatable, Hashable {
        public private(set) var rawValue: String

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
}

extension RunLoop.Mode {
    public static let `default`: RunLoop.Mode = RunLoop.Mode("kCFRunLoopDefaultMode")
    public static let common: RunLoop.Mode = RunLoop.Mode("kCFRunLoopCommonModes")
    
    // Use this instead of .rawValue._cfObject; this will allow CFRunLoop to use pointer equality internally.
    fileprivate var _cfStringUniquingKnown: CFString {
        if self == .default {
            return kCFRunLoopDefaultMode
        } else if self == .common {
            return kCFRunLoopCommonModes
        } else {
            return rawValue._cfObject
        }
    }
}

internal func _NSRunLoopNew(_ cf: CFRunLoop) -> Unmanaged<AnyObject> {
    let rl = Unmanaged<RunLoop>.passRetained(RunLoop(cfObject: cf))
    return unsafeBitCast(rl, to: Unmanaged<AnyObject>.self) // this retain is balanced on the other side of the CF fence
}

open class RunLoop: NSObject {
    internal var _cfRunLoop : CFRunLoop!
    internal static var _mainRunLoop : RunLoop = {
        return RunLoop(cfObject: CFRunLoopGetMain())
    }()

    internal init(cfObject : CFRunLoop) {
        _cfRunLoop = cfObject
    }

    open class var current: RunLoop {
        return _CFRunLoopGet2(CFRunLoopGetCurrent()) as! RunLoop
    }

    open class var main: RunLoop {
        return _CFRunLoopGet2(CFRunLoopGetMain()) as! RunLoop
    }

    open var currentMode: RunLoop.Mode? {
        if let mode = CFRunLoopCopyCurrentMode(_cfRunLoop) {
            return RunLoop.Mode(mode._swiftObject)
        } else {
            return nil
        }
    }
    
    open func getCFRunLoop() -> CFRunLoop {
        return _cfRunLoop
    }

    open func add(_ timer: Timer, forMode mode: RunLoop.Mode) {
        CFRunLoopAddTimer(_cfRunLoop, timer._cfObject, mode._cfStringUniquingKnown)
    }

    private let monitoredPortsWithModesLock = NSLock() // guards:
    private var monitoredPortsWithModes: [Port: Set<RunLoop.Mode>] = [:]
    private var monitoredPortObservers:  [Port: NSObjectProtocol]  = [:]
    
    open func add(_ aPort: Port, forMode mode: RunLoop.Mode) {
        var shouldSchedule = false
        monitoredPortsWithModesLock.synchronized {
            if monitoredPortsWithModes[aPort]?.contains(mode) != true {
                monitoredPortsWithModes[aPort, default: []].insert(mode)
                
                let shouldStartMonitoring = monitoredPortObservers[aPort] == nil
                if shouldStartMonitoring {
                    monitoredPortObservers[aPort] = NotificationCenter.default.addObserver(forName: Port.didBecomeInvalidNotification, object: aPort, queue: nil, using: { [weak self] (notification) in
                        self?.portDidInvalidate(aPort)
                    })
                }
                
                shouldSchedule = true
            }
        }
        
        if shouldSchedule {
            aPort.schedule(in: self, forMode: mode)
        }
    }
    
    private func portDidInvalidate(_ aPort: Port) {
        monitoredPortsWithModesLock.synchronized {
            if let observer = monitoredPortObservers.removeValue(forKey: aPort) {
                NotificationCenter.default.removeObserver(observer)
            }
            monitoredPortsWithModes.removeValue(forKey: aPort)
        }
    }

    open func remove(_ aPort: Port, forMode mode: RunLoop.Mode) {
        var shouldRemove = false
        monitoredPortsWithModesLock.synchronized {
            guard let modes = monitoredPortsWithModes[aPort], modes.contains(mode) else {
                return
            }
            
            shouldRemove = true
            
            if modes.count == 1 {
                if let observer = monitoredPortObservers.removeValue(forKey: aPort) {
                    NotificationCenter.default.removeObserver(observer)
                }
                monitoredPortsWithModes.removeValue(forKey: aPort)
            } else {
                monitoredPortsWithModes[aPort]?.remove(mode)
            }
        }
        
        if shouldRemove {
            aPort.remove(from: self, forMode: mode)
        }
    }

    open func limitDate(forMode mode: RunLoop.Mode) -> Date? {
        if _cfRunLoop !== CFRunLoopGetCurrent() {
            return nil
        }
        let modeArg = mode.rawValue._cfObject
        
        CFRunLoopRunInMode(modeArg, -10.0, true) /* poll run loop to fire ready timers and performers, as used to be done here */
        if _CFRunLoopFinished(_cfRunLoop, modeArg) {
            return nil
        }
        
        let nextTimerFireAbsoluteTime = CFRunLoopGetNextTimerFireDate(CFRunLoopGetCurrent(), modeArg)

        if (nextTimerFireAbsoluteTime == 0) {
            return Date.distantFuture
        }

        return Date(timeIntervalSinceReferenceDate: nextTimerFireAbsoluteTime)
    }

    open func acceptInput(forMode mode: String, before limitDate: Date) {
        if _cfRunLoop !== CFRunLoopGetCurrent() {
            return
        }
        CFRunLoopRunInMode(mode._cfObject, limitDate.timeIntervalSinceReferenceDate - CFAbsoluteTimeGetCurrent(), true)
    }

}

extension RunLoop {

    public func run() {
        while run(mode: .default, before: Date.distantFuture) { }
    }

    public func run(until limitDate: Date) {
        while run(mode: .default, before: limitDate) && limitDate.timeIntervalSinceReferenceDate > CFAbsoluteTimeGetCurrent() { }
    }

    public func run(mode: RunLoop.Mode, before limitDate: Date) -> Bool {
        if _cfRunLoop !== CFRunLoopGetCurrent() {
            return false
        }
        let modeArg = mode._cfStringUniquingKnown
        if _CFRunLoopFinished(_cfRunLoop, modeArg) {
            return false
        }
        
        let limitTime = limitDate.timeIntervalSinceReferenceDate
        let ti = limitTime - CFAbsoluteTimeGetCurrent()
        CFRunLoopRunInMode(modeArg, ti, true)
        return true
    }

    public func perform(inModes modes: [RunLoop.Mode], block: @escaping () -> Void) {
        CFRunLoopPerformBlock(getCFRunLoop(), (modes.map { $0._cfStringUniquingKnown })._cfObject, block)
    }
    
    public func perform(_ block: @escaping () -> Void) {
        perform(inModes: [.default], block: block)
    }
}

// SPI for XCTest
#if os(Windows)
extension RunLoop {
  public func _stop() {
    CFRunLoopStop(getCFRunLoop())
  }
}
#endif

