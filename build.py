# This source file is part of the Swift.org open source project
#
# Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
#
# See http://swift.org/LICENSE.txt for license information
# See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
#

script = Script()

foundation = DynamicLibrary("Foundation")

foundation.GCC_PREFIX_HEADER = 'CoreFoundation/Base.subproj/CoreFoundation_Prefix.h'

if Configuration.current.target.sdk == OSType.Linux:
	foundation.CFLAGS = '-DDEPLOYMENT_TARGET_LINUX -D_GNU_SOURCE '
	foundation.LDFLAGS = '-Wl,@./CoreFoundation/linux.ld -Xlinker -T ${SDKROOT}/lib/swift/linux/${ARCH}/swift.ld -lswiftGlibc `icu-config --ldflags` -Wl,-defsym,__CFConstantStringClassReference=_TMC10Foundation19_NSCFConstantString -Wl,-Bsymbolic '

elif Configuration.current.target.sdk == OSType.FreeBSD:
	foundation.CFLAGS = '-DDEPLOYMENT_TARGET_FREEBSD -I/usr/local/include -I/usr/local/include/libxml2 '
	foundation.LDFLAGS = ''
elif Configuration.current.target.sdk == OSType.MacOSX:
	foundation.CFLAGS = '-DDEPLOYMENT_TARGET_MACOSX '
	foundation.LDFLAGS = '-licucore -twolevel_namespace -Wl,-alias_list,CoreFoundation/Base.subproj/DarwinSymbolAliases -sectcreate __UNICODE __csbitmaps CoreFoundation/CharacterSets/CFCharacterSetBitmaps.bitmap -sectcreate __UNICODE __properties CoreFoundation/CharacterSets/CFUniCharPropertyDatabase.data -sectcreate __UNICODE __data CoreFoundation/CharacterSets/CFUnicodeData-L.mapping -segprot __UNICODE r r '

# For now, we do not distinguish between public and private headers (they are all private to Foundation)
# These are really part of CF, which should ultimately be a separate target
foundation.ROOT_HEADERS_FOLDER_PATH = "${PREFIX}/lib/swift"
foundation.PUBLIC_HEADERS_FOLDER_PATH = "${PREFIX}/lib/swift/CoreFoundation"
foundation.PRIVATE_HEADERS_FOLDER_PATH = "${PREFIX}/lib/swift/CoreFoundation"
foundation.PROJECT_HEADERS_FOLDER_PATH = "${PREFIX}/lib/swift/CoreFoundation"

foundation.PUBLIC_MODULE_FOLDER_PATH = "${PREFIX}/lib/swift/CoreFoundation"

foundation.CFLAGS += " ".join([
	'-DU_SHOW_DRAFT_API',
	'-DCF_BUILDING_CF',
	'-DDEPLOYMENT_RUNTIME_SWIFT',
	'-fconstant-cfstrings',
	'-fexceptions',
	'-Wno-shorten-64-to-32',
	'-Wno-deprecated-declarations',
	'-Wno-unreachable-code',
	'-Wno-conditional-uninitialized',
	'-Wno-unused-variable',
	'-Wno-int-conversion',
	'-Wno-unused-function',
	'-I/usr/include/libxml2',
	'-I./',
])

swift_cflags = [
	'-I${BUILD_DIR}/Foundation/usr/lib/swift',
	'-I/usr/include/libxml2'
]

if "XCTEST_BUILD_DIR" in Configuration.current.variables:
	swift_cflags += [
		'-I${XCTEST_BUILD_DIR}',
		'-L${XCTEST_BUILD_DIR}',
		'-I/usr/include/libxml2'
	]
foundation.SWIFTCFLAGS = " ".join(swift_cflags)

foundation.LDFLAGS += '-lpthread -ldl -lm -lswiftCore -lxml2 '

if "XCTEST_BUILD_DIR" in Configuration.current.variables:
	foundation.LDFLAGS += '-L${XCTEST_BUILD_DIR}'

