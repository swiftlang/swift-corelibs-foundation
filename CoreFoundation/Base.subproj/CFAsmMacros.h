// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if !defined(__COREFOUNDATION_CFASMMACROS__)
#define __COREFOUNDATION_CFASMMACROS__ 1

#define CONCAT(a,b) a##b
#define CONCAT_EXPANDED(a,b) CONCAT(a,b)
#define _C_LABEL(name) CONCAT_EXPANDED(__USER_LABEL_PREFIX__,name)

#if defined(__GNU__) || defined(__GNUC__) || defined(__ANDROID__) || defined(__FreeBSD__)
#define NO_EXEC_STACK_DIRECTIVE .section .note.GNU-stack,"",%progbits
#else
#define NO_EXEC_STACK_DIRECTIVE
#endif

#endif

