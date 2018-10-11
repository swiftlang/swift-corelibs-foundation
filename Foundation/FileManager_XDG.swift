// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

enum _XDGUserDirectory: String {
    case desktop = "DESKTOP"
    case download = "DOWNLOAD"
    case publicShare = "PUBLICSHARE"
    case documents = "DOCUMENTS"
    case music = "MUSIC"
    case pictures = "PICTURES"
    case videos = "VIDEOS"
    
    static let allDirectories: [_XDGUserDirectory] = [
        .desktop,
        .download,
        .publicShare,
        .documents,
        .music,
        .pictures,
        .videos,
    ]
    
    var url: URL {
        return url(userConfiguration: _XDGUserDirectory.configuredDirectoryURLs,
                   osDefaultConfiguration: _XDGUserDirectory.osDefaultDirectoryURLs,
                   stopgaps: _XDGUserDirectory.stopgapDefaultDirectoryURLs)
    }
    
    func url(userConfiguration: [_XDGUserDirectory: URL],
             osDefaultConfiguration: [_XDGUserDirectory: URL],
             stopgaps: [_XDGUserDirectory: URL]) -> URL {
        if let url = userConfiguration[self] {
            return url
        } else if let url = osDefaultConfiguration[self] {
            return url
        } else {
            return stopgaps[self]!
        }
    }
    
    static let stopgapDefaultDirectoryURLs: [_XDGUserDirectory: URL] = {
        let home = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
        return [
            .desktop: home.appendingPathComponent("Desktop"),
            .download: home.appendingPathComponent("Downloads"),
            .publicShare: home.appendingPathComponent("Public"),
            .documents: home.appendingPathComponent("Documents"),
            .music: home.appendingPathComponent("Music"),
            .pictures: home.appendingPathComponent("Pictures"),
            .videos: home.appendingPathComponent("Videos"),
        ]
    }()
    
    static func userDirectories(fromConfigurationFileAt url: URL) -> [_XDGUserDirectory: URL]? {
        if let configuration = try? String(contentsOf: url, encoding: .utf8) {
            return userDirectories(fromConfiguration: configuration)
        } else {
            return nil
        }
    }
    
    static func userDirectories(fromConfiguration configuration: String) -> [_XDGUserDirectory: URL] {
        var entries: [_XDGUserDirectory: URL] = [:]
        let home = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
        
        // Parse it:
        let lines = configuration.split(separator: "\n")
        for line in lines {
            if let range = line.range(of: "=") {
                var variable = String(line[line.startIndex ..< range.lowerBound].trimmingCharacters(in: .whitespaces))
                
                let prefix = "XDG_"
                let suffix = "_DIR"
                if variable.hasPrefix(prefix) && variable.hasSuffix(suffix) {
                    let endOfPrefix = variable.index(variable.startIndex, offsetBy: prefix.length)
                    let startOfSuffix = variable.index(variable.endIndex, offsetBy: -suffix.length)
                    
                    variable = String(variable[endOfPrefix ..< startOfSuffix])
                }
                
                guard let directory = _XDGUserDirectory(rawValue: variable) else {
                    continue
                }
                
                let path = String(line[range.upperBound ..< line.endIndex]).trimmingCharacters(in: .whitespaces)
                if !path.isEmpty {
                    entries[directory] = URL(fileURLWithPath: path, isDirectory: true, relativeTo: home)
                }
            } else {
                return [:] // Incorrect syntax.
            }
        }
        
        return entries
    }
    
    static let configuredDirectoryURLs: [_XDGUserDirectory: URL] = {
        let configurationHome = __SwiftValue.fetch(nonOptional: _CFXDGCreateConfigHomePath()) as! String
        let configurationFile = URL(fileURLWithPath: "user-dirs.dirs", isDirectory: false, relativeTo: URL(fileURLWithPath: configurationHome, isDirectory: true))
        
        return userDirectories(fromConfigurationFileAt: configurationFile) ?? [:]
    }()
    
    static let osDefaultDirectoryURLs: [_XDGUserDirectory: URL] = {
        let configurationDirs = __SwiftValue.fetch(nonOptional: _CFXDGCreateConfigDirectoriesPaths()) as! [String]
        
        for directory in configurationDirs {
            let configurationFile = URL(fileURLWithPath: directory, isDirectory: true).appendingPathComponent("user-dirs.defaults")
            
            if let result = userDirectories(fromConfigurationFileAt: configurationFile) {
                return result
            }
        }
        
        return [:]
    }()
}
