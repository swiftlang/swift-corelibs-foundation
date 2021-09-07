//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension AttributedString.Guts {
    internal struct RunOffset {
        fileprivate var location: Int = 0
        fileprivate var block: Int = 0
    }
    
    // MARK: - Helper Functions
    
    /// Retrieve the UTF-8 `location` and `block` index of the run containing the UTF-8 `location`, and update the cache accordingly
    @discardableResult
    private func seekToRun(location: Int) -> RunOffset {
        var currentLocation = 0
        var currentBlock = 0
        
        runOffsetCacheLock.lock()
        defer { runOffsetCacheLock.unlock() }
        
        if location > runOffsetCache.location / 2 {
            currentLocation = runOffsetCache.location
            currentBlock = runOffsetCache.block
        }
        
        if currentLocation <= location {
            while currentBlock < runs.count && currentLocation + runs[currentBlock].length <= location {
                currentLocation += runs[currentBlock].length
                currentBlock += 1
            }
        } else {
            repeat {
                currentBlock -= 1
                currentLocation -= runs[currentBlock].length
            } while currentLocation > location && currentBlock >= 0
        }
        
        let currentOffset = RunOffset(location: currentLocation, block: currentBlock)
        runOffsetCache = currentOffset
        return currentOffset
    }
    
    /// Retrieve the UTF-8 `location` and `block` index of the run at the `rangeIndex` block, and update the cache accordingly
    @discardableResult
    private func seekToRun(rangeIndex: Int) -> RunOffset {
        runOffsetCacheLock.lock()
        defer { runOffsetCacheLock.unlock() }
        return seekToRunAlreadyLocked(rangeIndex: rangeIndex)
    }
    
    /// Retrieve the UTF-8 `location` and `block` index of the run at the `rangeIndex` block, and update the cache accordingly
    @discardableResult
    private func seekToRunAlreadyLocked(rangeIndex: Int) -> RunOffset {
        var currentLocation = 0
        var currentBlock = 0
        
        if rangeIndex > runOffsetCache.block / 2 {
            currentLocation = runOffsetCache.location
            currentBlock = runOffsetCache.block
        }
        
        if currentBlock <= rangeIndex {
            while currentBlock != rangeIndex {
                currentLocation += runs[currentBlock].length
                currentBlock += 1
            }
        } else {
            repeat {
                currentBlock -= 1
                currentLocation -= runs[currentBlock].length
            } while currentBlock != rangeIndex
        }
        
        let currentOffset = RunOffset(location: currentLocation, block: currentBlock)
        runOffsetCache = currentOffset
        return currentOffset
    }
    
    /// Update the run at the given block `index` with the provided `run` and coalesce it with its neighbors if necessary.
    /// - Returns: The new index of the updated run (potentially different from the provided `index` due to coalescing)
    @discardableResult
    func updateAndCoalesce(run: AttributedString._InternalRun, at index: Int) -> Int {
        runOffsetCacheLock.lock()
        defer { runOffsetCacheLock.unlock() }
        if runOffsetCache.block > index {
            runOffsetCache.location += run.length - runs[index].length
        }
        runs[index] = run
        
        if index < runs.count - 1 && run.attributes == runs[index + 1].attributes {
            if runOffsetCache.block == index + 1 {
                runOffsetCache.location += runs[index + 1].length
            } else if runOffsetCache.block > index + 1{
                runOffsetCache.block -= 1
            }
            runs[index].length += runs[index + 1].length
            runs.remove(at: index + 1)
        }
        var newIndex = index
        if index > 0 && run.attributes == runs[index - 1].attributes {
            if runOffsetCache.block == index {
                runOffsetCache.location += runs[index].length
            } else if runOffsetCache.block > index {
                runOffsetCache.block -= 1
            }
            runs[index - 1].length += runs[index].length
            runs.remove(at: index)
            newIndex -= 1
        }
        return newIndex
    }
    
    func runAndLocation(at index: Int) -> (run: AttributedString._InternalRun, location: Int) {
        let result = seekToRun(rangeIndex: index)
        return (runs[result.block], result.location)
    }
    
    func run(containing location: Int) -> AttributedString._InternalRun {
        return runs[seekToRun(location: location).block]
    }
    
    func runAndLocation(containing location: Int) -> (run: AttributedString._InternalRun, location: Int) {
        let result = seekToRun(location: location)
        return (runs[result.block], result.location)
    }
    
    func runs(containing range: Range<Int>) -> [AttributedString._InternalRun] {
        var runs = [AttributedString._InternalRun]()
        var location = range.lowerBound
        while location < range.upperBound {
            let run = self.runs[seekToRun(location: location).block]
            let clampedRange = (location..<location + run.length).clamped(to: range)
            runs.append(AttributedString._InternalRun(length: clampedRange.count, attributes: run.attributes))
            location += run.length
        }
        return runs
    }
    
    enum RunEnumerationModification {
        case guaranteedNotModified
        case guaranteedModified
        case notGuaranteed
    }
    
    /// Enumerate each run in the provided range of UTF-8 locations. Mutating of attributes during this enumeration via the passed `inout AttributedString._InternalRun` IS allowed.
    ///
    /// - It is expected that only attributes will be mutated and not the length of the run (any changes to the length of the run will be ignored).
    /// - If a run that spans both the inside and outside of the provided `range` is modified, the run will be broken into pieces and only the piece within the `range` will be modified.
    /// - If a run is modified such that it becomes coalesced with the next run to be enumerated, that next run will not be passed to the `block` and the next call to the `block` will be with the next non-coalesced run.
    ///
    /// - Parameters:
    ///   - range: The range of UTF-8 indices to enumerate between. Runs will be clamped to this range.
    ///   - block: A block to call with each enumerated run. Mutation is ONLY supported by changing attributes on the provided `inout AttributedString._InternalRun` while enumerating.
    ///   - run: The current run provided via enumeration
    ///   - location: The UTF-8 distance from the start of the string to the start of this run (clamped to the provided `range`)
    ///   - stop: Stops further enumeration when set to `true`
    func enumerateRuns(containing range: Range<Int>? = nil, _ block: (_ run: inout AttributedString._InternalRun, _ location: Int, _ stop: inout Bool, _ modificationStatus: inout RunEnumerationModification) throws -> Void) rethrows {
        var location = range?.lowerBound ?? 0
        // When endLocation=-1, the return statement will break the loop
        // We do this to avoid needing to scan the whole runs array to find endLocation when range is nil
        let endLocation = range?.upperBound ?? -1
        while endLocation == -1 || location < endLocation {
            let result = seekToRun(location: location)
            if result.block >= runs.count {
                return
            }
            let run = runs[result.block]
            let runRange = result.location ..< result.location + run.length
            let clampedRange : Range<Int>
            if endLocation == -1 {
                clampedRange = runRange.clamped(to: location ..< runRange.endIndex)
            } else {
                clampedRange = runRange.clamped(to: location ..< endLocation)
            }
            var stop = false
            let clampedRun = AttributedString._InternalRun(length: clampedRange.count, attributes: run.attributes)
            var maybeChangedRun = clampedRun
            var modificationStatus: RunEnumerationModification = .notGuaranteed
            try block(&maybeChangedRun, location, &stop, &modificationStatus)
            maybeChangedRun.length = clampedRun.length // Ignore any changes to length
            if modificationStatus == .guaranteedModified || (modificationStatus == .notGuaranteed && maybeChangedRun.attributes != clampedRun.attributes) {
                if runRange != clampedRange {
                    var replacementRuns = [AttributedString._InternalRun]()
                    if runRange.startIndex != clampedRange.startIndex {
                        let splitOffStartLength = clampedRange.startIndex - runRange.startIndex
                        replacementRuns.append(AttributedString._InternalRun(length: splitOffStartLength, attributes: run.attributes))
                    }
                    replacementRuns.append(maybeChangedRun)
                    if runRange.endIndex != clampedRange.endIndex {
                        let splitOffEndLength = runRange.endIndex - clampedRange.endIndex
                        replacementRuns.append(AttributedString._InternalRun(length: splitOffEndLength, attributes: run.attributes))
                    }
                    replaceRunsSubrange(result.block ..< result.block + 1, with: replacementRuns)
                    let newResult = seekToRun(location: location)
                    location = newResult.location + runs[newResult.block].length
                } else {
                    let newBlock = self.updateAndCoalesce(run: maybeChangedRun, at: result.block)
                    let newResult = seekToRun(rangeIndex: newBlock)
                    location = newResult.location + runs[newResult.block].length
                }
            } else {
                location += maybeChangedRun.length
            }
            if stop {
                return
            }
        }
    }
    
    func indexOfRun(containing location: Int) -> Int {
        return seekToRun(location: location).block
    }
    
    /// Replace the runs for a specified range of UTF-8 locations with the provided collection. This will split runs at the start/end if the bounds of the range fall in the middle of an existing run
    /// Note: the provided `newElements` must already be coalesced together if needed.
    func replaceRunsSubrange<C: Collection>(locations subrange: Range<Int>, with newElements: C) where C.Element == AttributedString._InternalRun {
        let start = seekToRun(location: subrange.startIndex)
        let newStartLength = subrange.startIndex - start.location
        var insertingRuns = [AttributedString._InternalRun](newElements)
        if newStartLength > 0 {
            if insertingRuns.isEmpty || runs[start.block].attributes != insertingRuns[0].attributes {
                insertingRuns.insert(AttributedString._InternalRun(length: newStartLength, attributes: runs[start.block].attributes), at: 0)
            } else {
                insertingRuns[0].length += newStartLength
            }
        }
        
        let end = seekToRun(location: subrange.endIndex)
        if end.block != runs.endIndex {
            let endRun = runs[end.block]
            let newEndLength = end.location + endRun.length - subrange.endIndex
            if newEndLength > 0 {
                if insertingRuns.isEmpty || runs[end.block].attributes != insertingRuns.last!.attributes {
                    insertingRuns.append(AttributedString._InternalRun(length: newEndLength, attributes: runs[end.block].attributes))
                } else {
                    insertingRuns[insertingRuns.endIndex - 1].length += newEndLength
                }
            }
            replaceRunsSubrange(start.block ..< end.block + 1, with: insertingRuns)
        } else {
            replaceRunsSubrange(start.block ..< end.block, with: insertingRuns)
        }
    }
    
    /// Replaces the runs for a specified range of block indices with the given `newElements`
    /// Note: The provided `newElements` must already be coalsced together if needed.
    func replaceRunsSubrange<C: Collection>(_ subrange: Range<Int>, with newElements: C) where C.Element == AttributedString._InternalRun {
        runOffsetCacheLock.lock()
        defer { runOffsetCacheLock.unlock() }
        if runOffsetCache.block > subrange.lowerBound {
            // Move the cached location to a place where it won't be corrupted
            seekToRunAlreadyLocked(rangeIndex: subrange.lowerBound)
        }
        runs.replaceSubrange(subrange, with: newElements)
        let startOfReplacement = subrange.startIndex
        let endOfReplacement = subrange.endIndex + (newElements.count - (subrange.endIndex - subrange.startIndex))
        if endOfReplacement < runs.count && endOfReplacement > 0 && runs[endOfReplacement - 1].attributes == runs[endOfReplacement].attributes {
            runs[endOfReplacement - 1].length += runs[endOfReplacement].length
            runs.remove(at: endOfReplacement)
        }
        if startOfReplacement < runs.count && startOfReplacement > 0 && runs[startOfReplacement - 1].attributes == runs[startOfReplacement].attributes {
            runOffsetCache.block -= 1
            runOffsetCache.location -= runs[startOfReplacement - 1].length
            runs[startOfReplacement - 1].length += runs[startOfReplacement].length
            runs.remove(at: startOfReplacement)
        }
    }
}
