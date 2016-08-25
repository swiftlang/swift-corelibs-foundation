# Implementation Status

This document lays out the structure of the Foundation project, and provides the current implementation status of each major feature.

Foundation is divided into groups of related functionality. These groups are currently laid out in the Xcode project, even though they are in a flat structure on disk.

As Foundation is a work in progress, not all methods and functionality are present. When implementations are completed, this list should be updated to reflect the current state of the library.

* **Runtime**: The basis for interoperability.
    The classes and methods in this group provide an interface for interoperability between C code and Swift. They also provide common layers used throughout the framework such as the root class `NSObject`.

    | Entity Name             | Status          | Test Coverage | Notes                                                                       |
    |-------------------------|-----------------|---------------|-----------------------------------------------------------------------------|
    | `NSEnumerator`          | Complete        | ?             |                                                                             |
    | `NSGetSizeAndAlignment` | Complete        | ?             |                                                                             |
    | `NSStringFromClass`     | Mostly Complete | ?             | Only top-level Swift classes are supported                                  |
    | `NSClassFromString`     | Mostly Complete | ?             | Only top-level Swift classes are supported; mangled names are not supported |
    | `NSObject`              | Complete        | ?             |                                                                             |
    | `NSSwiftRuntime`        | N/A             | N/A           | For internal use only                                                       |
    | `Boxing`                | N/A             | N/A           | For internal use only                                                       |


* **URL**: Networking primitives

    The classes in this group provide functionality for manipulating URLs and paths via a common model object. The group also has classes for creating and receiving network connections.

    | Entity Name                  | Status          | Test Coverage | Notes                                                                                                              |
    |------------------------------|-----------------|---------------|--------------------------------------------------------------------------------------------------------------------|
    | `URLAuthenticationChallenge` | Unimplemented   | ?             |                                                                                                                    |
    | `URLCache`                   | Unimplemented   | ?             |                                                                                                                    |
    | `URLCredential`              | Mostly Complete | ?             | `NSCoding` and `NSCopying` remain unimplemented                                                                    |
    | `URLCredentialStorage`       | Unimplemented   | ?             |                                                                                                                    |
    | `NSURLError*`                | Complete        | N/A           |                                                                                                                    |
    | `URLProtectionSpace`         | Unimplemented   | ?             |                                                                                                                    |
    | `URLProtocol`                | Unimplemented   | ?             |                                                                                                                    |
    | `URLProtocolClient`          | Unimplemented   | ?             |                                                                                                                    |
    | `NSURLRequest`               | Mostly Complete | ?             | `NSCoding` remains unimplemented                                                                                   |
    | `NSMutableURLRequest`        | Mostly Complete | ?             | `NSCoding` remains unimplemented                                                                                   |
    | `URLResponse`                | Mostly Complete | ?             | `NSCoding` remains unimplemented                                                                                   |
    | `NSHTTPURLResponse`          | Mostly Complete | ?             | `NSCoding` remains unimplemented                                                                                   |
    | `NSURL`                      | Mostly Complete | ?             | `NSCoding` with non-keyed-coding archivers, `checkResourceIsReachable()`, and resource values remain unimplemented |
    | `NSURLQueryItem`             | Mostly Complete | ?             | `NSCoding` remains unimplemented                                                                                   |
    | `URLResourceKey`             | Complete        | N/A           |                                                                                                                    |
    | `URLFileResourceType`        | Complete        | N/A           |                                                                                                                    |
    | `URL`                        | Complete        | ?             |                                                                                                                    |
    | `URLResourceValues`          | Complete        | N/A           |                                                                                                                    |
    | `URLComponents`              | Complete        | ?             |                                                                                                                    |
    | `URLRequest`                 | Complete        | ?             |                                                                                                                    |
    | `HTTPCookie`                 | Complete        | ?             |                                                                                                                    |
    | `HTTPCookiePropertyKey`      | Complete        | ?             |                                                                                                                    |
    | `HTTPCookieStorage`          | Unimplemented   | ?             |                                                                                                                    |
    | `Host`                       | Complete        | ?             |                                                                                                                    |
    | `Configuration`              | N/A             | ?             | For internal use only                                                                                              |
    | `EasyHandle`                 | N/A             | ?             | For internal use only                                                                                              |
    | `HTTPBodySource`             | N/A             | ?             | For internal use only                                                                                              |
    | `HTTPMessage`                | N/A             | ?             | For internal use only                                                                                              |
    | `libcurlHelpers`             | N/A             | ?             | For internal use only                                                                                              |
    | `MultiHandle`                | N/A             | ?             | For internal use only                                                                                              |
    | `URLSession`                 | Mostly Complete | ?             | `shared`, invalidation, resetting, flushing, getting tasks, and others remain unimplemented                        |
    | `URLSessionConfiguration`    | Mostly Complete | ?             | `ephemeral` and `background(withIdentifier:)` remain unimplemented                                                 |
    | `URLSessionDelegate`         | Complete        | N/A           |                                                                                                                    |
    | `URLSessionTask`             | Mostly Complete | ?             | `NSCopying`, `cancel()`, `error`, `createTransferState(url:)` with streams, and others remain unimplemented        |
    | `URLSessionDataTask`         | Complete        | ?             |                                                                                                                    |
    | `URLSessionUploadTask`       | Complete        | ?             |                                                                                                                    |
    | `URLSessionDownloadTask`     | Unimplemented   | ?             |                                                                                                                    |
    | `URLSessionStreamTask`       | Unimplemented   | ?             |                                                                                                                    |
    | `TaskRegistry`               | N/A             | ?             | For internal use only                                                                                              |
    | `TransferState`              | N/A             | ?             | For internal use only                                                                                              |


