// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
import Foundation
import XCTest
#else
import SwiftFoundation
import SwiftXCTest
#endif

#if os(OSX) || os(iOS)
    import Darwin
#elseif os(Linux)
    import Glibc
#endif


let kURLTestParsingTestsKey = "ParsingTests"

let kURLTestTitleKey = "In-Title"
let kURLTestUrlKey = "In-Url"
let kURLTestBaseKey = "In-Base"
let kURLTestURLCreatorKey = "In-URLCreator"
let kURLTestPathComponentKey = "In-PathComponent"
let kURLTestPathExtensionKey = "In-PathExtension"

let kURLTestCFResultsKey = "Out-CFResults"
let kURLTestNSResultsKey = "Out-NSResults"

let kNSURLWithStringCreator = "NSURLWithString"
let kCFURLCreateWithStringCreator = "CFURLCreateWithString"
let kCFURLCreateWithBytesCreator = "CFURLCreateWithBytes"
let kCFURLCreateAbsoluteURLWithBytesCreator = "CFURLCreateAbsoluteURLWithBytes"

let kNullURLString = "<null url>"
let kNullString = "<null>"

/// Reads the test data plist file and returns the list of objects
private func getTestData() -> [Any]? {
    let testFilePath = testBundle().pathForResource("NSURLTestData", ofType: "plist")
    let data = NSData(contentsOfFile: testFilePath!)
    guard let testRoot = try? NSPropertyListSerialization.propertyListWithData(data!, options: [], format: nil) as? [String : Any] else {
        XCTFail("Unable to deserialize property list data")
        return nil
    }
    guard let parsingTests = testRoot![kURLTestParsingTestsKey] as? [Any] else {
        XCTFail("Unable to create the parsingTests dictionary")
        return nil
    }
    return parsingTests
}

class TestNSURL : XCTestCase {
    var allTests : [(String, () -> Void)] {
        return [
            ("test_URLStrings", test_URLStrings),
            ("test_fileURLWithPath_relativeToURL", test_fileURLWithPath_relativeToURL ),
            // TODO: these tests fail on linux, more investigation is needed
            // ("test_fileURLWithPath", test_fileURLWithPath),
            // ("test_fileURLWithPath_isDirectory", test_fileURLWithPath_isDirectory),
        ]
    }
    
    func test_fileURLWithPath_relativeToURL() {
        let homeDirectory = "/" // NSHomeDirectory()
//        XCTAssertNotNil(homeDirectory, "Failed to find home directory");
        let baseURL = NSURL(fileURLWithPath: homeDirectory, isDirectory: true)
        XCTAssertNotNil(baseURL, "fileURLWithPath:isDirectory: failed")
        XCTAssertEqual("/", baseURL.path)
/* Can't create NSURLs with relative path values until we have NSString.stringByStandardizingPath
        // we're telling fileURLWithPath:isDirectory:relativeToURL: Library is a directory
        let url1 = NSURL(fileURLWithPath: "Library", isDirectory: true, relativeToURL: baseURL)
        XCTAssertNotNil(url1, "fileURLWithPath:isDirectory:relativeToURL: failed")
        // we're letting fileURLWithPath:relativeToURL: determine Library is a directory with I/O
        let url2 = NSURL(fileURLWithPath: "Library", relativeToURL: baseURL)
        XCTAssertNotNil(url2, "fileURLWithPath:relativeToURL: failed")
        XCTAssertEqual(url1, url2, "\(url1) was not equal to \(url2)")
        // we're telling fileURLWithPath:relativeToURL: Library is a directory with a trailing slash
        let url3 = NSURL(fileURLWithPath: "Library/", relativeToURL: baseURL)
        XCTAssertNotNil(url3, "fileURLWithPath:relativeToURL: failed")
        XCTAssertEqual(url1, url3, "\(url1) was not equal to \(url3)");
*/
    }
    
    /// Returns a URL from the given url string and base
    private func URLWithString(urlString : String, baseString : String?) -> NSURL? {
        if let baseString = baseString {
            let baseURL = NSURL(string: baseString)
            return NSURL(string: urlString, relativeToURL: baseURL)
        } else {
            return NSURL(string: urlString)
        }
    }
    
