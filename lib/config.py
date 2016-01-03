# This source file is part of the Swift.org open source project
#
# Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
#
# See http://swift.org/LICENSE.txt for license information
# See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
#

import json

from .path import Path

class Configuration:
    Debug = "debug"
    Release = "release"
    version = 1

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
    ar = None
    swift_sdk = None
    bootstrap_directory = None
    verbose = False
    extra_c_flags = None
    extra_swift_flags = None
    extra_ld_flags = None
    build_mode = None
    config_path = None # dont save this; else it would be recursive
    variables = {}
    def __init__(self):
        pass

    def _encode_path(self, path):
        if path is not None:
            return path.absolute()
        else:
            return None

    def write(self, path):
        info = {
            'version' : self.version,
            'command' : self.command,
            'project' : self.project,
            'script_path' : self._encode_path(self.script_path),
            'build_script_path' : self._encode_path(self.build_script_path),
            'source_root' : self._encode_path(self.source_root),
            'target' : self.target.triple,
            'system_root' : self._encode_path(self.system_root),
            'toolchain' : self.toolchain,
            'build_directory' : self._encode_path(self.build_directory),
            'intermediate_directory' : self._encode_path(self.intermediate_directory),
            'module_cache_directory' : self._encode_path(self.module_cache_directory),
            'install_directory' : self._encode_path(self.install_directory),
            'prefix' : self.prefix,
            'swift_install' : self.swift_install,
            'clang' : self.clang,
            'clangxx' : self.clangxx,
            'swift' : self.swift,
            'swiftc' : self.swiftc,
            'ar' : self.ar,
            'swift_sdk' : self.swift_sdk,
            'bootstrap_directory' : self._encode_path(self.bootstrap_directory),
            'verbose' : self.verbose,
            'extra_c_flags' : self.extra_c_flags,
            'extra_swift_flags' : self.extra_swift_flags,
            'extra_ld_flags' : self.extra_ld_flags,
            'build_mode' : self.build_mode,
            'variables' : self.variables,
        }
        with open(path, 'w+') as outfile:
            json.dump(info, outfile)
        