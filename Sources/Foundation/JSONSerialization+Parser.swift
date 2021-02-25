//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//


internal struct JSONParser {
    
    private var reader: DocumentReader
    private var depth: Int = 0
    
    init<Bytes: Collection>(bytes: Bytes) where Bytes.Element == UInt8 {
        self.reader = DocumentReader(bytes: [UInt8](bytes))
    }

    internal mutating func parse() throws -> JSONValue {
        let value = try parseValue()
        #if DEBUG
        defer {
            guard self.depth == 0 else {
                preconditionFailure("Expected to end parsing with a depth of 0")
            }
        }
        #endif

        // handle extra character if top level was number
        if case .number = value {
            guard let extraCharacter = reader.value else {
                return value
            }

            switch extraCharacter {
            case ._space, ._return, ._newline, ._tab:
                break
            default:
                throw JSONError.unexpectedCharacter(ascii: extraCharacter, characterIndex: reader.index)
            }
        }

        while let (byte, index) = reader.read() {
            switch byte {
            case ._space, ._return, ._newline, ._tab:
                continue
            default:
                throw JSONError.unexpectedCharacter(ascii: byte, characterIndex: index)
            }
        }

        return value
    }

    // MARK: Generic Value Parsing

    mutating func parseValue() throws -> JSONValue {
        while let (byte, index) = reader.read() {
            switch byte {
            case UInt8(ascii: "\""):
                return .string(try self.parseString())
            case ._openbrace:
                let object = try parseObject()
                return .object(object)
            case ._openbracket:
                let array = try parseArray()
                return .array(array)
            case UInt8(ascii: "f"), UInt8(ascii: "t"):
                let bool = try parseBool()
                return .bool(bool)
            case UInt8(ascii: "n"):
                try self.parseNull()
                return .null

            case UInt8(ascii: "-"), UInt8(ascii: "0") ... UInt8(ascii: "9"):
                let number = try parseNumber()
                return .number(number)
            case ._space, ._return, ._newline, ._tab:
                continue
            default:
                throw JSONError.unexpectedCharacter(ascii: byte, characterIndex: index)
            }
        }

        throw JSONError.unexpectedEndOfFile
    }

    // MARK: - Parse Null -

    mutating func parseNull() throws {
        guard self.reader.read()?.0 == UInt8(ascii: "u"),
              self.reader.read()?.0 == UInt8(ascii: "l"),
              self.reader.read()?.0 == UInt8(ascii: "l")
        else {
            guard let value = reader.value else {
                throw JSONError.unexpectedEndOfFile
            }

            throw JSONError.unexpectedCharacter(ascii: value, characterIndex: self.reader.index)
        }
    }

    // MARK: - Parse Bool -

    mutating func parseBool() throws -> Bool {
        switch self.reader.value {
        case UInt8(ascii: "t"):
            guard self.reader.read()?.0 == UInt8(ascii: "r"),
                  self.reader.read()?.0 == UInt8(ascii: "u"),
                  self.reader.read()?.0 == UInt8(ascii: "e")
            else {
                guard let value = reader.value else {
                    throw JSONError.unexpectedEndOfFile
                }

                throw JSONError.unexpectedCharacter(ascii: value, characterIndex: self.reader.index)
            }

            return true
        case UInt8(ascii: "f"):
            guard self.reader.read()?.0 == UInt8(ascii: "a"),
                  self.reader.read()?.0 == UInt8(ascii: "l"),
                  self.reader.read()?.0 == UInt8(ascii: "s"),
                  self.reader.read()?.0 == UInt8(ascii: "e")
            else {
                guard let value = reader.value else {
                    throw JSONError.unexpectedEndOfFile
                }

                throw JSONError.unexpectedCharacter(ascii: value, characterIndex: self.reader.index)
            }

            return false
        default:
            preconditionFailure("Expected to have `t` or `f` as first character")
        }
    }

    // MARK: - Parse String -

