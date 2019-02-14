// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestPropertyListEncoder : XCTestCase {
    static var allTests: [(String, (TestPropertyListEncoder) -> () throws -> Void)] {
        return [
            ("test_basicEncodeDecode", test_basicEncodeDecode),
            ("test_xmlDecoder", test_xmlDecoder),
        ]
    }
}

extension TestPropertyListEncoder {
    class TestBaseClass: Codable {
        enum IntEnum: Int, Codable, Equatable {
            case one = 1
            case two
        }
        
        struct InnerStruct: Codable, Equatable {
            enum StringEnum: String, Codable, Equatable {
                case one = "1"
                case two
            }
            
            let string: String?
            let optionalInt: Int?
            let url: URL
            let stringEnum: StringEnum?
            var data: Data
            var date: Date?
        }
        
        let intEnum: IntEnum
        let innerStruct: InnerStruct

        init(intEnum: IntEnum, innerStruct: InnerStruct) {
            self.intEnum = intEnum
            self.innerStruct = innerStruct
        }
    }
    
    func test_basicEncodeDecode() throws {
        let propertyListFormats: [PropertyListSerialization.PropertyListFormat?] = [nil, .binary, .xml]
        
        for format in propertyListFormats {
            let optionalInt: Int? = 1234
            let url = URL(string: "https://swift.org")!
            let innerClassString = "demo_string"
            let testData = innerClassString.data(using: .utf8)!
            let testDate = Date.distantPast
            
            let innerStruct = TestBaseClass.InnerStruct(string: innerClassString, optionalInt: optionalInt, url: url, stringEnum: .two, data: testData, date: testDate)
            let testClass = TestBaseClass(intEnum: .one, innerStruct: innerStruct)
            
            let encoder = PropertyListEncoder()
            if let format = format {
                encoder.outputFormat = format
            }
            let data = try? encoder.encode(testClass)
            XCTAssertNotNil(data)
            
            let decoder = PropertyListDecoder()
            let decodedClass: TestBaseClass
            decodedClass = try decoder.decode(TestBaseClass.self, from: data!)
            XCTAssertEqual(decodedClass.innerStruct, testClass.innerStruct)
            XCTAssertEqual(decodedClass.intEnum, testClass.intEnum)
            
            if format == .xml {
                XCTAssertNotNil(String(data: data!, encoding: .utf8))
            }
        }
    }
}

extension TestPropertyListEncoder {
    static let propertyListXML = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>xdgTestHelper</string>
    <key>CFBundleIdentifier</key>
    <string>org.swift.xdgTestHelper</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <real>6.0</real>
    <key>CFBundleIntKey</key>
    <integer>-100</integer>
    <key>CFBundleBoolKey</key>
    <true/>
    <key>CFBundleOtherKey</key>
    <string>other...</string>
    <key>CFBundleDataArrayKey</key>
    <array>
        <data>
        VEVTVF9EQVRB
        </data>
    </array>
    <key>CFBundleDateKey</key>
    <date>1970-01-01T00:00:20Z</date>
    </dict>
    </plist>
    """
    
    struct InfoPlist: Codable, Equatable {
        let CFBundleDevelopmentRegion: String
        let CFBundleExecutable: String?
        let CFBundleIdentifier: String
        let CFBundleInfoDictionaryVersion: Double
        let CFBundleIntKey: Int
        let CFFakeOptionalKey: Int?
        let CFBundleBoolKey: Bool
        let CFBundleDataArrayKey: [Data]
        let CFBundleDateKey: Date
    }
    
    func test_xmlDecoder() throws {
        let resultInfoPlist = InfoPlist(
            CFBundleDevelopmentRegion: "en",
            CFBundleExecutable: "xdgTestHelper",
            CFBundleIdentifier: "org.swift.xdgTestHelper",
            CFBundleInfoDictionaryVersion: 6.0,
            CFBundleIntKey: -100,
            CFFakeOptionalKey: nil,
            CFBundleBoolKey: true,
            CFBundleDataArrayKey: ["TEST_DATA".data(using: .utf8)!],
            CFBundleDateKey: Date(timeIntervalSince1970: 20)
        )
        
        let testData = TestPropertyListEncoder.propertyListXML.data(using: .utf8)!
        let decoder = PropertyListDecoder()
        var format: PropertyListSerialization.PropertyListFormat = .binary
        let decodedInfoPlist = try decoder.decode(InfoPlist.self, from: testData, format: &format)
        XCTAssertEqual(format, .xml)
        XCTAssertEqual(decodedInfoPlist, resultInfoPlist)
    }
}
