//
//  TestURLCache.swift
//  TestFoundation
//
//  Created by Karthikkeyan Bala Sundaram on 3/8/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import SQLite3

class TestURLCache: XCTestCase {

    static var allTests: [(String, (TestURLCache) -> () throws -> Void)] {
        return [
            ("test_cacheFileAndDirectorySetup", test_cacheFileAndDirectorySetup),
            ("test_cacheDatabaseTables", test_cacheDatabaseTables),
            ("test_cacheDatabaseIndices", test_cacheDatabaseIndices),
        ]
    }
    
    private var cacheDirectoryPath: String {
        if let path = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.path {
            return "\(path)/org.swift.TestFoundation"
        } else {
            return "\(NSHomeDirectory())/Library/Caches/org.swift.TestFoundation"
        }
    }
    
    private var cacheDatabasePath: String {
        return "\(cacheDirectoryPath)/Cache.db"
    }
    
    func test_cacheFileAndDirectorySetup() {
        let _ = URLCache.shared
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: cacheDirectoryPath))
        XCTAssertTrue(FileManager.default.fileExists(atPath: cacheDatabasePath))
    }
    
    func test_cacheDatabaseTables() {
        let _ = URLCache.shared
        
        var db: OpaquePointer? = nil
        let openDBResult = sqlite3_open_v2(cacheDatabasePath, &db, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE, nil)
        XCTAssertTrue(openDBResult == SQLITE_OK, "Unable to open database")
        
        var statement: OpaquePointer? = nil
        let prepareResult = sqlite3_prepare_v2(db!, "select tbl_name from sqlite_master where type='table'", -1, &statement, nil)
        XCTAssertTrue(prepareResult == SQLITE_OK, "Unable to prepare list tables statement")
        
        var tables = ["cfurl_cache_response": false, "cfurl_cache_receiver_data": false, "cfurl_cache_blob_data": false, "cfurl_cache_schema_version": false]
        while sqlite3_step(statement!) == SQLITE_ROW {
            let tableName = String(cString: sqlite3_column_text(statement!, 0))
            tables[tableName] = true
        }
        
        let tablesNotExist = tables.filter({ !$0.value })
        if tablesNotExist.count == tables.count {
            XCTFail("No tables created for URLCache")
        }
        
        XCTAssertTrue(tablesNotExist.count == 0, "Table(s) not created: \(tablesNotExist.map({ $0.key }).joined(separator: ", "))")
        sqlite3_close_v2(db!)
    }
    
    func test_cacheDatabaseIndices() {
        let _ = URLCache.shared
        
        var db: OpaquePointer? = nil
        let openDBResult = sqlite3_open_v2(cacheDatabasePath, &db, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE, nil)
        XCTAssertTrue(openDBResult == SQLITE_OK, "Unable to open database")
        
        var statement: OpaquePointer? = nil
        let prepareResult = sqlite3_prepare_v2(db!, "select name from sqlite_master where type='index'", -1, &statement, nil)
        XCTAssertTrue(prepareResult == SQLITE_OK, "Unable to prepare list tables statement")
        
        var indices = ["proto_props_index": false, "receiver_data_index": false, "request_key_index": false, "time_stamp_index": false]
        while sqlite3_step(statement!) == SQLITE_ROW {
            let name = String(cString: sqlite3_column_text(statement!, 0))
            indices[name] = true
        }
        
        let indicesNotExist = indices.filter({ !$0.value })
        if indicesNotExist.count == indices.count {
            XCTFail("No index created for URLCache")
        }
        
        XCTAssertTrue(indicesNotExist.count == 0, "Indices not created: \(indicesNotExist.map({ $0.key }).joined(separator: ", "))")
        sqlite3_close_v2(db!)
    }
    
}