    mutating func parseString() throws -> String {
        try self.reader.readUTF8StringTillNextUnescapedQuote()
    }

    // MARK: - Parse Number -

    enum ControlCharacter {
        case operand
        case decimalPoint
        case exp
        case expOperator
    }

    mutating func parseNumber() throws -> String {
        var pastControlChar: ControlCharacter = .operand
        var numbersSinceControlChar: UInt = 0
        var hasLeadingZero = false

        // parse first character

        let stringStartIndex = self.reader.index
        switch self.reader.value! {
        case UInt8(ascii: "0"):
            numbersSinceControlChar = 1
            pastControlChar = .operand
            hasLeadingZero = true
        case UInt8(ascii: "1") ... UInt8(ascii: "9"):
            numbersSinceControlChar = 1
            pastControlChar = .operand
        case UInt8(ascii: "-"):
            numbersSinceControlChar = 0
            pastControlChar = .operand
        default:
            preconditionFailure("This state should never be reached")
        }

        // parse everything else

        while let (byte, index) = reader.read() {
            switch byte {
            case UInt8(ascii: "0"):
                if hasLeadingZero {
                    throw JSONError.numberWithLeadingZero(index: index)
                }
                if numbersSinceControlChar == 0, pastControlChar == .operand {
                    // the number started with a minus. this is the leading zero.
                    hasLeadingZero = true
                }
                numbersSinceControlChar += 1
            case UInt8(ascii: "1") ... UInt8(ascii: "9"):
                if hasLeadingZero {
                    throw JSONError.numberWithLeadingZero(index: index)
                }
                numbersSinceControlChar += 1
            case UInt8(ascii: "."):
                guard numbersSinceControlChar > 0, pastControlChar == .operand else {
                    throw JSONError.unexpectedCharacter(ascii: byte, characterIndex: index)
                }

                hasLeadingZero = false

                pastControlChar = .decimalPoint
                numbersSinceControlChar = 0

            case UInt8(ascii: "e"), UInt8(ascii: "E"):
                guard numbersSinceControlChar > 0,
                      pastControlChar == .operand || pastControlChar == .decimalPoint
                else {
                    throw JSONError.unexpectedCharacter(ascii: byte, characterIndex: index)
                }

                hasLeadingZero = false

                pastControlChar = .exp
                numbersSinceControlChar = 0
            case UInt8(ascii: "+"), UInt8(ascii: "-"):
                guard numbersSinceControlChar == 0, pastControlChar == .exp else {
                    throw JSONError.unexpectedCharacter(ascii: byte, characterIndex: index)
                }

                pastControlChar = .expOperator
                numbersSinceControlChar = 0
            case ._space, ._return, ._newline, ._tab:
                guard numbersSinceControlChar > 0 else {
                    throw JSONError.unexpectedCharacter(ascii: byte, characterIndex: index)
                }

                return self.reader.makeStringFast(self.reader[stringStartIndex ..< index])
            case ._comma, ._closebracket, ._closebrace:
                guard numbersSinceControlChar > 0 else {
                    throw JSONError.unexpectedCharacter(ascii: byte, characterIndex: index)
                }

                return self.reader.makeStringFast(self.reader[stringStartIndex ..< index])
            default:
                throw JSONError.unexpectedCharacter(ascii: byte, characterIndex: index)
            }
        }

        guard numbersSinceControlChar > 0 else {
            throw JSONError.unexpectedEndOfFile
        }

        return String(decoding: self.reader.remainingBytes(from: stringStartIndex), as: Unicode.UTF8.self)
    }

    // MARK: - Parse Array -

    enum ArrayState {
        case expectValueOrEnd
        case expectValue
        case expectSeperatorOrEnd
    }