headers = CopyHeaders(
module = 'CoreFoundation/Base.subproj/linux.modulemap',
public = [
	'CoreFoundation/Stream.subproj/CFStream.h',
	'CoreFoundation/String.subproj/CFStringEncodingExt.h',
	'CoreFoundation/Base.subproj/SwiftRuntime/CoreFoundation.h',
	'CoreFoundation/Base.subproj/SwiftRuntime/TargetConditionals.h',
	'CoreFoundation/RunLoop.subproj/CFMessagePort.h',
	'CoreFoundation/Collections.subproj/CFBinaryHeap.h',
	'CoreFoundation/PlugIn.subproj/CFBundle.h',
	'CoreFoundation/Locale.subproj/CFCalendar.h',
	'CoreFoundation/Collections.subproj/CFBitVector.h',
	'CoreFoundation/Base.subproj/CFAvailability.h',
	'CoreFoundation/Collections.subproj/CFTree.h',
	'CoreFoundation/NumberDate.subproj/CFTimeZone.h',
	'CoreFoundation/Error.subproj/CFError.h',
	'CoreFoundation/Collections.subproj/CFBag.h',
	'CoreFoundation/PlugIn.subproj/CFPlugIn.h',
	'CoreFoundation/Parsing.subproj/CFXMLParser.h',
	'CoreFoundation/String.subproj/CFString.h',
	'CoreFoundation/Collections.subproj/CFSet.h',
	'CoreFoundation/Base.subproj/CFUUID.h',
	'CoreFoundation/NumberDate.subproj/CFDate.h',
	'CoreFoundation/Collections.subproj/CFDictionary.h',
	'CoreFoundation/Base.subproj/CFByteOrder.h',
	'CoreFoundation/AppServices.subproj/CFUserNotification.h',
	'CoreFoundation/Base.subproj/CFBase.h',
	'CoreFoundation/Preferences.subproj/CFPreferences.h',
	'CoreFoundation/Locale.subproj/CFLocale.h',
	'CoreFoundation/RunLoop.subproj/CFSocket.h',
	'CoreFoundation/Parsing.subproj/CFPropertyList.h',
	'CoreFoundation/Collections.subproj/CFArray.h',
	'CoreFoundation/RunLoop.subproj/CFRunLoop.h',
	'CoreFoundation/URL.subproj/CFURLAccess.h',
	'CoreFoundation/Locale.subproj/CFDateFormatter.h',
	'CoreFoundation/RunLoop.subproj/CFMachPort.h',
	'CoreFoundation/PlugIn.subproj/CFPlugInCOM.h',
	'CoreFoundation/Base.subproj/CFUtilities.h',
	'CoreFoundation/Parsing.subproj/CFXMLNode.h',
	'CoreFoundation/URL.subproj/CFURLComponents.h',
	'CoreFoundation/URL.subproj/CFURL.h',
	'CoreFoundation/Locale.subproj/CFNumberFormatter.h',
	'CoreFoundation/String.subproj/CFCharacterSet.h',
	'CoreFoundation/NumberDate.subproj/CFNumber.h',
	'CoreFoundation/Collections.subproj/CFData.h',
],
private = [
	'CoreFoundation/Base.subproj/ForSwiftFoundationOnly.h',
	'CoreFoundation/Base.subproj/ForFoundationOnly.h',
	'CoreFoundation/String.subproj/CFBurstTrie.h',
	'CoreFoundation/Error.subproj/CFError_Private.h',
	'CoreFoundation/URL.subproj/CFURLPriv.h',
	'CoreFoundation/Base.subproj/CFLogUtilities.h',
	'CoreFoundation/PlugIn.subproj/CFBundlePriv.h',
	'CoreFoundation/StringEncodings.subproj/CFStringEncodingConverter.h',
	'CoreFoundation/Stream.subproj/CFStreamAbstract.h',
	'CoreFoundation/Base.subproj/CFInternal.h',
	'CoreFoundation/Parsing.subproj/CFXMLInputStream.h',
	'CoreFoundation/Parsing.subproj/CFXMLInterface.h',
	'CoreFoundation/PlugIn.subproj/CFPlugIn_Factory.h',
	'CoreFoundation/String.subproj/CFStringLocalizedFormattingInternal.h',
	'CoreFoundation/PlugIn.subproj/CFBundle_Internal.h',
	'CoreFoundation/StringEncodings.subproj/CFStringEncodingConverterPriv.h',
	'CoreFoundation/Collections.subproj/CFBasicHash.h',
	'CoreFoundation/StringEncodings.subproj/CFStringEncodingDatabase.h',
	'CoreFoundation/StringEncodings.subproj/CFUnicodeDecomposition.h',
	'CoreFoundation/Stream.subproj/CFStreamInternal.h',
	'CoreFoundation/PlugIn.subproj/CFBundle_BinaryTypes.h',
	'CoreFoundation/Locale.subproj/CFICULogging.h',
	'CoreFoundation/Locale.subproj/CFLocaleInternal.h',
	'CoreFoundation/StringEncodings.subproj/CFUnicodePrecomposition.h',
	'CoreFoundation/Base.subproj/CFPriv.h',
	'CoreFoundation/StringEncodings.subproj/CFUniCharPriv.h',
	'CoreFoundation/URL.subproj/CFURL.inc.h',
	'CoreFoundation/NumberDate.subproj/CFBigNumber.h',
	'CoreFoundation/StringEncodings.subproj/CFUniChar.h',
	'CoreFoundation/StringEncodings.subproj/CFStringEncodingConverterExt.h',
	'CoreFoundation/Collections.subproj/CFStorage.h',
	'CoreFoundation/Base.subproj/CFRuntime.h',
	'CoreFoundation/String.subproj/CFStringDefaultEncoding.h',
	'CoreFoundation/String.subproj/CFCharacterSetPriv.h',
	'CoreFoundation/Stream.subproj/CFStreamPriv.h',
	'CoreFoundation/StringEncodings.subproj/CFICUConverters.h',
	'CoreFoundation/String.subproj/CFRegularExpression.h',
],
project = [
])

