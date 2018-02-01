# Key Strategies for JSONEncoder and JSONDecoder

* Proposal: SCLF-0001
* Author(s): Tony Parker <anthony.parker@apple.com>

##### Related radars or Swift bugs

* <rdar://problem/33019707> Snake case / Camel case conversions for JSONEncoder/Decoder

##### Revision history

* **v1** Initial version

## Introduction

While early feedback for `JSONEncoder` and `JSONDecoder` has been very positive, many developers have told us that they would appreciate a convenience for converting between `snake_case_keys` and `camelCaseKeys` without having to manually specify the key values for all types.

## Proposed solution

`JSONEncoder` and `JSONDecoder` will gain new strategy properties to allow for conversion of keys during encoding and decoding.

```swift
class JSONDecoder {
    /// The strategy to use for automatically changing the value of keys before decoding.
    public enum KeyDecodingStrategy {
        /// Use the keys specified by each type. This is the default strategy.
        case useDefaultKeys
        
        /// Convert from "snake_case_keys" to "camelCaseKeys" before attempting to match a key with the one specified by each type.
        /// 
        /// The conversion to upper case uses `Locale.system`, also known as the ICU "root" locale. This means the result is consistent regardless of the current user's locale and language preferences.
        ///
        /// Converting from snake case to camel case:
        /// 1. Capitalizes the word starting after each `_`
        /// 2. Removes all `_`
        /// 3. Preserves starting and ending `_` (as these are often used to indicate private variables or other metadata).
        /// For example, `one_two_three` becomes `oneTwoThree`. `_one_two_three_` becomes `_oneTwoThree_`.
        ///
        /// - Note: Using a key decoding strategy has a nominal performance cost, as each string key has to be inspected for the `_` character.
        case convertFromSnakeCase
        
        /// Provide a custom conversion from the key in the encoded JSON to the keys specified by the decoded types.
        /// The full path to the current decoding position is provided for context (in case you need to locate this key within the payload). The returned key is used in place of the last component in the coding path before decoding.
        case custom(([CodingKey]) -> CodingKey)
    }
    
    /// The strategy to use for decoding keys. Defaults to `.useDefaultKeys`.
    open var keyDecodingStrategy: KeyDecodingStrategy = .useDefaultKeys
}

class JSONEncoder {
    /// The strategy to use for automatically changing the value of keys before encoding.
    public enum KeyEncodingStrategy {
        /// Use the keys specified by each type. This is the default strategy.
        case useDefaultKeys
        
        /// Convert from "camelCaseKeys" to "snake_case_keys" before writing a key to JSON payload.
        ///
        /// Capital characters are determined by testing membership in `CharacterSet.uppercaseLetters` and `CharacterSet.lowercaseLetters` (Unicode General Categories Lu and Lt).
        /// The conversion to lower case uses `Locale.system`, also known as the ICU "root" locale. This means the result is consistent regardless of the current user's locale and language preferences.
        ///
        /// Converting from camel case to snake case:
        /// 1. Splits words at the boundary of lower-case to upper-case
        /// 2. Inserts `_` between words
        /// 3. Lowercases the entire string
        /// 4. Preserves starting and ending `_`.
        ///
        /// For example, `oneTwoThree` becomes `one_two_three`. `_oneTwoThree_` becomes `_one_two_three_`.
        ///
        /// - Note: Using a key encoding strategy has a nominal performance cost, as each string key has to be converted.
        case convertToSnakeCase
        
        /// Provide a custom conversion to the key in the encoded JSON from the keys specified by the encoded types.
        /// The full path to the current encoding position is provided for context (in case you need to locate this key within the payload). The returned key is used in place of the last component in the coding path before encoding.
        case custom(([CodingKey]) -> CodingKey)
    }
    
    
    /// The strategy to use for encoding keys. Defaults to `.useDefaultKeys`.
    open var keyEncodingStrategy: KeyEncodingStrategy = .useDefaultKeys
}
```

## Detailed design

The strategy enum allows developers to pick from common actions of converting to and from `snake_case` to the Swift-standard `camelCase`. The implementation is intentionally simple, because we want to make the rules predictable.

Converting from snake case to camel case:

1. Capitalizes the word starting after each `_`
2. Removes all `_`
3. Preserves starting and ending `_` (as these are often used to indicate private variables or other metadata).

For example, `one_two_three` becomes `oneTwoThree`. `_one_two_three_` becomes `_oneTwoThree_`.

Converting from camel case to snake case:

1. Splits words at the boundary of lower-case to upper-case
2. Inserts `_` between words
3. Lowercases the entire string
4. Preserves starting and ending `_`.

For example, `oneTwoThree` becomes `one_two_three`. `_oneTwoThree_` becomes `_one_two_three_`.

We also provide a `custom` action for both encoding and decoding to allow for maximum flexibility if the built-in options are not sufficient.

## Example

Given this JSON:

```
{ "hello_world" : 3, "goodbye_cruel_world" : 10, "key" : 42 }
```

Previously, you would customize your `Decodable` type with custom keys, like this:

```swift
struct Thing : Decodable {

    let helloWorld : Int
    let goodbyeCruelWorld: Int
    let key: Int

    private enum CodingKeys : CodingKey {
        case helloWorld = "hello_world"
        case goodbyeCruelWorld = "goodbye_cruel_world"
        case key
    }
}

var decoder = JSONDecoder()
let result = try! decoder.decode(Thing.self, from: data)
```

With this change, you can write much less boilerplate:

```swift
struct Thing : Decodable {

    let helloWorld : Int
    let goodbyeCruelWorld: Int
    let key: Int
}

var decoder = JSONDecoder()
decoder.keyDecodingStrategy = .convertFromSnakeCase
let result = try! decoder.decode(Thing.self, from: data)
```

## Alternatives considered

None.