    internal func generateResults(url: NSURL, pathComponent: String?, pathExtension : String?) -> [String : String] {
        var result = [String : String]()
        if let pathComponent = pathComponent {
            if let newURL = url.URLByAppendingPathComponent(pathComponent, isDirectory: false) {
                result["appendingPathComponent-File"] = newURL.relativeString
                result["appendingPathComponent-File-BaseURL"] = newURL.baseURL?.relativeString ?? kNullString
            } else {
                result["appendingPathComponent-File"] = kNullString
                result["appendingPathComponent-File-BaseURL"] = kNullString
            }

            if let newURL = url.URLByAppendingPathComponent(pathComponent, isDirectory: true) {
                result["appendingPathComponent-Directory"] = newURL.relativeString
                result["appendingPathComponent-Directory-BaseURL"] = newURL.baseURL?.relativeString ?? kNullString
            } else {
                result["appendingPathComponent-Directory"] = kNullString
                result["appendingPathComponent-Directory-BaseURL"] = kNullString
            }
        } else if let pathExtension = pathExtension {
            if let newURL = url.URLByAppendingPathExtension(pathExtension) {
                result["appendingPathExtension"] = newURL.relativeString
                result["appendingPathExtension-BaseURL"] = newURL.baseURL?.relativeString ?? kNullString
            } else {
                result["appendingPathExtension"] = kNullString
                result["appendingPathExtension-BaseURL"] = kNullString
            }
        } else {
            result["relativeString"] = url.relativeString
            result["baseURLString"] = url.baseURL?.relativeString ?? kNullString
            result["absoluteString"] = url.absoluteString
            result["absoluteURLString"] = url.absoluteURL?.relativeString ?? kNullString
            result["scheme"] = url.scheme ?? kNullString
            result["resourceSpecifier"] = url.resourceSpecifier ?? kNullString
            result["host"] = url.host ?? kNullString
            // Temporarily disabled because we're only checking string results
            // result["port"] = url.port ?? kNullString
            result["user"] = url.user ?? kNullString
            result["password"] = url.password ?? kNullString
            result["path"] = url.path ?? kNullString
            result["query"] = url.query ?? kNullString
            result["fragment"] = url.fragment ?? kNullString
            result["parameterString"] = url.parameterString ?? kNullString
            result["relativePath"] = url.relativePath ?? kNullString
            result["isFileURL"] = url.fileURL ? "YES" : "NO"
            // Not yet implemented
            // result["standardizedURL"] = url.standardizedURL?.relativeString ?? kNullString
            
            // Temporarily disabled because we're only checking string results
            // result["pathComponents"] = url.pathComponents ?? kNullString
            result["lastPathComponent"] = url.lastPathComponent ?? kNullString
            result["pathExtension"] = url.pathExtension ?? kNullString
            result["deletingLastPathComponent"] = url.URLByDeletingLastPathComponent?.relativeString ?? kNullString
            result["deletingLastPathExtension"] = url.URLByDeletingPathExtension?.relativeString ?? kNullString
        }
        return result
    }

    internal func compareResults(url : NSURL, expected : [String : Any], got : [String : String]) -> (Bool, [String]) {
        var differences = [String]()
        for (key, obj) in expected {
            // Skip non-string expected results
            if ["port", "standardizedURL", "pathComponents"].contains(key) {
                continue
            }
            if let stringObj = obj as? String {
                if stringObj != got[key] {
                    differences.append(" \(key)  Expected = '\(stringObj)',  Got = '\(got[key])'")
                }
            }
        }
        for (key, obj) in got {
            if expected[key] == nil {
                differences.append(" \(key)  Expected = 'nil',  Got = '\(obj)'")
            }
        }
        if differences.count > 0 {
            differences.sortInPlace()
            differences.insert(" url:  '\(url)' ", atIndex: 0)
            return (false, differences)
        } else {
            return (true, [])
        }
    }

    func test_URLStrings() {
        for obj in getTestData()! {
            let testDict = obj as! [String: Any]
            let title = testDict[kURLTestTitleKey] as! String
            let inURL = testDict[kURLTestUrlKey]! as! String
            let inBase = testDict[kURLTestBaseKey] as! String?
            let inPathComponent = testDict[kURLTestPathComponentKey] as! String?
            let inPathExtension = testDict[kURLTestPathExtensionKey] as! String?
            let expectedCFResults = testDict[kURLTestCFResultsKey]!
            let expectedNSResult = testDict[kURLTestNSResultsKey]!
            var url : NSURL? = nil
            switch (testDict[kURLTestURLCreatorKey]! as! String) {
            case kNSURLWithStringCreator:
                url = URLWithString(inURL, baseString: inBase)
            case kCFURLCreateWithStringCreator, kCFURLCreateWithBytesCreator, kCFURLCreateAbsoluteURLWithBytesCreator:
                // TODO: Not supported right now
                continue
            default:
                XCTFail()
            }
            if let url = url {

                // TODO: NSURL.standardizedURL isn't implemented yet.
                var modifiedExpectedNSResult = expectedNSResult as! [String: Any]
                modifiedExpectedNSResult["standardizedURL"] = nil
                
                let results = generateResults(url, pathComponent: inPathComponent, pathExtension: inPathExtension)
                let (isEqual, differences) = compareResults(url, expected: modifiedExpectedNSResult, got: results)
                XCTAssertTrue(isEqual, "\(title): \(differences)")
            } else {
                XCTAssertEqual(expectedCFResults as? String, kNullURLString)
                XCTAssertEqual(expectedNSResult as? String, kNullURLString)
            }
        }
        
    }
    
