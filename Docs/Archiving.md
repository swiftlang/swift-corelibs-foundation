# Archiving Notes

There is a preliminary implementation of NSKeyedArchiver and NSKeyedUnarchiver which should be compatible with the OS X version.

* NSKeyedArchiver is not yet working archiving to files, there seems to be an issue where the URL is not passed correctly to CFWriteStreamCreateWithFile()

* The implementation of NSStringFromClass() and NSClassFromString() currently uses private Swift API and does not support encoding classes that are not exported (i.e. cannot be looked up with dlsym()

* NSKeyedUnarchiver reads the entire plist into memory before constructing the object graph, it should construct it incrementally as does Foundation on OS X

* Paths that raise errors vs. calling _fatalError() need to be reviewed carefully

* Encoding/decoding of objects using the encodeValueOfObjCType() methods is not yet supported

* The signature of the decoding APIs that take a class whitelist has changed from NSSet to [AnyClass] as AnyClass does not support Hashable

* classForKeyed[Un]Archiver has moved into NSObject so it can be overridden, move this back into an extension eventually