* **Formatters**: Locale and language-correct formatted values.

    This group contains the is the base `NSFormatter` class and its subclasses. These formatters can be used for dates, numbers, sizes, energy, and many other types.

    | Entity Name                     | Status          | Test Coverage | Notes                                                                                     |
    |---------------------------------|-----------------|---------------|-------------------------------------------------------------------------------------------|
    | `DateComponentFormatter`        | Unimplemented   | ?             |                                                                                           |
    | `DateIntervalFormatter`         | Unimplemented   | ?             |                                                                                           |
    | `EnergyFormatter`               | Unimplemented   | ?             |                                                                                           |
    | `LengthFormatter`               | Unimplemented   | ?             |                                                                                           |
    | `MassFormatter`                 | Unimplemented   | ?             |                                                                                           |
    | `NumberFormatter`               | Mostly Complete | ?             | `objectValue(_:range:)` remains unimplemented                                             |
    | `PersonNameComponentsFormatter` | Unimplemented   | ?             |                                                                                           |
    | `ByteCountFormatter`            | Unimplemented   | ?             |                                                                                           |
    | `DateFormatter`                 | Mostly Complete | ?             | `objectValue(_:range:)` and `setLocalizedDateFormatFromTemplate(_:)` remain unimplemented |
    | `Formatter`                     | Complete        | ?             |                                                                                           |
    | `MeasurementFormatter`          | Unimplemented   | ?             |                                                                                           |

* **Predicates**: Base functionality for building queries.

    This is the base class and subclasses for `NSPredicate` and `NSExpression`.

    | Entity Name             | Status        | Test Coverage | Notes                                                                              |
    |-------------------------|---------------|---------------|------------------------------------------------------------------------------------|
    | `NSExpression`          | Unimplemented | N/A           |                                                                                    |
    | `NSComparisonPredicate` | Unimplemented | N/A           |                                                                                    |
    | `NSCompoundPredicate`   | Complete      | N/A           |                                                                                    |
    | `NSPredicate`           | Incomplete    | Incomplete    | Only boolean and block evaluations are implemented; all else remains unimplemented |

* **Serialization**: Serialization and deserialization functionality.

    The classes in this group perform tasks like parsing and writing JSON, property lists and binary archives.

    | Entity Name                 | Status          | Test Coverage | Notes                                                                         |
    |-----------------------------|-----------------|---------------|-------------------------------------------------------------------------------|
    | `NSJSONSerialization`       | Mostly Complete | Substantial   | `jsonObject(with:options:)` remains unimplemented                             |
    | `NSKeyedArchiver`           | Mostly Complete | Substantial   | `init()` and `encodedData` remain unimplemented                               |
    | `NSKeyedCoderOldStyleArray` | N/A             | N/A           | For internal use only                                                         |
    | `NSKeyedUnarchiver`         | Mostly Complete | Substantial   | `decodingFailurePolicy.set` remains unimplemented                             |
    | `NSKeyedArchiverHelpers`    | N/A             | N/A           | For internal use only                                                         |
    | `NSCoder`                   | Incomplete      | N/A           | Decoding methods which require a concrete implementation remain unimplemented |
    | `PropertyListSerialization` | Mostly Complete | Incomplete    | `propertyList(with:options:format:)` remains unimplemented                    |