    static let gBaseTemporaryDirectoryPath = "/tmp/" // TODO: NSTemporaryDirectory()
    static var gBaseCurrentWorkingDirectoryPath : String {
        get {
            let count = Int(1024) // MAXPATHLEN is platform specific; this is the lowest common denominator for darwin and most linuxes
            var buf : [Int8] = Array(count: count, repeatedValue: 0)
            getcwd(&buf, count)
            return String.fromCString(buf)!
        }
    }
//    size_t      gRelativeOffsetFromBaseCurrentWorkingDirectory = 0;
    static let gFileExistsName = "TestCFURL_file_exists"
    static let gFileDoesNotExistName = "TestCFURL_file_does_not_exist"
    static let gDirectoryExistsName = "TestCFURL_directory_exists"
    static let gDirectoryDoesNotExistName = "TestCFURL_directory_does_not_exist"
    static let gFileExistsPath = gBaseTemporaryDirectoryPath + gFileExistsName
    static let gFileDoesNotExistPath = gBaseTemporaryDirectoryPath + gFileDoesNotExistName
    static let gDirectoryExistsPath = gBaseTemporaryDirectoryPath + gDirectoryExistsName
    static let gDirectoryDoesNotExistPath = gBaseTemporaryDirectoryPath + gDirectoryDoesNotExistName

    static func setup_test_paths() -> Bool {
        if creat(gFileExistsPath, S_IRWXU) < 0 && errno != EEXIST {
            return false
        }
        if unlink(gFileDoesNotExistPath) != 0 && errno != ENOENT {
            return false
        }
        if mkdir(gDirectoryExistsPath, S_IRWXU) != 0 && errno != EEXIST {
            return false
        }
        if rmdir(gDirectoryDoesNotExistPath) != 0 && errno != ENOENT {
            return false
        }
        return true
    }
        
    func test_fileURLWithPath() {
                
        XCTAssertTrue(TestNSURL.setup_test_paths(), "Failed to set up test paths")
        
        // test with file that exists
        var path = TestNSURL.gFileExistsPath
        var url = NSURL(fileURLWithPath: path)
        XCTAssertFalse(url.hasDirectoryPath, "did not expect URL with directory path: \(url)")
        XCTAssertEqual(path, url.path, "path from file path URL is wrong")
        
        // test with file that doesn't exist
        path = TestNSURL.gFileDoesNotExistPath
        url = NSURL(fileURLWithPath: path)
        XCTAssertFalse(url.hasDirectoryPath, "did not expect URL with directory path: \(url)")
        XCTAssertEqual(path, url.path, "path from file path URL is wrong")
            
        // test with directory that exists
        path = TestNSURL.gDirectoryExistsPath
        url = NSURL(fileURLWithPath: path)
        XCTAssertTrue(url.hasDirectoryPath, "expected URL with directory path: \(url)")
        XCTAssertEqual(path, url.path, "path from file path URL is wrong")

        // test with directory that doesn't exist
        path = TestNSURL.gDirectoryDoesNotExistPath
        url = NSURL(fileURLWithPath: path)
        XCTAssertFalse(url.hasDirectoryPath, "did not expect URL with directory path: \(url)")
        XCTAssertEqual(path, url.path, "path from file path URL is wrong")

        /*
        TODO: Relative URLs not yet working
        // test with name relative to current working directory
        path = [NSString stringWithUTF8String:gFileDoesNotExistName];
        url = [NSURL fileURLWithPath:path];
        XCTAssertTrue(!CFURLHasDirectoryPath((CFURLRef)url), @"did not expect URL with directory path: %@", url);
        fileSystemRep = [url fileSystemRepresentation];
        XCTAssertTrue(strlen(fileSystemRep) == (strlen(gFileDoesNotExistName) + gRelativeOffsetFromBaseCurrentWorkingDirectory), @"fileSystemRepresentation was too short");
        XCTAssertTrue(strncmp(gBaseCurrentWorkingDirectoryPath, fileSystemRep, strlen(gBaseCurrentWorkingDirectoryPath)) == 0, @"fileSystemRepresentation of base path is wrong");
        XCTAssertTrue(strncmp(gFileDoesNotExistName, &fileSystemRep[gRelativeOffsetFromBaseCurrentWorkingDirectory], strlen(gFileDoesNotExistName)) == 0, @"fileSystemRepresentation of file path is wrong");
        */
    }
        