foundation.add_phase(headers)

sources = CompileSources([
    'closure/data.c',
    'closure/runtime.c',
    'uuid/uuid.c',
	# 'CoreFoundation/AppServices.subproj/CFUserNotification.c',
	'CoreFoundation/Base.subproj/CFBase.c',
	'CoreFoundation/Base.subproj/CFFileUtilities.c',
	'CoreFoundation/Base.subproj/CFPlatform.c',
	'CoreFoundation/Base.subproj/CFRuntime.c',
	'CoreFoundation/Base.subproj/CFSortFunctions.c',
	'CoreFoundation/Base.subproj/CFSystemDirectories.c',
	'CoreFoundation/Base.subproj/CFUtilities.c',
	'CoreFoundation/Base.subproj/CFUUID.c',
	'CoreFoundation/Collections.subproj/CFArray.c',
	'CoreFoundation/Collections.subproj/CFBag.c',
	'CoreFoundation/Collections.subproj/CFBasicHash.c',
	'CoreFoundation/Collections.subproj/CFBinaryHeap.c',
	'CoreFoundation/Collections.subproj/CFBitVector.c',
	'CoreFoundation/Collections.subproj/CFData.c',
	'CoreFoundation/Collections.subproj/CFDictionary.c',
	'CoreFoundation/Collections.subproj/CFSet.c',
	'CoreFoundation/Collections.subproj/CFStorage.c',
	'CoreFoundation/Collections.subproj/CFTree.c',
	'CoreFoundation/Error.subproj/CFError.c',
	'CoreFoundation/Locale.subproj/CFCalendar.c',
	'CoreFoundation/Locale.subproj/CFDateFormatter.c',
	'CoreFoundation/Locale.subproj/CFLocale.c',
	'CoreFoundation/Locale.subproj/CFLocaleIdentifier.c',
	'CoreFoundation/Locale.subproj/CFLocaleKeys.c',
	'CoreFoundation/Locale.subproj/CFNumberFormatter.c',
	'CoreFoundation/NumberDate.subproj/CFBigNumber.c',
	'CoreFoundation/NumberDate.subproj/CFDate.c',
	'CoreFoundation/NumberDate.subproj/CFNumber.c',
	'CoreFoundation/NumberDate.subproj/CFTimeZone.c',
	'CoreFoundation/Parsing.subproj/CFBinaryPList.c',
	'CoreFoundation/Parsing.subproj/CFOldStylePList.c',
	'CoreFoundation/Parsing.subproj/CFPropertyList.c',
	'CoreFoundation/Parsing.subproj/CFXMLInputStream.c',
	'CoreFoundation/Parsing.subproj/CFXMLNode.c',
	'CoreFoundation/Parsing.subproj/CFXMLParser.c',
	'CoreFoundation/Parsing.subproj/CFXMLTree.c',
	'CoreFoundation/Parsing.subproj/CFXMLInterface.c',
	'CoreFoundation/PlugIn.subproj/CFBundle.c',
	'CoreFoundation/PlugIn.subproj/CFBundle_Binary.c',
	'CoreFoundation/PlugIn.subproj/CFBundle_Grok.c',
	'CoreFoundation/PlugIn.subproj/CFBundle_InfoPlist.c',
	'CoreFoundation/PlugIn.subproj/CFBundle_Locale.c',
	'CoreFoundation/PlugIn.subproj/CFBundle_Resources.c',
	'CoreFoundation/PlugIn.subproj/CFBundle_Strings.c',
	'CoreFoundation/PlugIn.subproj/CFPlugIn.c',
	'CoreFoundation/PlugIn.subproj/CFPlugIn_Factory.c',
	'CoreFoundation/PlugIn.subproj/CFPlugIn_Instance.c',
	'CoreFoundation/PlugIn.subproj/CFPlugIn_PlugIn.c',
	'CoreFoundation/Preferences.subproj/CFApplicationPreferences.c',
	'CoreFoundation/Preferences.subproj/CFPreferences.c',
	# 'CoreFoundation/RunLoop.subproj/CFMachPort.c',
	# 'CoreFoundation/RunLoop.subproj/CFMessagePort.c',
	'CoreFoundation/RunLoop.subproj/CFRunLoop.c',
	'CoreFoundation/RunLoop.subproj/CFSocket.c',
	'CoreFoundation/Stream.subproj/CFConcreteStreams.c',
	'CoreFoundation/Stream.subproj/CFSocketStream.c',
	'CoreFoundation/Stream.subproj/CFStream.c',
	'CoreFoundation/String.subproj/CFBurstTrie.c',
	'CoreFoundation/String.subproj/CFCharacterSet.c',
	'CoreFoundation/String.subproj/CFString.c',
	'CoreFoundation/String.subproj/CFStringEncodings.c',
	'CoreFoundation/String.subproj/CFStringScanner.c',
	'CoreFoundation/String.subproj/CFStringUtilities.c',
	'CoreFoundation/String.subproj/CFStringTransform.c',
	'CoreFoundation/StringEncodings.subproj/CFBuiltinConverters.c',
	'CoreFoundation/StringEncodings.subproj/CFICUConverters.c',
	'CoreFoundation/StringEncodings.subproj/CFPlatformConverters.c',
	'CoreFoundation/StringEncodings.subproj/CFStringEncodingConverter.c',
	'CoreFoundation/StringEncodings.subproj/CFStringEncodingDatabase.c',
	'CoreFoundation/StringEncodings.subproj/CFUniChar.c',
	'CoreFoundation/StringEncodings.subproj/CFUnicodeDecomposition.c',
	'CoreFoundation/StringEncodings.subproj/CFUnicodePrecomposition.c',
	'CoreFoundation/URL.subproj/CFURL.c',
	'CoreFoundation/URL.subproj/CFURLAccess.c',
	'CoreFoundation/URL.subproj/CFURLComponents.c',
	'CoreFoundation/URL.subproj/CFURLComponents_URIParser.c',
	'CoreFoundation/String.subproj/CFCharacterSetData.S',
	'CoreFoundation/String.subproj/CFUnicodeDataL.S',
	'CoreFoundation/String.subproj/CFUniCharPropertyDatabase.S',
	'CoreFoundation/String.subproj/CFRegularExpression.c',
])

