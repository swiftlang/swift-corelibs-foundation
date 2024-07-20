//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

extension JSONDecoder.DateDecodingStrategy {
    public static func formatted(_ formatter: DateFormatter) -> Self {
        .custom { decoder in
            let container = try decoder.singleValueContainer()
            let result = try container.decode(String.self)
            if let date = formatter.date(from: result) {
                return date
            } else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Date string does not match format expected by formatter."))
            }
        }
    }
}