    mutating func parseArray() throws -> [JSONValue] {
        assert(self.reader.value == ._openbracket)
        guard self.depth < 512 else {
            throw JSONError.tooManyNestedArraysOrDictionaries(characterIndex: self.reader.index)
        }
        self.depth += 1
        defer { depth -= 1 }
        var state = ArrayState.expectValueOrEnd

        var array = [JSONValue]()
        array.reserveCapacity(10)

        // parse first value or immidiate end

        do {
            let value = try parseValue()
            array.append(value)

            if case .number = value {
                guard let extraByte = reader.value else {
                    throw JSONError.unexpectedEndOfFile
                }

                switch extraByte {
                case ._comma:
                    state = .expectValue
                case ._closebracket:
                    return array
                case ._space, ._return, ._newline, ._tab:
                    state = .expectSeperatorOrEnd
                default:
                    throw JSONError.unexpectedCharacter(ascii: extraByte, characterIndex: reader.index)
                }
            } else {
                state = .expectSeperatorOrEnd
            }
        } catch JSONError.unexpectedCharacter(ascii: ._closebracket, _) {
            return []
        }

        // parse further

        while true {
            switch state {
            case .expectSeperatorOrEnd:
                // parsing for seperator or end

                seperatorloop: while let (byte, index) = reader.read() {
                    switch byte {
                    case ._space, ._return, ._newline, ._tab:
                        continue
                    case ._closebracket:
                        return array
                    case ._comma:
                        state = .expectValue
                        break seperatorloop
                    default:
                        throw JSONError.unexpectedCharacter(ascii: byte, characterIndex: index)
                    }
                }

                if state != .expectValue {
                    throw JSONError.unexpectedEndOfFile
                }
            case .expectValue:
                let value = try parseValue()
                array.append(value)

                guard case .number = value else {
                    state = .expectSeperatorOrEnd
                    continue
                }

                guard let extraByte = reader.value else {
                    throw JSONError.unexpectedEndOfFile
                }

                switch extraByte {
                case ._comma:
                    state = .expectValue
                case ._closebracket:
                    return array
                case ._space, ._return, ._newline, ._tab:
                    state = .expectSeperatorOrEnd
                default:
                    throw JSONError.unexpectedCharacter(ascii: extraByte, characterIndex: self.reader.index)
                }
            case .expectValueOrEnd:
                preconditionFailure("this state should not be reachable at this point")
            }
        }
    }

    // MARK: - Object parsing -

    enum ObjectState: Equatable {
        case expectKeyOrEnd
        case expectKey
        case expectColon(key: String)
        case expectValue(key: String)
        case expectSeperatorOrEnd
    }