* **XML**: A group of classes for parsing and representing XML documents and elements.

    The classes provided in this group are responsible for parsing and validating XML. They should be an interface for representing libxml2 in a more object-oriented manner.

    | Entity Name   | Status          | Test Coverage | Notes                                                                                                                                 |
    |---------------|-----------------|---------------|---------------------------------------------------------------------------------------------------------------------------------------|
    | `XMLDocument` | Mostly Complete | Substantial   | `init()`, `replacementClass(for:)`, and `object(byApplyingXSLT...)` remain unimplemented                                              |
    | `XMLDTD`      | Mostly Complete | Substantial   | `init()` remains unimplemented                                                                                                        |
    | `XMLDTDNode`  | Complete        | Incomplete    |                                                                                                                                       |
    | `XMLElement`  | Incomplete      | Incomplete    | `init(xmlString:)`, `elements(forLocalName:uri:)`, `attribute(forLocalName:uri:)`, namespace support, and others remain unimplemented |
    | `XMLNode`     | Incomplete      | Incomplete    | `localName(forName:)`, `prefix(forName:)`, `predefinedNamespace(forPrefix:)`, and others remain unimplemented                         |
    | `XMLParser`   | Complete        | Incomplete    |                                                                                                                                       |

* **Collections**: A group of classes to contain objects.

    The classes provided in this group provide basic collections. The primary role for these classes is to provide an interface layer between the CoreFoundation implementations and the standard library implementations. Additionally, they have useful extras like serialization support. There are also additional collection types that the standard library does not support.

     > _Note_: See [Known Issues](Issues.md) for more information about bridging between Foundation collection types and Swift standard library collection types.

    | Entity Name           | Status          | Test Coverage | Notes                                                                                                                                                               |
    |-----------------------|-----------------|---------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------|
    | `NSOrderedSet`        | Mostly Complete | ?             | `NSCoding` with non-keyed-coding archivers, `NS[Mutable]Copying`, and `array` & `set` (and associated indexing methods) remain unimplemented                        |
    | `NSMutableOrderedSet` | Mostly Complete | ?             | `NSCoding` and `sortRange(_:options:, usingComparator:)` with non-empty options remain unimplemented                                                                |
    | `NSCFArray`           | N/A             | ?             | For internal use only                                                                                                                                               |
    | `NSIndexSet`          | Mostly Complete | ?             | `NSCoding`, `NSCopying`, and concurrent `enumerateWithOptions(_:range:paramType:returnType:block:)` remain unimplemented                                            |
    | `NSMutableIndexSet`   | Mostly Complete | ?             | `shiftIndexesStarting(at:by:)` remains unimplemented                                                                                                                |
    | `IndexSet`            | Complete        | ?             |                                                                                                                                                                     |
    | `NSIndexPath`         | Mostly Complete | ?             | `NSCoding`, `NSCopying`, `getIndexes(_:)` remain unimplemented                                                                                                      |
    | `IndexPath`           | Complete        | ?             |                                                                                                                                                                     |
    | `NSArray`             | Mostly Complete | ?             | Reading/writing to files/URLs, concurrent `enumerateObjects(at:options:using:)`, and `sortedArray(from:options:usingComparator:)` with options remain unimplemented |
    | `NSMutableArray`      | Mostly Complete | ?             | `exchangeObject(at:withObjectAt:)` and `replaceObjects(in:withObjectsFromArray:)` remain unimplemented for types other than `NSMutableArray`                        |
    | `NSDictionary`        | Mostly Complete | ?             | `NSCoding` with non-keyed-coding archivers, `descriptionInStringsFileFormat`, `sharedKeySet(forKeys:)`, and reading/writing to files/URLs remain unimplemented      |
    | `NSMutableDictionary` | Mostly Complete | ?             | `descriptionInStringsFileFormat`, `sharedKeySet(forKeys:)`, and reading/writing to files/URLs remain unimplemented                                                  |
    | `NSCFDictionary`      | N/A             | ?             | For internal use only                                                                                                                                               |
    | `NSSet`               | Mostly Complete | ?             | `description(withLocale:)` and `customMirror` remain unimplemented                                                                                                  |
    | `NSMutableSet`        | Mostly Complete | ?             | `init?(coder:)` remains unimplemented                                                                                                                               |
    | `NSCountedSet`        | Mostly Complete | ?             | `init?(coder:)` remains unimplemented                                                                                                                               |
    | `NSCFSet`             | N/A             | ?             | For internal use only                                                                                                                                               |
    | `NSCache`             | Complete        | ?             |                                                                                                                                                                     |
    | `NSSortDescriptor`    | Unimplemented   | ?             |                                                                                                                                                                     |