sources.add_dependency(headers)
foundation.add_phase(sources)

swift_sources = CompileSwiftSources([
	'Foundation/NSObject.swift',
	'Foundation/NSAffineTransform.swift',
	'Foundation/NSArray.swift',
	'Foundation/NSAttributedString.swift',
	'Foundation/NSBundle.swift',
	'Foundation/NSByteCountFormatter.swift',
	'Foundation/NSCache.swift',
	'Foundation/NSCalendar.swift',
	'Foundation/NSCFArray.swift',
	'Foundation/NSCFDictionary.swift',
	'Foundation/NSCFSet.swift',
	'Foundation/NSCFString.swift',
	'Foundation/NSCharacterSet.swift',
	'Foundation/NSCoder.swift',
	'Foundation/NSComparisonPredicate.swift',
	'Foundation/NSCompoundPredicate.swift',
	'Foundation/NSConcreteValue.swift',
	'Foundation/NSData.swift',
	'Foundation/NSDate.swift',
	'Foundation/NSDateComponentsFormatter.swift',
	'Foundation/NSDateFormatter.swift',
	'Foundation/NSDateIntervalFormatter.swift',
	'Foundation/NSDecimal.swift',
	'Foundation/NSDecimalNumber.swift',
	'Foundation/NSDictionary.swift',
	'Foundation/NSEnergyFormatter.swift',
	'Foundation/NSEnumerator.swift',
	'Foundation/NSError.swift',
	'Foundation/NSExpression.swift',
	'Foundation/NSFileHandle.swift',
	'Foundation/NSFileManager.swift',
	'Foundation/NSFormatter.swift',
	'Foundation/NSGeometry.swift',
	'Foundation/NSHost.swift',
	'Foundation/NSHTTPCookie.swift',
	'Foundation/NSHTTPCookieStorage.swift',
	'Foundation/NSIndexPath.swift',
	'Foundation/NSIndexSet.swift',
	'Foundation/NSJSONSerialization.swift',
	'Foundation/NSKeyedCoderOldStyleArray.swift',
	'Foundation/NSKeyedArchiver.swift',
	'Foundation/NSKeyedUnarchiver.swift',
	'Foundation/NSLengthFormatter.swift',
	'Foundation/NSLocale.swift',
	'Foundation/NSLock.swift',
	'Foundation/NSLog.swift',
	'Foundation/NSMassFormatter.swift',
	'Foundation/NSNotification.swift',
	'Foundation/NSNotificationQueue.swift',
	'Foundation/NSNull.swift',
	'Foundation/NSNumber.swift',
	'Foundation/NSNumberFormatter.swift',
	'Foundation/NSObjCRuntime.swift',
	'Foundation/NSOperation.swift',
	'Foundation/NSOrderedSet.swift',
	'Foundation/NSPathUtilities.swift',
	'Foundation/NSPersonNameComponents.swift',
	'Foundation/NSPersonNameComponentsFormatter.swift',
	'Foundation/NSPort.swift',
	'Foundation/NSPortMessage.swift',
	'Foundation/NSPredicate.swift',
	'Foundation/NSProcessInfo.swift',
	'Foundation/NSProgress.swift',
	'Foundation/NSPropertyList.swift',
	'Foundation/NSRange.swift',
	'Foundation/NSRegularExpression.swift',
	'Foundation/NSRunLoop.swift',
	'Foundation/NSScanner.swift',
	'Foundation/NSSet.swift',
	'Foundation/NSSortDescriptor.swift',
	'Foundation/NSSpecialValue.swift',
	'Foundation/NSStream.swift',
	'Foundation/NSString.swift',
	'Foundation/String.swift',
	'Foundation/NSSwiftRuntime.swift',
	'Foundation/NSTask.swift',
	'Foundation/NSTextCheckingResult.swift',
	'Foundation/NSThread.swift',
	'Foundation/NSTimer.swift',
	'Foundation/NSTimeZone.swift',
	'Foundation/NSURL.swift',
	'Foundation/NSURLAuthenticationChallenge.swift',
	'Foundation/NSURLCache.swift',
	'Foundation/NSURLCredential.swift',
	'Foundation/NSURLCredentialStorage.swift',
	'Foundation/NSURLError.swift',
	'Foundation/NSURLProtectionSpace.swift',
	'Foundation/NSURLProtocol.swift',
	'Foundation/NSURLRequest.swift',
	'Foundation/NSURLResponse.swift',
	'Foundation/NSURLSession.swift',
	'Foundation/NSUserDefaults.swift',
	'Foundation/NSUUID.swift',
	'Foundation/NSValue.swift',
	'Foundation/NSXMLDocument.swift',
	'Foundation/NSXMLDTD.swift',
	'Foundation/NSXMLDTDNode.swift',
	'Foundation/NSXMLElement.swift',
	'Foundation/NSXMLNode.swift',
	'Foundation/NSXMLNodeOptions.swift',
	'Foundation/NSXMLParser.swift',
	'Foundation/FoundationErrors.swift',
])

