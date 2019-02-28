// This source file is part of the Swift.org open source project
//
// Copyright (c) 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

extension CharacterSet {
    fileprivate func contains(_ character: Character) -> Bool {
        return character.unicodeScalars.allSatisfy(self.contains(_:))
    }
}

// -----

@available(swift 5.0)
extension Scanner {
    public enum NumberRepresentation {
        case decimal // See the %d, %f and %F format conversions.
        case hexadecimal // See the %x, %X, %a and %A format conversions. For integers, a leading 0x or 0X is optional; for floating-point numbers, it is required.
    }
    
    public var currentIndex: String.Index {
        get {
            let string = self.string
            var index = string._toUTF16Index(scanLocation)
            
            var delta = 0
            while index != string.endIndex && index.samePosition(in: string) == nil {
                delta += 1
                index = string._toUTF16Index(scanLocation + delta)
            }
            
            return index
        }
        set { scanLocation = string._toUTF16Offset(newValue) }
    }
    
    public func scanInt(representation: NumberRepresentation = .decimal) -> Int? {
        #if arch(x86_64) || arch(arm64) || arch(s390x) || arch(powerpc64) || arch(powerpc64le)
        if let value = scanInt64(representation: representation) {
            return Int(value)
        }
        #elseif arch(i386) || arch(arm)
        if let value = scanInt32(representation: representation) {
            return Int(value)
        }
        #else
        #error("This architecture isn't known. Add it to the 32-bit or 64-bit line; if the machine word isn't either of those, you need to implement appropriate scanning and handle the potential overflow here.")
        #endif
        return nil
    }
    
    public func scanInt32(representation: NumberRepresentation = .decimal) -> Int32? {
        var value = Int32.max
        switch representation {
        case .decimal: guard self.scanInt32(&value) else { return nil }
        default:
            var overflowingValue = UInt32.max
            guard self.scanHexInt32(&overflowingValue) else { return nil }
            if overflowingValue < Int32.max {
                value = Int32(overflowingValue)
            }
        }
        return value
    }
    
    public func scanInt64(representation: NumberRepresentation = .decimal) -> Int64? {
        var value = Int64.max
        switch representation {
        case .decimal: guard self.scanInt64(&value) else { return nil }
        case .hexadecimal:
            var overflowingValue = UInt64.max
            guard self.scanHexInt64(&overflowingValue) else { return nil }
            if overflowingValue < Int64.max {
                value = Int64(overflowingValue)
            }
        }
        return value
    }
    
    public func scanUInt64(representation: NumberRepresentation = .decimal) -> UInt64? {
        var value = UInt64.max
        switch representation {
        case .decimal: guard self.scanUnsignedLongLong(&value) else { return nil }
        case .hexadecimal: guard self.scanHexInt64(&value) else { return nil }
        }
        return value
    }
    
    public func scanFloat(representation: NumberRepresentation = .decimal) -> Float? {
        var value = Float.greatestFiniteMagnitude
        switch representation {
        case .decimal: guard self.scanFloat(&value) else { return nil }
        case .hexadecimal: guard self.scanHexFloat(&value) else { return nil }
        }
        return value
    }
    
    public func scanDouble(representation: NumberRepresentation = .decimal) -> Double? {
        var value = Double.greatestFiniteMagnitude
        switch representation {
        case .decimal: guard self.scanDouble(&value) else { return nil }
        case .hexadecimal: guard self.scanHexDouble(&value) else { return nil }
        }
        return value
    }
    
    fileprivate var _currentIndexAfterSkipping: String.Index {
        guard let skips = charactersToBeSkipped else { return currentIndex }
        
        let index = string[currentIndex...].firstIndex(where: { !skips.contains($0) })
        return index ?? string.endIndex
    }
    
    public func scanString(_ searchString: String) -> String? {
        let currentIndex = _currentIndexAfterSkipping
        
        guard let substringEnd = string.index(currentIndex, offsetBy: searchString.count, limitedBy: string.endIndex) else { return nil }
        
        if string.compare(searchString, options: self.caseSensitive ? [] : .caseInsensitive, range: currentIndex ..< substringEnd, locale: self.locale as? Locale) == .orderedSame {
            let it = string[currentIndex ..< substringEnd]
            self.currentIndex = substringEnd
            return String(it)
        } else {
            return nil
        }
    }
    
    public func scanCharacters(from set: CharacterSet) -> String? {
        let currentIndex = _currentIndexAfterSkipping
        
        let substringEnd = string[currentIndex...].firstIndex(where: { !set.contains($0) }) ?? string.endIndex
        guard currentIndex != substringEnd else { return nil }
        
        let substring = string[currentIndex ..< substringEnd]
        self.currentIndex = substringEnd
        return String(substring)
    }
    
    public func scanUpToString(_ substring: String) -> String? {
        guard !substring.isEmpty else { return nil }
        let string = self.string
        let startIndex = _currentIndexAfterSkipping
        
        var beginningOfNewString = string.endIndex
        var currentSearchIndex = startIndex
        
        repeat {
            guard let range = string.range(of: substring, options: self.caseSensitive ? [] : .caseInsensitive, range: currentSearchIndex ..< string.endIndex, locale: self.locale as? Locale) else {
                // If the string isn't found at all, it means it's not in the string. Just take everything to the end.
                beginningOfNewString = string.endIndex
                break
            }
            
            // range(of:…) can return partial grapheme ranges when dealing with emoji.
            // Make sure we take a range only if it doesn't split a grapheme in the string.
            if let maybeBeginning = range.lowerBound.samePosition(in: string),
                range.upperBound.samePosition(in: string) != nil {
                beginningOfNewString = maybeBeginning
                break
            }
            
            // If we got here, we need to search again starting from just after the location we found.
            currentSearchIndex = range.upperBound
        } while beginningOfNewString == string.endIndex && currentSearchIndex < string.endIndex
        
        guard startIndex != beginningOfNewString else { return nil }
        
        let foundSubstring = string[startIndex ..< beginningOfNewString]
        self.currentIndex = beginningOfNewString
        return String(foundSubstring)
    }
    
    public func scanUpToCharacters(from set: CharacterSet) -> String? {
        let currentIndex = _currentIndexAfterSkipping
        let string = self.string
        
        let firstCharacterInSet = string[currentIndex...].firstIndex(where: { set.contains($0) }) ?? string.endIndex
        guard currentIndex != firstCharacterInSet else { return nil }
        self.currentIndex = firstCharacterInSet
        return String(string[currentIndex ..< firstCharacterInSet])
    }
    
    public func scanCharacter() -> Character? {
        let currentIndex = _currentIndexAfterSkipping
        
        let string = self.string
        
        guard currentIndex != string.endIndex else { return nil }
        
        let character = string[currentIndex]
        self.currentIndex = string.index(after: currentIndex)
        return character
    }
}
