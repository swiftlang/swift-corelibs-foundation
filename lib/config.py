# This source file is part of the Swift.org open source project
#
# Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
#
# See http://swift.org/LICENSE.txt for license information
# See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
#

class Configuration:
    Debug = "debug"
    Release = "release"

    command = None
    current = None
    project = None
    script_path = None
    build_script_path = None
    source_root = None
    target = None
    system_root = None
    toolchain = None
    build_directory = None
    intermediate_directory = None
    module_cache_directory = None
    install_directory = None
    prefix = None
    swift_install = None
    clang = None
    clangxx = None
    swift = None
    swiftc = None
    swift_sdk = None
    bootstrap_directory = None
    verbose = False
    extra_c_flags = None
    extra_swift_flags = None
    extra_ld_flags = None
    build_mode = None
    variables = {}
    def __init__(self):
        pass