    mutating func parseObject() throws -> [String: JSONValue] {
        assert(self.reader.value == ._openbrace)
        guard self.depth < 512 else {
            throw JSONError.tooManyNestedArraysOrDictionaries(characterIndex: self.reader.index)
        }
        self.depth += 1
        defer { depth -= 1 }

        var state = ObjectState.expectKeyOrEnd

        // parse first key or end immidiatly
        loop: while let (byte, index) = reader.read() {
            switch byte {
            case ._space, ._return, ._newline, ._tab:
                continue
            case UInt8(ascii: "\""):
                state = .expectColon(key: try self.parseString())
                break loop
            case ._closebrace:
                return [:]
            default:
                throw JSONError.unexpectedCharacter(ascii: byte, characterIndex: index)
            }
        }

        guard case .expectColon = state else {
            throw JSONError.unexpectedEndOfFile
        }

        var object = [String: JSONValue]()
        object.reserveCapacity(20)

        while true {
            switch state {
            case .expectKey:
                keyloop: while let (byte, index) = reader.read() {
                    switch byte {
                    case UInt8(ascii: "\""):
                        let key = try parseString()
                        state = .expectColon(key: key)
                        break keyloop
                    case ._space, ._return, ._newline, ._tab:
                        continue
                    default:
                        throw JSONError.unexpectedCharacter(ascii: byte, characterIndex: index)
                    }
                }

                guard case .expectColon = state else {
                    throw JSONError.unexpectedEndOfFile
                }

            case .expectColon(let key):
                colonloop: while let (byte, index) = reader.read() {
                    switch byte {
                    case ._space, ._return, ._newline, ._tab:
                        continue
                    case ._colon:
                        state = .expectValue(key: key)
                        break colonloop
                    default:
                        throw JSONError.unexpectedCharacter(ascii: byte, characterIndex: index)
                    }
                }

                guard case .expectValue = state else {
                    throw JSONError.unexpectedEndOfFile
                }

            case .expectValue(let key):
                let value = try parseValue()
                object[key] = value

                // special handling for numbers
                guard case .number = value else {
                    state = .expectSeperatorOrEnd
                    continue
                }

                guard let extraByte = reader.value else {
                    throw JSONError.unexpectedEndOfFile
                }

                switch extraByte {
                case ._comma:
                    state = .expectKey
                case ._closebrace:
                    return object
                case ._space, ._return, ._newline, ._tab:
                    state = .expectSeperatorOrEnd
                default:
                    throw JSONError.unexpectedCharacter(ascii: extraByte, characterIndex: self.reader.index)
                }

            case .expectSeperatorOrEnd:
                seperatorloop: while let (byte, index) = reader.read() {
                    switch byte {
                    case ._space, ._return, ._newline, ._tab:
                        continue
                    case ._closebrace:
                        return object
                    case ._comma:
                        state = .expectKey
                        break seperatorloop
                    default:
                        throw JSONError.unexpectedCharacter(ascii: byte, characterIndex: index)
                    }
                }

                guard case .expectKey = state else {
                    throw JSONError.unexpectedEndOfFile
                }
            case .expectKeyOrEnd:
                preconditionFailure("this state should be unreachable here")
            }
        }
    }
}

private extension JSONParser {
    
    struct DocumentReader {
        let array: [UInt8]
        let count: Int

        private(set) var index: Int = -1
        private(set) var value: UInt8?

        init(bytes: [UInt8]) {
            self.array = bytes
            self.count = self.array.count
        }

        subscript(bounds: Range<Int>) -> ArraySlice<UInt8> {
            self.array[bounds]
        }

        mutating func read() -> (UInt8, Int)? {
            guard self.index < self.count - 1 else {
                self.value = nil
                self.index = self.array.endIndex
                return nil
            }

            self.index += 1
            self.value = self.array[self.index]

            return (self.value!, self.index)
        }

        func remainingBytes(from index: Int) -> ArraySlice<UInt8> {
            self.array.suffix(from: index)
        }

        enum EscapedSequenceError: Swift.Error {
            case expectedLowSurrogateUTF8SequenceAfterHighSurrogate(index: Int)
            case unexpectedEscapedCharacter(ascii: UInt8, index: Int)
            case couldNotCreateUnicodeScalarFromUInt32(index: Int, unicodeScalarValue: UInt32)
        }