* **RunLoop**: Timers, streams and run loops.

    The classes in this group provide support for scheduling work and acting upon input from external sources.

    | Entity Name      | Status          | Test Coverage | Notes                                                                         |
    |------------------|-----------------|---------------|-------------------------------------------------------------------------------|
    | `Port`           | Unimplemented   | None          |                                                                               |
    | `MessagePort`    | Unimplemented   | None          |                                                                               |
    | `SocketPort`     | Unimplemented   | None          |                                                                               |
    | `PortMessage`    | Unimplemented   | None          |                                                                               |
    | `RunLoop`        | Mostly Complete | Incomplete    | `add(_: Port, forMode:)` and `remove(_: Port, forMode:)` remain unimplemented |
    | `NSStream`       | Mostly Complete | Substantial   |                                                                               |
    | `Stream`         | Unimplemented   | Substantial   | Methods which require a concrete implementation remain unimplemented          |
    | `InputStream`    | Mostly Complete | Substantial   | `getBuffer(_:length:)` remains unimplemented                                  |
    | `NSOutputStream` | Complete        | Substantial   |                                                                               |
    | `Timer`          | Complete        | Substantial   |                                                                               |

* **String**: A set of classes for scanning, manipulating and storing string values.

    The NSString implementation is present to provide an interface layer between CoreFoundation and Swift, but it also adds additional functionality on top of the Swift standard library String type. Other classes in this group provide mechanisms to scan, match regular expressions, store attributes in run arrays attached to strings, and represent sets of characters.

    > _Note_: See [Known Issues](Issues.md) for more information about bridging between the Foundation NSString types and Swift standard library String type.

    | Entity Name                 | Status          | Test Coverage | Notes                                                                                                                                                            |
    |-----------------------------|-----------------|---------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------|
    | `RegularExpression`         | Mostly Complete | ?             | `NSCoding` remains unimplemented                                                                                                                                 |
    | `Scanner`                   | Mostly Complete | ?             | `scanHex<T: _FloatLike>(_:locale:locationToScanFrom:to:)` and `localizedScannerWithString(_:)` remain unimplemented                                              |
    | `TextCheckingResult`        | Mostly Complete | ?             | `NSCoding`, `NSCopying`, `resultType`, and `range(at:)` remain unimplemented                                                                                     |
    | `NSAttributedString`        | Incomplete      | ?             | `NSCoding`, `NS[Mutable]Copying`, `attributedSubstring(from:)`, `isEqual(to:)`, `init(NSAttributedString:)`, and `enumerateAttributes(...)` remain unimplemented |
    | `NSMutableAttributedString` | Unimplemented   | ?             | Only `addAttribute(_:value:range:)` is implemented                                                                                                               |
    | `NSCharacterSet`            | Mostly Complete | ?             | `NSCoding` remains unimplemented                                                                                                                                 |
    | `NSMutableCharacterSet`     | Mostly Complete | ?             | Decoding remains unimplemented                                                                                                                                   |
    | `NSCFCharacterSet`          | N/A             | ?             | For internal use only                                                                                                                                            |
    | `CharacterSet`              | Complete        | ?             |                                                                                                                                                                  |
    | `NSString`                  | Mostly Complete | ?             | `init(contentsOf:usedEncoding:)`, `init(contentsOfFile:usedEncoding:)`, `enumerateSubstrings(in:options:using:)` remain unimplemented                            |
    | `NSStringEncodings`         | Complete        | N/A           | Contains definitions of string encodings                                                                                                                         |
    | `NSCFString`                | N/A             | N/A           | For internal use only                                                                                                                                            |
    | `NSStringAPI`               | N/A             | N/A           | Exposes `NSString` APIs on `String`                                                                                                                              |
    | `ExtraStringAPIs`           | Complete        | ?             | Random access for `String.UTF16View`, only when Foundation is imported; decouples the Swift core from a UTF16 representation.                                    |