swift_sources.add_dependency(headers)
foundation.add_phase(swift_sources)

foundation_tests_resources = CopyResources('TestFoundation', [
    'TestFoundation/Resources/Info.plist',
    'TestFoundation/Resources/NSURLTestData.plist',
    'TestFoundation/Resources/Test.plist',
    'TestFoundation/Resources/NSStringTestData.txt',
    'TestFoundation/Resources/NSXMLDocumentTestData.xml',
    'TestFoundation/Resources/PropertyList-1.0.dtd',
    'TestFoundation/Resources/NSXMLDTDTestData.xml',
    'TestFoundation/Resources/NSKeyedUnarchiver-ArrayTest.plist',
    'TestFoundation/Resources/NSKeyedUnarchiver-ComplexTest.plist',
    'TestFoundation/Resources/NSKeyedUnarchiver-ConcreteValueTest.plist',
    'TestFoundation/Resources/NSKeyedUnarchiver-EdgeInsetsTest.plist',
    'TestFoundation/Resources/NSKeyedUnarchiver-NotificationTest.plist',
    'TestFoundation/Resources/NSKeyedUnarchiver-RangeTest.plist',
    'TestFoundation/Resources/NSKeyedUnarchiver-RectTest.plist',
    'TestFoundation/Resources/NSKeyedUnarchiver-URLTest.plist',
    'TestFoundation/Resources/NSKeyedUnarchiver-UUIDTest.plist',
    'TestFoundation/Resources/NSKeyedUnarchiver-OrderedSetTest.plist',
])

