// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
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
    let testFilePath = testBundle().urlForResource("NSURLTestData", withExtension: "plist")
    let data = try! Data(contentsOf: testFilePath!)
    guard let testRoot = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String : Any] else {
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
    static var allTests: [(String, (TestNSURL) -> () throws -> Void)] {
        return [
            ("test_URLStrings", test_URLStrings),
            ("test_fileURLWithPath_relativeToURL", test_fileURLWithPath_relativeToURL ),
            // TODO: these tests fail on linux, more investigation is needed
            ("test_fileURLWithPath", test_fileURLWithPath),
            ("test_fileURLWithPath_isDirectory", test_fileURLWithPath_isDirectory),
            ("test_URLByResolvingSymlinksInPath", test_URLByResolvingSymlinksInPath),
            ("test_copy", test_copy)
        ]
    }
    
    func test_fileURLWithPath_relativeToURL() {
        let homeDirectory = NSHomeDirectory()
        XCTAssertNotNil(homeDirectory, "Failed to find home directory")
        let homeURL = URL(fileURLWithPath: homeDirectory, isDirectory: true)
        XCTAssertNotNil(homeURL, "fileURLWithPath:isDirectory: failed")
        XCTAssertEqual(homeDirectory, homeURL.path)

        #if os(OSX)
        let baseURL = URL(fileURLWithPath: homeDirectory, isDirectory: true)
        let relativePath = "Documents"
        #elseif os(Linux)
        let baseURL = URL(fileURLWithPath: "/usr", isDirectory: true)
        let relativePath = "include"
        #endif
        // we're telling fileURLWithPath:isDirectory:relativeToURL: Documents is a directory
        let url1 = URL(fileURLWithFileSystemRepresentation: relativePath, isDirectory: true, relativeTo: baseURL)
        XCTAssertNotNil(url1, "fileURLWithPath:isDirectory:relativeToURL: failed")
        // we're letting fileURLWithPath:relativeToURL: determine Documents is a directory with I/O
        let url2 = URL(fileURLWithPath: relativePath, relativeTo: baseURL)
        XCTAssertNotNil(url2, "fileURLWithPath:relativeToURL: failed")
        XCTAssertEqual(url1, url2, "\(url1) was not equal to \(url2)")
        // we're telling fileURLWithPath:relativeToURL: Documents is a directory with a trailing slash
        let url3 = URL(fileURLWithPath: relativePath + "/", relativeTo: baseURL)
        XCTAssertNotNil(url3, "fileURLWithPath:relativeToURL: failed")
        XCTAssertEqual(url1, url3, "\(url1) was not equal to \(url3)")
    }
    
    /// Returns a URL from the given url string and base
    private func URLWithString(_ urlString : String, baseString : String?) -> URL? {
        if let baseString = baseString {
            let baseURL = URL(string: baseString)
            return URL(string: urlString, relativeTo: baseURL)
        } else {
            return URL(string: urlString)
        }
    }
    
    internal func generateResults(_ url: URL, pathComponent: String?, pathExtension : String?) -> [String : String] {
        var result = [String : String]()
        if let pathComponent = pathComponent {
            do {
                let newURL = try url.appendingPathComponent(pathComponent, isDirectory: false)
                result["appendingPathComponent-File"] = newURL.relativeString
                result["appendingPathComponent-File-BaseURL"] = newURL.baseURL?.relativeString ?? kNullString
            } catch {
                result["appendingPathComponent-File"] = kNullString
                result["appendingPathComponent-File-BaseURL"] = kNullString
            }

            do {
               let newURL = try url.appendingPathComponent(pathComponent, isDirectory: true)
                result["appendingPathComponent-Directory"] = newURL.relativeString
                result["appendingPathComponent-Directory-BaseURL"] = newURL.baseURL?.relativeString ?? kNullString
            } catch {
                result["appendingPathComponent-Directory"] = kNullString
                result["appendingPathComponent-Directory-BaseURL"] = kNullString
            }
            
        } else if let pathExtension = pathExtension {
            do {
                let newURL = try url.appendingPathExtension(pathExtension)
                result["appendingPathExtension"] = newURL.relativeString
                result["appendingPathExtension-BaseURL"] = newURL.baseURL?.relativeString ?? kNullString
            } catch {
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
            result["isFileURL"] = url.isFileURL ? "YES" : "NO"
            do {
                let url = try url.standardized()
                result["standardizedURL"] = url.relativeString
            } catch {
                result["standardizedURL"] = kNullString
            } 
            // Temporarily disabled because we're only checking string results
            // result["pathComponents"] = url.pathComponents ?? kNullString
            result["lastPathComponent"] = url.lastPathComponent ?? kNullString
            result["pathExtension"] = url.pathExtension ?? kNullString
            do {
                let url = try url.deletingLastPathComponent()
                result["deletingLastPathComponent"] = url.relativeString
            } catch {
                result["deletingLastPathComponent"] = kNullString
            }
            
            do {
                let url = try url.deletingPathExtension()
                result["deletingLastPathExtension"] = url.relativeString
            } catch {
                result["deletingLastPathExtension"] = kNullString
            }
        }
        return result
    }

    internal func compareResults(_ url : URL, expected : [String : Any], got : [String : String]) -> (Bool, [String]) {
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
            differences.sort()
            differences.insert(" url:  '\(url)' ", at: 0)
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
            var url : URL? = nil
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

                if title == "NSURLWithString-parse-ambiguous-url-001" {
                    // TODO: Fix this test
                } else {
                    let results = generateResults(url, pathComponent: inPathComponent, pathExtension: inPathExtension)
                    let (isEqual, differences) = compareResults(url, expected: expectedNSResult as! [String: Any], got: results)
                    XCTAssertTrue(isEqual, "\(title): \(differences)")
                }
            } else {
                XCTAssertEqual(expectedCFResults as? String, kNullURLString)
                XCTAssertEqual(expectedNSResult as? String, kNullURLString)
            }
        }
        
    }
    
    static let gBaseTemporaryDirectoryPath = NSTemporaryDirectory()
    static var gBaseCurrentWorkingDirectoryPath : String {
        let count = Int(1024) // MAXPATHLEN is platform specific; this is the lowest common denominator for darwin and most linuxes
        var buf : [Int8] = Array(repeating: 0, count: count)
        getcwd(&buf, count)
        return String(cString: buf)
    }
    static var gRelativeOffsetFromBaseCurrentWorkingDirectory: UInt = 0
    static let gFileExistsName = "TestCFURL_file_exists\(ProcessInfo.processInfo().globallyUniqueString)"
    static let gFileDoesNotExistName = "TestCFURL_file_does_not_exist"
    static let gDirectoryExistsName = "TestCFURL_directory_exists\(ProcessInfo.processInfo().globallyUniqueString)"
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
        
        let cwd = FileManager.default.currentDirectoryPath
        let cwdURL = URL(fileURLWithPath: cwd, isDirectory: true)
        // 1 for path separator
        cwdURL.withUnsafeFileSystemRepresentation {
            gRelativeOffsetFromBaseCurrentWorkingDirectory = UInt(strlen($0) + 1)
        }
        
        
        return true
    }
        
    func test_fileURLWithPath() {
        if !TestNSURL.setup_test_paths() {
            let error = strerror(errno)!
            XCTFail("Failed to set up test paths: \(NSString(bytes: error, length: Int(strlen(error)), encoding: String.Encoding.ascii.rawValue)!.bridge())")
        }
        
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

        // test with name relative to current working directory
        path = TestNSURL.gFileDoesNotExistName
        url = NSURL(fileURLWithPath: path)
        XCTAssertFalse(url.hasDirectoryPath, "did not expect URL with directory path: \(url)")
        let fileSystemRep = url.fileSystemRepresentation
        let actualLength = strlen(fileSystemRep)
        // 1 for path separator
        let expectedLength = UInt(strlen(TestNSURL.gFileDoesNotExistName)) + TestNSURL.gRelativeOffsetFromBaseCurrentWorkingDirectory
        XCTAssertTrue(UInt(actualLength) == expectedLength, "fileSystemRepresentation was too short")
        XCTAssertTrue(strncmp(TestNSURL.gBaseCurrentWorkingDirectoryPath, fileSystemRep, Int(strlen(TestNSURL.gBaseCurrentWorkingDirectoryPath))) == 0, "fileSystemRepresentation of base path is wrong")
        let lengthOfRelativePath = Int(strlen(TestNSURL.gFileDoesNotExistName))
        let relativePath = fileSystemRep.advanced(by: Int(TestNSURL.gRelativeOffsetFromBaseCurrentWorkingDirectory))
        XCTAssertTrue(strncmp(TestNSURL.gFileDoesNotExistName, relativePath, lengthOfRelativePath) == 0, "fileSystemRepresentation of file path is wrong")
    }
        
    func test_fileURLWithPath_isDirectory() {
        if !TestNSURL.setup_test_paths() {
            let error = strerror(errno)!
            XCTFail("Failed to set up test paths: \(NSString(bytes: error, length: Int(strlen(error)), encoding: String.Encoding.ascii.rawValue)!.bridge())")
        }
            
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
        
        // test with name relative to current working directory
        path = TestNSURL.gFileDoesNotExistName
        url = NSURL(fileURLWithPath: path, isDirectory: false)
        XCTAssertFalse(url.hasDirectoryPath, "did not expect URL with directory path: \(url)")
        url = NSURL(fileURLWithPath: path, isDirectory: true)
        XCTAssertTrue(url.hasDirectoryPath, "expected URL with directory path: \(url)")
        let fileSystemRep = url.fileSystemRepresentation
        let actualLength = UInt(strlen(fileSystemRep))
        // 1 for path separator
        let expectedLength = UInt(strlen(TestNSURL.gFileDoesNotExistName)) + TestNSURL.gRelativeOffsetFromBaseCurrentWorkingDirectory
        XCTAssertTrue(actualLength == expectedLength, "fileSystemRepresentation was too short")
        XCTAssertTrue(strncmp(TestNSURL.gBaseCurrentWorkingDirectoryPath, fileSystemRep, Int(strlen(TestNSURL.gBaseCurrentWorkingDirectoryPath))) == 0, "fileSystemRepresentation of base path is wrong")
        let lengthOfRelativePath = Int(strlen(TestNSURL.gFileDoesNotExistName))
        let relativePath = fileSystemRep.advanced(by: Int(TestNSURL.gRelativeOffsetFromBaseCurrentWorkingDirectory))
        XCTAssertTrue(strncmp(TestNSURL.gFileDoesNotExistName, relativePath, lengthOfRelativePath) == 0, "fileSystemRepresentation of file path is wrong")
    }
    
    func test_URLByResolvingSymlinksInPath() {
        let files = [
            "/tmp/ABC/test_URLByResolvingSymlinksInPath"
        ]
        
        guard ensureFiles(files) else {
            XCTAssert(false, "Could create files for testing.")
            return
        }
        
        // tmp is special because it is symlinked to /private/tmp and this /private prefix should be dropped,
        // so tmp is tmp. On Linux tmp is not symlinked so it would be the same.
        do {
            let url = URL(fileURLWithPath: "/.//tmp/ABC/..")
            let result = try url.resolvingSymlinksInPath().absoluteString
            XCTAssertEqual(result, "file:///tmp/", "URLByResolvingSymlinksInPath removes extraneous path components and resolve symlinks.")
        } catch {
            XCTFail()
        }
            
        do {
            let url = URL(fileURLWithPath: "~")
            let result = try url.resolvingSymlinksInPath().absoluteString
            let expected = "file://" + FileManager.default.currentDirectoryPath + "/~"
            XCTAssertEqual(result, expected, "URLByResolvingSymlinksInPath resolves relative paths using current working directory.")
        } catch {
            XCTFail()
        }

        do {
            let url = URL(fileURLWithPath: "anysite.com/search")
            let result = try url.resolvingSymlinksInPath().absoluteString
            let expected = "file://" + FileManager.default.currentDirectoryPath + "/anysite.com/search"
            XCTAssertEqual(result, expected)
        } catch {
            XCTFail()
        }

        // tmp is symlinked on OS X only
        #if os(OSX)
        do {
            let url = URL(fileURLWithPath: "/tmp/..")
            let result = try url.resolvingSymlinksInPath().absoluteString
            XCTAssertEqual(result, "file:///private/")
        } catch {
            XCTFail()
            }
        #endif
        
        do {
            let url = URL(fileURLWithPath: "/tmp/ABC/test_URLByResolvingSymlinksInPath")
            let result = try url.resolvingSymlinksInPath().absoluteString
            XCTAssertEqual(result, "file:///tmp/ABC/test_URLByResolvingSymlinksInPath", "URLByResolvingSymlinksInPath appends trailing slash for existing directories only")
        } catch {
            XCTFail()
        }
        
        do {
            let url = URL(fileURLWithPath: "/tmp/ABC/..")
            let result = try url.resolvingSymlinksInPath().absoluteString
            XCTAssertEqual(result, "file:///tmp/")
        } catch {
            XCTFail()
        }
    }

    func test_copy() {
        let url = NSURL(string: "https://www.swift.org")
        let urlCopy = url!.copy() as! NSURL
        XCTAssertTrue(url!.isEqual(urlCopy))

        let queryItem = NSURLQueryItem(name: "id", value: "23")
        let queryItemCopy = queryItem.copy() as! NSURLQueryItem
        XCTAssertTrue(queryItem.isEqual(queryItemCopy))
    }
}
    