* **Number**: A set of classes and methods for representing numeric values and structures.

    | Entity Name                       | Status          | Test Coverage | Notes                                                                         |
    |-----------------------------------|-----------------|---------------|-------------------------------------------------------------------------------|
    | `NSRange`                         | Mostly Complete | ?             | `NSCoding` from non-keyed-coding archivers remains unimplemented              |
    | `Decimal`                         | Unimplemented   | ?             |                                                                               |
    | `NSDecimalNumber`                 | Unimplemented   | ?             |                                                                               |
    | `NSDecimalNumberHandler`          | Unimplemented   | ?             |                                                                               |
    | `CGPoint`                         | Complete        | ?             |                                                                               |
    | `CGSize`                          | Complete        | ?             |                                                                               |
    | `CGRect`                          | Complete        | ?             |                                                                               |
    | `NSEdgeInsets`                    | Mostly Complete | ?             | `NSCoding` from non-keyed-coding archivers remains unimplemented              |
    | `NSGeometry`                      | Mostly Complete | ?             | `NSIntegralRectWithOptions` `.AlignRectFlipped` support remains unimplemented |
    | `CGFloat`                         | Complete        | ?             |                                                                               |
    | `AffineTransform`                 | Complete        | ?             |                                                                               |
    | `NSAffineTransform`               | Mostly Complete | ?             | `NSCoding` remains unimplemented                                              |
    | `NSNumber`                        | Complete        | ?             |                                                                               |
    | `NSConcreteValue`                 | N/A             | N/A           | For internal use only                                                         |
    | `NSSpecialValue`                  | N/A             | N/A           | For internal use only                                                         |
    | `NSValue`                         | Complete        | ?             |                                                                               |
    | `NSMeasurement`                   | Unimplemented   | ?             |                                                                               |
    | `Measurement`                     | Complete        | ?             |                                                                               |
    | `UnitConverter`                   | Complete        | ?             |                                                                               |
    | `UnitConverterLinear`             | Complete        | ?             |                                                                               |
    | `Unit`                            | Complete        | ?             |                                                                               |
    | `Dimension`                       | Complete        | ?             |                                                                               |
    | `UnitAcceleration`                | Complete        | ?             |                                                                               |
    | `UnitAngle`                       | Complete        | ?             |                                                                               |
    | `UnitArea`                        | Complete        | ?             |                                                                               |
    | `UnitConcentrationMass`           | Complete        | ?             |                                                                               |
    | `UnitDispersion`                  | Complete        | ?             |                                                                               |
    | `UnitDuration`                    | Complete        | ?             |                                                                               |
    | `UnitElectricCharge`              | Complete        | ?             |                                                                               |
    | `UnitElectricCurrent`             | Complete        | ?             |                                                                               |
    | `UnitElectricPotentialDifference` | Complete        | ?             |                                                                               |
    | `UnitElectricResistance`          | Complete        | ?             |                                                                               |
    | `UnitEnergy`                      | Complete        | ?             |                                                                               |
    | `UnitFrequency`                   | Complete        | ?             |                                                                               |
    | `UnitFuelEfficiency`              | Complete        | ?             |                                                                               |
    | `UnitLength`                      | Complete        | ?             |                                                                               |
    | `UnitIlluminance`                 | Complete        | ?             |                                                                               |
    | `UnitMass`                        | Complete        | ?             |                                                                               |
    | `UnitPower`                       | Complete        | ?             |                                                                               |
    | `UnitPressure`                    | Complete        | ?             |                                                                               |
    | `UnitSpeed`                       | Complete        | ?             |                                                                               |
    | `UnitTemperature`                 | Complete        | ?             |                                                                               |
    | `UnitVolume`                      | Complete        | ?             |                                                                               |

* **UserDefaults**: A mechanism for storing values to persist as user settings and local.

    | Entity Name    | Statues         | Test Coverage | Notes                                                                                                                         |
    |----------------|-----------------|---------------|-------------------------------------------------------------------------------------------------------------------------------|
    | `UserDefaults` | Incomplete      | None          | `dictionaryRepresentation()`, domain support, and forced objects remain unimplemented. Unit tests are currently commented out |
    | `NSLocale`     | Mostly Complete | Incomplete    | `NSCoding` from non-keyed-coding archivers remains unimplemented. Only unit test asserts locale key constant names            |
    | `Locale`       | Complete        | Incomplete    | Only unit test asserts value copying                                                                                          |