# TODO: Probably this should be another 'product', but for now it's simply a phase
foundation_tests = SwiftExecutable('TestFoundation', [
	'TestFoundation/main.swift',
] + glob.glob('./TestFoundation/Test*.swift')) # all TestSomething.swift are considered sources to the test project in the TestFoundation directory

foundation_tests.add_dependency(foundation_tests_resources)
foundation.add_phase(foundation_tests_resources)
foundation.add_phase(foundation_tests)

plutil = SwiftExecutable('plutil', ['Tools/plutil/main.swift'])
foundation.add_phase(plutil)

script.add_product(foundation)

extra_script = """
rule InstallFoundation
    command = mkdir -p "${DSTROOT}/${PREFIX}/lib/swift/${OS}"; $
    cp "${BUILD_DIR}/Foundation/${DYLIB_PREFIX}Foundation${DYLIB_SUFFIX}" "${DSTROOT}/${PREFIX}/lib/swift/${OS}"; $
    mkdir -p "${DSTROOT}/${PREFIX}/lib/swift/${OS}/${ARCH}"; $
    cp "${BUILD_DIR}/Foundation/Foundation.swiftmodule" "${DSTROOT}/${PREFIX}/lib/swift/${OS}/${ARCH}/"; $
    cp "${BUILD_DIR}/Foundation/Foundation.swiftdoc" "${DSTROOT}/${PREFIX}/lib/swift/${OS}/${ARCH}/"; $
    mkdir -p "${DSTROOT}/${PREFIX}/local/include"; $
    rsync -r "${BUILD_DIR}/Foundation/${PREFIX}/lib/swift/CoreFoundation" "${DSTROOT}/${PREFIX}/lib/swift/"

build ${BUILD_DIR}/.install: InstallFoundation ${BUILD_DIR}/Foundation/${DYLIB_PREFIX}Foundation${DYLIB_SUFFIX}

build install: phony | ${BUILD_DIR}/.install

"""
if "XCTEST_BUILD_DIR" in Configuration.current.variables:
	extra_script += """
rule RunTestFoundation
    command = echo "**** RUNNING TESTS ****\\nexecute:\\nLD_LIBRARY_PATH=${BUILD_DIR}/Foundation/:${XCTEST_BUILD_DIR} ${BUILD_DIR}/TestFoundation/TestFoundation\\n**** DEBUGGING TESTS ****\\nexecute:\\nLD_LIBRARY_PATH=${BUILD_DIR}/Foundation/:${XCTEST_BUILD_DIR} lldb ${BUILD_DIR}/TestFoundation/TestFoundation\\n"
    description = Building Tests

build ${BUILD_DIR}/.test: RunTestFoundation | TestFoundation

build test: phony | ${BUILD_DIR}/.test

"""
else:
	extra_script += """
rule RunTestFoundation
    command = echo "**** RUNNING TESTS ****\\nexecute:\\nLD_LIBRARY_PATH=${BUILD_DIR}/Foundation/ ${BUILD_DIR}/TestFoundation/TestFoundation\\n**** DEBUGGING TESTS ****\\nexecute:\\nLD_LIBRARY_PATH=${BUILD_DIR}/Foundation/ lldb ${BUILD_DIR}/TestFoundation/TestFoundation\\n"
    description = Building Tests

build ${BUILD_DIR}/.test: RunTestFoundation | TestFoundation

build test: phony | ${BUILD_DIR}/.test

"""

script.add_text(extra_script)

script.generate()