class TestNSURLComponents : XCTestCase {
    static var allTests: [(String, (TestNSURLComponents) -> () throws -> Void)] {
        return [
            ("test_string", test_string),
            ("test_port", test_portSetter),
            ("test_URLRelativeToURL", test_URLRelativeToURL),
        ]
    }
    
    func test_string() {
        for obj in getTestData()! {
            let testDict = obj as! [String: Any]
            let unencodedString = testDict[kURLTestUrlKey] as! String
            let expectedString = NSString(string: unencodedString).stringByAddingPercentEncodingWithAllowedCharacters(.urlPathAllowed)!
            guard let components = URLComponents(string: expectedString) else { continue }
            XCTAssertEqual(components.string!, expectedString, "should be the expected string (\(components.string!) != \(expectedString))")
        }
    }
    
    func test_portSetter() {
        let urlString = "http://myhost.mydomain.com"
        let port: Int = 8080
        let expectedString = "http://myhost.mydomain.com:8080"
        var url = URLComponents(string: urlString)
        url!.port = port
        let receivedString = url!.string
        XCTAssertEqual(receivedString, expectedString, "expected \(expectedString) but received \(receivedString)")
    }

    func test_URLRelativeToURL() {

        let baseURL = URL(string: "https://www.example.com")

        /* test NSURLComponents without authority */
        var compWithAuthority = URLComponents(string: "https://www.swift.org")
        compWithAuthority!.path = "/path/to/file with space.html"
        compWithAuthority!.query = "id=23&search=Foo Bar"
        var expectedString = "https://www.swift.org/path/to/file%20with%20space.html?id=23&search=Foo%20Bar"
        XCTAssertEqual(compWithAuthority!.string, expectedString, "expected \(expectedString) but received \(compWithAuthority!.string)")

        var aURL = compWithAuthority!.url(relativeTo: baseURL)
        XCTAssertNotNil(aURL)
        XCTAssertNil(aURL!.baseURL)
        XCTAssertEqual(aURL!.absoluteString, expectedString, "expected \(expectedString) but received \(aURL!.absoluteString)")

        compWithAuthority!.path = "path/to/file with space.html" //must start with /
        XCTAssertNil(compWithAuthority!.string) // must be nil

        aURL = compWithAuthority!.url(relativeTo: baseURL)
        XCTAssertNil(aURL) //must be nil



        /* test NSURLComponents without authority */
        var compWithoutAuthority = URLComponents()
        compWithoutAuthority.path = "path/to/file with space.html"
        compWithoutAuthority.query = "id=23&search=Foo Bar"
        expectedString = "path/to/file%20with%20space.html?id=23&search=Foo%20Bar"
        XCTAssertEqual(compWithoutAuthority.string, expectedString, "expected \(expectedString) but received \(compWithoutAuthority.string)")

        aURL = compWithoutAuthority.url(relativeTo: baseURL)
        XCTAssertNotNil(aURL)
        expectedString = "https://www.example.com/path/to/file%20with%20space.html?id=23&search=Foo%20Bar"
        XCTAssertEqual(aURL!.absoluteString, expectedString, "expected \(expectedString) but received \(aURL!.absoluteString)")

        compWithoutAuthority.path = "//path/to/file with space.html" //shouldn't start with //
        XCTAssertNil(compWithoutAuthority.string) // must be nil

        aURL = compWithoutAuthority.url(relativeTo: baseURL)
        XCTAssertNil(aURL) //must be nil
    }
}