        mutating func readUTF8StringTillNextUnescapedQuote() throws -> String {
            precondition(self.value == UInt8(ascii: "\""), "Expected to have read a quote character last")
            var stringStartIndex = self.index + 1
            var output: String?

            while let (byte, index) = read() {
                switch byte {
                case UInt8(ascii: "\""):
                    guard var result = output else {
                        // if we don't have an output string we create a new string
                        return self.makeStringFast(self.array[stringStartIndex ..< index])
                    }
                    // if we have an output string we append
                    result += self.makeStringFast(self.array[stringStartIndex ..< index])
                    return result

                case 0 ... 31:
                    // All Unicode characters may be placed within the
                    // quotation marks, except for the characters that must be escaped:
                    // quotation mark, reverse solidus, and the control characters (U+0000
                    // through U+001F).
                    var string = output ?? ""
                    string += self.makeStringFast(self.array[stringStartIndex ... index])
                    throw JSONError.unescapedControlCharacterInString(ascii: byte, in: string, index: index)

                case UInt8(ascii: "\\"):
                    if output != nil {
                        output! += self.makeStringFast(self.array[stringStartIndex ..< index])
                    } else {
                        output = self.makeStringFast(self.array[stringStartIndex ..< index])
                    }

                    do {
                        let (escaped, newIndex) = try parseEscapeSequence()
                        output! += escaped
                        stringStartIndex = newIndex + 1
                    } catch EscapedSequenceError.unexpectedEscapedCharacter(let ascii, let failureIndex) {
                        output! += makeStringFast(array[index ... self.index])
                        throw JSONError.unexpectedEscapedCharacter(ascii: ascii, in: output!, index: failureIndex)
                    } catch EscapedSequenceError.expectedLowSurrogateUTF8SequenceAfterHighSurrogate(let failureIndex) {
                        output! += makeStringFast(array[index ... self.index])
                        throw JSONError.expectedLowSurrogateUTF8SequenceAfterHighSurrogate(in: output!, index: failureIndex)
                    } catch EscapedSequenceError.couldNotCreateUnicodeScalarFromUInt32(let failureIndex, let unicodeScalarValue) {
                        output! += makeStringFast(array[index ... self.index])
                        throw JSONError.couldNotCreateUnicodeScalarFromUInt32(
                            in: output!, index: failureIndex, unicodeScalarValue: unicodeScalarValue
                        )
                    }

                default:
                    continue
                }
            }

            throw JSONError.unexpectedEndOfFile
        }

        // can be removed as soon https://bugs.swift.org/browse/SR-12126 and
        // https://bugs.swift.org/browse/SR-12125 has landed.
        // Thanks @weissi for making my code fast!
        func makeStringFast<Bytes: Collection>(_ bytes: Bytes) -> String where Bytes.Element == UInt8 {
            if let string = bytes.withContiguousStorageIfAvailable({ String(decoding: $0, as: Unicode.UTF8.self) }) {
                return string
            } else {
                return String(decoding: bytes, as: Unicode.UTF8.self)
            }
        }

        mutating func parseEscapeSequence() throws -> (String, Int) {
            guard let (byte, index) = read() else {
                throw JSONError.unexpectedEndOfFile
            }

            switch byte {
            case 0x22: return ("\"", index)
            case 0x5C: return ("\\", index)
            case 0x2F: return ("/", index)
            case 0x62: return ("\u{08}", index) // \b
            case 0x66: return ("\u{0C}", index) // \f
            case 0x6E: return ("\u{0A}", index) // \n
            case 0x72: return ("\u{0D}", index) // \r
            case 0x74: return ("\u{09}", index) // \t
            case 0x75:
                let (character, newIndex) = try parseUnicodeSequence()
                return (String(character), newIndex)
            default:
                throw EscapedSequenceError.unexpectedEscapedCharacter(ascii: byte, index: index)
            }
        }

        mutating func parseUnicodeSequence() throws -> (Unicode.Scalar, Int) {
            // we build this for utf8 only for now.
            let bitPattern = try parseUnicodeHexSequence()

            // check if high surrogate
            let isFirstByteHighSurrogate = bitPattern & 0xFC00 // nil everything except first six bits
            if isFirstByteHighSurrogate == 0xD800 {
                // if we have a high surrogate we expect a low surrogate next
                let highSurrogateBitPattern = bitPattern
                guard let (escapeChar, _) = read(),
                      let (uChar, _) = read()
                else {
                    throw JSONError.unexpectedEndOfFile
                }

                guard escapeChar == UInt8(ascii: #"\"#), uChar == UInt8(ascii: "u") else {
                    throw EscapedSequenceError.expectedLowSurrogateUTF8SequenceAfterHighSurrogate(index: self.index)
                }

                let lowSurrogateBitBattern = try parseUnicodeHexSequence()
                let isSecondByteLowSurrogate = lowSurrogateBitBattern & 0xFC00 // nil everything except first six bits
                guard isSecondByteLowSurrogate == 0xDC00 else {
                    // we are in an escaped sequence. for this reason an output string must have
                    // been initialized
                    throw EscapedSequenceError.expectedLowSurrogateUTF8SequenceAfterHighSurrogate(index: self.index)
                }

                let highValue = UInt32(highSurrogateBitPattern - 0xD800) * 0x400
                let lowValue = UInt32(lowSurrogateBitBattern - 0xDC00)
                let unicodeValue = highValue + lowValue + 0x10000
                guard let unicode = Unicode.Scalar(unicodeValue) else {
                    throw EscapedSequenceError.couldNotCreateUnicodeScalarFromUInt32(
                        index: self.index, unicodeScalarValue: unicodeValue
                    )
                }
                return (unicode, self.index)
            }

            guard let unicode = Unicode.Scalar(bitPattern) else {
                throw EscapedSequenceError.couldNotCreateUnicodeScalarFromUInt32(
                    index: self.index, unicodeScalarValue: UInt32(bitPattern)
                )
            }
            return (unicode, self.index)
        }

