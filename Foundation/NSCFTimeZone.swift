//
//  NSCFTimeZone.swift
//  SwiftFoundation
//
//  Created by Philippe Hausler on 7/5/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import CoreFoundation

internal final class __NSTimeZone : NSTimeZone {
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override var name: String {
        return String(_unsafeReferenceCast(CFTimeZoneGetName(_unsafeReferenceCast(self, to: CFTimeZone.self)), to: NSString.self))
    }
    
    override var data: Data {
        return Data(referencing:
        _unsafeReferenceCast(CFTimeZoneGetData(_unsafeReferenceCast(self, to: CFTimeZone.self)), to: NSData.self))
    }
    
    override func secondsFromGMT(for aDate: Date) -> Int {
        return Int(CFTimeZoneGetSecondsFromGMT(_unsafeReferenceCast(self, to: CFTimeZone.self), aDate.timeIntervalSinceReferenceDate))
    }
    
    override func abbreviation(for aDate: Date) -> String? {
        guard let abbr = CFTimeZoneCopyAbbreviation(_unsafeReferenceCast(self, to: CFTimeZone.self), aDate.timeIntervalSinceReferenceDate) else {
            return nil
        }
        return String(_unsafeReferenceCast(abbr, to: NSString.self))
    }
    
    override func isDaylightSavingTime(for aDate: Date) -> Bool {
        return CFTimeZoneIsDaylightSavingTime(_unsafeReferenceCast(self, to: CFTimeZone.self), aDate.timeIntervalSinceReferenceDate)
    }
    
    override func daylightSavingTimeOffset(for aDate: Date) -> TimeInterval {
        return CFTimeZoneGetDaylightSavingTimeOffset(_unsafeReferenceCast(self, to: CFTimeZone.self), aDate.timeIntervalSinceReferenceDate)
    }
    
    override func nextDaylightSavingTimeTransition(after aDate: Date) -> Date? {
        return Date(timeIntervalSinceReferenceDate: CFTimeZoneGetNextDaylightSavingTimeTransition(_unsafeReferenceCast(self, to: CFTimeZone.self), aDate.timeIntervalSinceReferenceDate))
    }
}