    func test_fileURLWithPath_isDirectory() {
        XCTAssertTrue(TestNSURL.setup_test_paths(), "Failed to set up test paths")
            
        // test with file that exists
        var path = TestNSURL.gFileExistsPath
        var url = NSURL(fileURLWithPath: path, isDirectory: true)
        XCTAssertTrue(url.hasDirectoryPath, "expected URL with directory path: \(url)")
        url = NSURL(fileURLWithPath: path, isDirectory: false)
        XCTAssertFalse(url.hasDirectoryPath, "did not expect URL with directory path: \(url)")
        XCTAssertEqual(path, url.path, "path from file path URL is wrong")
        
        // test with file that doesn't exist
        path = TestNSURL.gFileDoesNotExistPath
        url = NSURL(fileURLWithPath: path, isDirectory: true)
        XCTAssertTrue(url.hasDirectoryPath, "expected URL with directory path: \(url)")
        url = NSURL(fileURLWithPath: path, isDirectory: false)
        XCTAssertFalse(url.hasDirectoryPath, "did not expect URL with directory path: \(url)")
        XCTAssertEqual(path, url.path, "path from file path URL is wrong")
        
        // test with directory that exists
        path = TestNSURL.gDirectoryExistsPath
        url = NSURL(fileURLWithPath: path, isDirectory: false)
        XCTAssertFalse(url.hasDirectoryPath, "did not expect URL with directory path: \(url)")
        url = NSURL(fileURLWithPath: path, isDirectory: true)
        XCTAssertTrue(url.hasDirectoryPath, "expected URL with directory path: \(url)")
        XCTAssertEqual(path, url.path, "path from file path URL is wrong")
        
        // test with directory that doesn't exist
        path = TestNSURL.gDirectoryDoesNotExistPath
        url = NSURL(fileURLWithPath: path, isDirectory: false)
        XCTAssertFalse(url.hasDirectoryPath, "did not expect URL with directory path: \(url)")
        url = NSURL(fileURLWithPath: path, isDirectory: true)
        XCTAssertTrue(url.hasDirectoryPath, "expected URL with directory path: \(url)")
        XCTAssertEqual(path, url.path, "path from file path URL is wrong")
        
        /*
        TODO: Relative URLs not yet working
        // test with name relative to current working directory
        path = [NSString stringWithUTF8String:gFileDoesNotExistName];
        url = [NSURL fileURLWithPath:path isDirectory:NO];
        XCTAssertTrue(!CFURLHasDirectoryPath((CFURLRef)url), @"did not expect URL with directory path: %@", url);
        url = [NSURL fileURLWithPath:path isDirectory:YES];
        XCTAssertTrue(CFURLHasDirectoryPath((CFURLRef)url), @"expected URL with directory path: %@", url);
        fileSystemRep = [url fileSystemRepresentation];
        XCTAssertTrue(strlen(fileSystemRep) == (strlen(gFileDoesNotExistName) + gRelativeOffsetFromBaseCurrentWorkingDirectory), @"fileSystemRepresentation was too short");
        XCTAssertTrue(strncmp(gBaseCurrentWorkingDirectoryPath, fileSystemRep, strlen(gBaseCurrentWorkingDirectoryPath)) == 0, @"fileSystemRepresentation of base path is wrong");
        XCTAssertTrue(strncmp(gFileDoesNotExistName, &fileSystemRep[gRelativeOffsetFromBaseCurrentWorkingDirectory], strlen(gFileDoesNotExistName)) == 0, @"fileSystemRepresentation of file path is wrong");
        */
    }
}
    
class TestNSURLComponents : XCTestCase {
    var allTests : [(String, () -> Void)] {
        return [
            ("test_string", test_string),
        ]
    }
    
    func test_string() {
        for obj in getTestData()! {
            let testDict = obj as! [String: Any]
            let unencodedString = testDict[kURLTestUrlKey] as! String
            let expectedString = NSString(string: unencodedString).stringByAddingPercentEncodingWithAllowedCharacters(.URLPathAllowedCharacterSet())!
            guard let components = NSURLComponents(string: expectedString) else { continue }
            XCTAssertEqual(components.string!, expectedString, "should be the expected string (\(components.string!) != \(expectedString))")
        }
    }

}
