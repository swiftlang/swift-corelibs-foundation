// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if defined(__BIG_ENDIAN__)
    .global __CFUnicodeDataB
__CFUnicodeDataB:
    .incbin "CoreFoundation/CharacterSets/CFUnicodeData-B.mapping"

    .global __CFUnicodeDataBEnd
__CFUnicodeDataBEnd:
    .byte 0

    .global __CFUnicodeDataBSize
__CFUnicodeDataBSize:
    .int __CFUnicodeDataBEnd - __CFUnicodeDataB
#else
    .global __CFUnicodeDataL
__CFUnicodeDataL:
    .incbin "CoreFoundation/CharacterSets/CFUnicodeData-L.mapping"

    .global __CFUnicodeDataLEnd
__CFUnicodeDataLEnd:
    .byte 0

    .global __CFUnicodeDataLSize
__CFUnicodeDataLSize:
    .int __CFUnicodeDataLEnd - __CFUnicodeDataL
#endif