        mutating func parseUnicodeHexSequence() throws -> UInt16 {
            // As stated in RFC-8259 an escaped unicode character is 4 HEXDIGITs long
            // https://tools.ietf.org/html/rfc8259#section-7
            guard let (firstHex, startIndex) = read(),
                  let (secondHex, _) = read(),
                  let (thirdHex, _) = read(),
                  let (forthHex, _) = read()
            else {
                throw JSONError.unexpectedEndOfFile
            }

            guard let first = DocumentReader.hexAsciiTo4Bits(firstHex),
                  let second = DocumentReader.hexAsciiTo4Bits(secondHex),
                  let third = DocumentReader.hexAsciiTo4Bits(thirdHex),
                  let forth = DocumentReader.hexAsciiTo4Bits(forthHex)
            else {
                let hexString = String(decoding: [firstHex, secondHex, thirdHex, forthHex], as: Unicode.UTF8.self)
                throw JSONError.invalidHexDigitSequence(hexString, index: startIndex)
            }
            let firstByte = UInt16(first) << 4 | UInt16(second)
            let secondByte = UInt16(third) << 4 | UInt16(forth)

            let bitPattern = UInt16(firstByte) << 8 | UInt16(secondByte)

            return bitPattern
        }

        static func hexAsciiTo4Bits(_ ascii: UInt8) -> UInt8? {
            switch ascii {
            case 48 ... 57:
                return ascii - 48
            case 65 ... 70:
                // uppercase letters
                return ascii - 55
            case 97 ... 102:
                // lowercase letters
                return ascii - 87
            default:
                return nil
            }
        }
    }
}

enum JSONError: Swift.Error, Equatable {
    case unexpectedCharacter(ascii: UInt8, characterIndex: Int)
    case unexpectedEndOfFile
    case tooManyNestedArraysOrDictionaries(characterIndex: Int)
    case invalidHexDigitSequence(String, index: Int)
    case unexpectedEscapedCharacter(ascii: UInt8, in: String, index: Int)
    case unescapedControlCharacterInString(ascii: UInt8, in: String, index: Int)
    case expectedLowSurrogateUTF8SequenceAfterHighSurrogate(in: String, index: Int)
    case couldNotCreateUnicodeScalarFromUInt32(in: String, index: Int, unicodeScalarValue: UInt32)
    case numberWithLeadingZero(index: Int)
    case numberIsNotRepresentableInSwift(parsed: String)
    case singleFragmentFoundButNotAllowed
}

extension UInt8 {
    
    internal static let _space = UInt8(ascii: " ")
    internal static let _return = UInt8(ascii: "\r")
    internal static let _newline = UInt8(ascii: "\n")
    internal static let _tab = UInt8(ascii: "\t")
    
    internal static let _colon = UInt8(ascii: ":")
    internal static let _comma = UInt8(ascii: ",")
    
    internal static let _openbrace = UInt8(ascii: "{")
    internal static let _closebrace = UInt8(ascii: "}")
    
    internal static let _openbracket = UInt8(ascii: "[")
    internal static let _closebracket = UInt8(ascii: "]")
    
}
