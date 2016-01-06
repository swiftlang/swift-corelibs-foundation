# Implementation Status

This document lays out the structure of the Foundation project, and provides the current implementation status of each major feature.

Foundation is divided into groups of related functionality. These groups are currently laid out in the Xcode project, even though they are in a flat structure on disk.

As Foundation is a work in progress, not all methods and functionality are present. When implementations are completed, this list should be updated to reflect the current state of the library.

* **Runtime**: The basis for interoperability.

    The classes and methods in this group provide an interface for interoperability between C code and Swift. They also provide common layers used throughout the framework such as the root class `NSObject`.

    * `NSObject` is mostly implemented.
    * `NSEnumerator` is fully implemented.
    * `NSSwiftRuntime` _(internal use only)_ contains Swift runtime-specific functionality.
    * `NSObjCRuntime` is missing some key parts such as NSClassFromString. Much of the functionality here is specific to the Objective-C runtime and is not relevant when building for Swift.


* **URL**: Networking primitives.

    The classes in this group provide functionality for manipulating URLs and paths via a common model object. The group also has classes for creating and receiving network connections.

    * `NSURL` is mostly implemented.
    * `NSURLSession` and related classes are not yet implemented.
        * _Note_: `NSURLConnection` is deprecated API and not present in this version of Foundation.


* **Formatters**: Locale and language-correct formatted values.

    This group contains the is the base `NSFormatter` class and its subclasses. These formatters can be used for dates, numbers, sizes, energy, and many other types.

    * `NSFormatter` is fully implemented.
    * `NSDateFormatter` is mostly implemented.
    * `NSNumberFormatter` is mostly implemented.
    * The remaining formatters are not yet implemented.


* **Predicates**: Base functionality for building queries.

    This is the base class and subclasses for `NSPredicate` and `NSExpression`.

    * These classes are not yet implemented.


* **Serialization**: Serialization and deserialization functionality.

    The classes in this group perform tasks like parsing and writing JSON, property lists and binary archives.

    * `NSPropertyList` is mostly implemented.
    * `NSCoder` and `NSKeyedArchiver` are mostly not yet implemented (a few funnel methods are implemented).
    * `NSJSONSerialization` is partly implemented (serialization is not yet implemented)


* **XML**: A group of classes for parsing and representing XML documents and elements.

    The classes provided in this group are responsible for parsing and validating XML. They should be an interface for representing libxml2 in a more object-oriented manner.

    * These classes are not yet implemented.


* **Collections**: A group of classes to contain objects.

    The classes provided in this group provide basic collections. The primary role for these classes is to provide an interface layer between the CoreFoundation implementations and the standard library implementations. Additionally, they have useful extras like serialization support. There are also additional collection types that the standard library does not support.

     > _Note_: See [Known Issues](Issues.md) for more information about bridging between Foundation collection types and Swift standard library collection types.

    * `NSOrderedSet` is not yet implemented.
    * `NSCFArray` _(internal use only)_ implements toll-free bridging between Swift and CoreFoundation array types.
    * `NSIndexSet` is fully implemented.
    * `NSIndexPath` is fully implemented.
    * `NSArray` is partially implemented.
    * `NSDictionary` is partially implemented.
    * `NSCFDictionary` _(internal use only)_ implements toll-free bridging between Swift and CoreFoundation dictionary types.
    * `NSSet` is partially implemented.
    * `NSCFSet` _(internal use only)_ implements toll-free bridging between Swift and CoreFoundation set types.
    * `NSCache` is fully implemented.
    * `NSSortDescriptor` is not yet implemented.


* **RunLoop**: Timers, streams and run loops.

    The classes in this group provide support for scheduling work and acting upon input from external sources.

    * `NSPort` is not yet implemented.
    * `NSPortMessage` is not yet implemented.
    * `NSRunLoop` is not yet implemented. Its CoreFoundation equivalent `CFRunLoop` is available, but needs some work to remove a dependency on libdispatch.
    * `NSStream` is not yet implemented.
    * `NSTimer` is not yet implemented.


* **String**: A set of classes for scanning, manipulating and storing string values.

    The NSString implementation is present to provide an interface layer between CoreFoundation and Swift, but it also adds additional functionality on top of the Swift standard library String type. Other classes in this group provide mechanisms to scan, match regular expressions, store attributes in run arrays attached to strings, and represent sets of characters.

    > _Note_: See [Known Issues](Issues.md) for more information about bridging between the Foundation NSString types and Swift standard library String type.

    * `NSRegularExpression` is not yet implemented.
    * `NSScanner` is fully implemented. _Note_: This class contains some experimental API. See the source for more details.
    * `NSTextCheckingResult` is not yet implemented.
    * `NSAttributedString` is not yet implemented.
    * `NSCharacterSet` is fully implemented.
    * `NSString` is partially implemented.
    * `NSCFString` _(internal use only)_ implements toll-free bridging between Swift and CoreFoundation String types.


* **Number**: A set of classes and methods for representing numeric values and structures.

    * `NSRange` is fully implemented.
    * `NSDecimal` is not yet implemented.
    * `NSDecimalNumber` is not yet implemented.
    * `NSGeometry` is fully implemented.
    * `NSAffineTransform` is fully implemented.
    * `NSNumber` is fully implemented.
    * `NSValue` is not yet implemented.


* **UserDefaults**: A mechanism for storing values to persist as user settings and local.

    * `NSUserDefaults` is not yet implemented.
    * `NSLocale` is fully implemented.


* **OS**: Mechanisms for interacting with the operating system on a file system level as well as process and thread level

    * `NSFileHandle` is mostly not yet implemented, excluding a few methods used for plutil.
    * `NSFileManager` is partially implemented.
    * `NSTask` is not yet implemented.
    * `NSBundle` is mostly not yet implemented. The CoreFoundation implementation of `CFBundle` is available to use.
    * `NSProcessInfo` is mostly implemented.
    * `NSThread` is fully implemented.
    * `NSOperation` is not yet implemented.
    * `NSLock` is fully implemented.
    * `NSPathUtilities` is mostly implemented.


* **DateTime**: Classes for representing dates, timezones, and calendars.

    * `NSCalendar` is fully implemented. _Note_: This class contains some experimental API. See the source for more details.
    * `NSDate` is fully implemented.
    * `NSTimeZone` is partially implemented.


* **Notifications**: Classes for loosely coupling events from a set of many observers.

    * `NSNotification` is not yet implemented.
    * `NSNotificationQueue` is not yet implemented.


* **Model**: Representations for abstract model elements like null, data, and errors.

    * `NSNull` is fully implemented.
    * `NSData` is mostly implemented.
    * `NSProgress` is not yet implemented.
    * `NSError` is fully implemented.
    * `NSUUID` is fully implemented.
    * `NSPersonNameComponents` is not yet implemented.
    * `FoundationErrors` is an interoperability layer between `NSError` and Swift error handling.