* **OS**: Mechanisms for interacting with the operating system on a file system level as well as process and thread level

    | Entity Name       | Status          | Test Coverage | Notes                                                                                                                     |
    |-------------------|-----------------|---------------|---------------------------------------------------------------------------------------------------------------------------|
    | `FileHandle`      | Mostly Complete | ?             | `NSCoding`, `nullDevice`, and background operations remain unimplemented                                                  |
    | `Pipe`            | Complete        | ?             |                                                                                                                           |
    | `FileManager`     | Incomplete      | ?             | URL searches, relationship lookups, item copying, cross-device moving, recursive linking, and others remain unimplemented |
    | `Task`            | Mostly Complete | ?             | `interrupt()`, `terminate()`, `suspend()`, `resume()`, and `terminationReason` remain unimplemented                       |
    | `Bundle`          | Mostly Complete | ?             | `allBundles`, `init(for:)`, `unload()`, `classNamed()`, and `principalClass` remain unimplemented                         |
    | `ProcessInfo`     | Complete        | ?             |                                                                                                                           |
    | `NSThread`        | Incomplete      | ?             | `isMainThread`, `mainThread`, `name`, `callStackReturnAddresses`, and `callStackSymbols` remain unimplemented             |
    | `Operation`       | Complete        | ?             |                                                                                                                           |
    | `BlockOperation`  | Complete        | ?             |                                                                                                                           |
    | `OperationQueue`  | Complete        | ?             |                                                                                                                           |
    | `NSLock`          | Mostly Complete | ?             | `lock(before:)` remains unimplemented                                                                                     |
    | `NSConditionLock` | Complete        | ?             |                                                                                                                           |
    | `NSRecursiveLock` | Mostly Complete | ?             | `lock(before:)` remains unimplemented                                                                                     |
    | `NSCondition`     | Complete        | ?             |                                                                                                                           |

* **DateTime**: Classes for representing dates, timezones, and calendars.

    | Entity Name        | Status          | Test Coverage | Notes                                                                                                                           |
    |--------------------|-----------------|---------------|---------------------------------------------------------------------------------------------------------------------------------|
    | `NSCalendar`       | Mostly Complete | ?             | `NSCoding` from non-keyed-coding archivers, `autoupdatingCurrent`, and `enumerateDates` remain unimplemented                    |
    | `NSDateComponents` | Mostly Complete | ?             | `NSCoding` from non-keyed-coding archivers remains unimplemented                                                                |
    | `Calendar`         | Complete        | ?             |                                                                                                                                 |
    | `DateComponents`   | Complete        | ?             |                                                                                                                                 |
    | `NSDate`           | Mostly Complete | ?             | Encoding to non-keyed-coding archivers and `timeIntervalSinceReferenceDate` remain unimplemented                                |
    | `NSDateInterval`   | Complete        | ?             |                                                                                                                                 |
    | `DateInterval`     | Complete        | ?             |                                                                                                                                 |
    | `Date`             | Complete        | ?             |                                                                                                                                 |
    | `NSTimeZone`       | Incomplete      | ?             | `init(forSecondsFromGMT:)`, `localTimeZones()`, `knownTimeZoneNames`, `abbreviationDictionary`, and others remain unimplemented |
    | `TimeZone`         | Complete        | ?             |                                                                                                                                 |

* **Notifications**: Classes for loosely coupling events from a set of many observers.

    | Entity Name          | Status          | Test Coverage | Notes                                                      |
    |----------------------|-----------------|---------------|------------------------------------------------------------|
    | `NSNotification`     | Complete        | ?             |                                                            |
    | `NotificationCenter` | Mostly Complete | ?             | Adding observers to non-`nil` queues remains unimplemented |
    | `Notification`       | Complete        | ?             |                                                            |
    | `NotificationQueue`  | Complete        | ?             |                                                            |

* **Model**: Representations for abstract model elements like null, data, and errors.

    | Entity Name              | Status          | Test Coverage | Notes                             |
    |--------------------------|-----------------|---------------|-----------------------------------|
    | `NSNull`                 | Complete        | ?             |                                   |
    | `NSData`                 | Complete        | ?             |                                   |
    | `NSMutableData`          | Complete        | ?             |                                   |
    | `Data`                   | Complete        | ?             |                                   |
    | `NSProgress`             | Unimplemented   | ?             |                                   |
    | `NSError`                | Complete        | ?             |                                   |
    | `NSUUID`                 | Complete        | ?             |                                   |
    | `UUID`                   | Complete        | ?             |                                   |
    | `NSPersonNameComponents` | Mostly Complete | ?             | `NSCopying` remains unimplemented |
    | `PersonNameComponents`   | Complete        | ?             |                                   |
