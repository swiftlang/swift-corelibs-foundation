# This source file is part of the Swift.org open source project
#
# Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
#
# See http://swift.org/LICENSE.txt for license information
# See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
#

from .config import Configuration
import os

class Script:
    products = []
    workspaces = []
    extra = ""

    def __init__(self):
        pass

    def add_product(self, product):
        self.workspaces = None
        self.products.append(product)

    def add_workspace(self, workspace):
        self.products = None
        self.workspaces.append(workspace)

    def add_text(self, text):
        self.extra += text + "\n\n"

    def generate_products(self):
        variables = ""
        for key, val in Configuration.current.variables.items():
            variables += key + "=" + val
        variables += "\n"
        verbose_flags = """
VERBOSE_FLAGS = """ 
        if Configuration.current.verbose:
            verbose_flags += "-v"
        verbose_flags += "\n"
        swift_triple = Configuration.current.target.swift_triple
        base_flags = """
TARGET                = """ + Configuration.current.target.triple + """
DSTROOT               = """ + Configuration.current.install_directory.absolute() + """
"""
        if swift_triple is not None:
            base_flags += """
SWIFT_TARGET          = """ + Configuration.current.target.swift_triple + """
SWIFT_ARCH            = """ + Configuration.current.target.swift_arch + """
"""
        base_flags += """
MODULE_CACHE_PATH     = """ + Configuration.current.module_cache_directory.relative() + """
BUILD_DIR             = """ + Configuration.current.build_directory.relative() + """
INTERMEDIATE_DIR      = """ + Configuration.current.intermediate_directory.relative() + """
CLANG                 = """ + Configuration.current.clang + """
CLANGXX               = """ + Configuration.current.clangxx + """
SWIFT                 = """ + Configuration.current.swift + """
SWIFTC                = """ + Configuration.current.swiftc + """
SDKROOT               = """ + Configuration.current.swift_sdk + """
AR                    = """ + Configuration.current.ar + """
OS                    = """ + Configuration.current.target.swift_sdk_name + """
ARCH                  = """ + Configuration.current.target.swift_arch + """
DYLIB_PREFIX          = """ + Configuration.current.target.dynamic_library_prefix + """
DYLIB_SUFFIX          = """ + Configuration.current.target.dynamic_library_suffix + """
PREFIX                = """ + Configuration.current.prefix + """
"""
        if Configuration.current.system_root is not None:
            base_flags += """
SYSROOT               = """ + Configuration.current.system_root.absolute() + """
"""
        base_flags += """
SRCROOT               = """ + Configuration.current.source_root.relative() + """
BINUTILS_VERSION      = 4.8
TARGET_LDSYSROOT      =
"""
        
        if Configuration.current.bootstrap_directory is not None:
            base_flags += """
BOOTSTRAP_DIR         = """ + Configuration.current.bootstrap_directory.relative() + """/common
TARGET_BOOTSTRAP_DIR  = """ + Configuration.current.bootstrap_directory.relative() + """/${TARGET}
"""

        c_flags = """
TARGET_CFLAGS         = -fcolor-diagnostics -fdollars-in-identifiers -fblocks -fobjc-runtime=macosx-10.11 -fintegrated-as -fPIC --target=${TARGET} """

        if Configuration.current.build_mode == Configuration.Debug:
            c_flags += "-g -O0 "
        elif Configuration.current.build_mode == Configuration.Release:
            c_flags += "-O2 "

        if Configuration.current.system_root is not None:
            c_flags += "--sysroot=${SYSROOT}"

        if Configuration.current.bootstrap_directory is not None:
            c_flags += """  -I${BOOTSTRAP_DIR}/usr/include -I${BOOTSTRAP_DIR}/usr/local/include """
            c_flags += """  -I${TARGET_BOOTSTRAP_DIR}/usr/include -I${TARGET_BOOTSTRAP_DIR}/usr/local/include """
        
        c_flags += Configuration.current.extra_c_flags

        swift_flags = "\nTARGET_SWIFTCFLAGS    = -I${SDKROOT}/lib/swift/" + Configuration.current.target.swift_sdk_name + " -Xcc -fblocks "
        if swift_triple is not None:
            swift_flags += "-target ${SWIFT_TARGET} "
        if Configuration.current.system_root is not None:
            swift_flags += "-sdk ${SYSROOT} "

        if Configuration.current.bootstrap_directory is not None:
            swift_flags += """  -I${BOOTSTRAP_DIR}/usr/include -I${BOOTSTRAP_DIR}/usr/local/include """
            swift_flags += """  -I${TARGET_BOOTSTRAP_DIR}/usr/include -I${TARGET_BOOTSTRAP_DIR}/usr/local/include """

        if Configuration.current.build_mode == Configuration.Debug:
            swift_flags += "-g -Onone "
        elif Configuration.current.build_mode == Configuration.Release:
            swift_flags += " " 

        swift_flags += Configuration.current.extra_swift_flags
        
        swift_flags += """
TARGET_SWIFTEXE_FLAGS = -I${SDKROOT}/lib/swift/""" + Configuration.current.target.swift_sdk_name + """  -L${SDKROOT}/lib/swift/""" + Configuration.current.target.swift_sdk_name + """ """
        if Configuration.current.build_mode == Configuration.Debug:
            swift_flags += "-g -Onone -enable-testing "
        elif Configuration.current.build_mode == Configuration.Release:
            swift_flags += " "
        swift_flags += Configuration.current.extra_swift_flags



        ld_flags = """
EXTRA_LD_FLAGS       = """ + Configuration.current.extra_ld_flags

        ld_flags += """
TARGET_LDFLAGS       = --target=${TARGET} ${EXTRA_LD_FLAGS} -L${SDKROOT}/lib/swift/""" + Configuration.current.target.swift_sdk_name + """ """
        if Configuration.current.system_root is not None:
            ld_flags += "--sysroot=${SYSROOT}"

        if Configuration.current.bootstrap_directory is not None:
            ld_flags += """ -L${TARGET_BOOTSTRAP_DIR}/usr/lib"""

        if Configuration.current.toolchain is not None:
            c_flags += " -B" + Configuration.current.toolchain.path_by_appending("bin").relative()
            ld_flags += " -B" + Configuration.current.toolchain.path_by_appending("bin").relative()

        c_flags += "\n"
        swift_flags += "\n"
        ld_flags += "\n"

        cxx_flags = """
TARGET_CXXFLAGS       = -std=gnu++11 -I${SYSROOT}/usr/include/c++/${BINUTILS_VERSION} -I${SYSROOT}/usr/include/${TARGET}/c++/${BINUTILS_VERSION}
"""

        ar_flags = """
AR_FLAGS              = rcs
"""

        flags = variables + verbose_flags + base_flags + c_flags + swift_flags + cxx_flags + ld_flags + ar_flags

        cp_command = """
rule Cp
    command = mkdir -p `dirname $out`; /bin/cp -r $in $out
    description = Cp $in
"""

        compilec_command = """
rule CompileC
    command = mkdir -p `dirname $out`; ${CLANG} ${TARGET_CFLAGS} $flags ${VERBOSE_FLAGS} -c $in -o $out 
    description = CompileC: $in

rule CompileCxx
    command = mkdir -p `dirname $out`; ${CLANGXX} ${TARGET_CFLAGS} ${TARGET_CXXFLAGS} $flags ${VERBOSE_FLAGS} -c $in -o $out 
    description = CompileCxx: $in
"""

        swiftc_command = """
rule CompileSwift
    command = mkdir -p `dirname $out`; mkdir -p ${MODULE_CACHE_PATH}; ${SWIFT} -frontend -c $module_sources ${TARGET_SWIFTCFLAGS} $flags -module-name $module_name -module-link-name $module_name -o $out -emit-module-path $out.~partial.swiftmodule -emit-module-doc-path $out.~partial.swiftdoc -emit-dependencies-path $out.d -emit-reference-dependencies-path $out.swiftdeps -module-cache-path ${MODULE_CACHE_PATH}
    description = CompileSwift: $in
    depfile = $out.d

rule MergeSwiftModule
    command = mkdir -p `dirname $out`; ${SWIFT} -frontend -emit-module $partials ${TARGET_SWIFTCFLAGS} $flags -module-cache-path ${MODULE_CACHE_PATH} -module-link-name $module_name -o $out
    description = Merge $out
"""

        assembler_command = """
rule Assemble
    command = mkdir -p `dirname $out`; ${CLANG} -x assembler-with-cpp -c $in -o $out ${TARGET_CFLAGS} $flags ${VERBOSE_FLAGS} 
    description = Assemble: $in
"""

        link_command = """
rule Link
    command = mkdir -p `dirname $out`; ${CLANG} ${TARGET_LDFLAGS} $flags ${VERBOSE_FLAGS} $start $in $end -o $out""" 
        if Configuration.current.verbose:
            link_command += "-Xlinker --verbose"
        link_command += """
    description = Link: $out

rule Archive
    command = mkdir -p `dirname $out`; ${AR} ${AR_FLAGS} $flags $out $in
    description = Archive: $out
"""
        
        swift_build_command = """
rule SwiftExecutable
    command = mkdir -p `dirname $out`; ${SWIFTC} ${TARGET_SWIFTEXE_FLAGS} ${EXTRA_LD_FLAGS} $flags $in -o $out
    description = SwiftExecutable: $out
"""

        commands = cp_command + compilec_command + swiftc_command + assembler_command + link_command + swift_build_command

        script = flags + commands

        for product in self.products:
            script += product.generate()

        script += """

rule RunReconfigure
    command = ./configure --reconfigure
    description = Reconfiguring build script.

build ${BUILD_DIR}/.reconfigure: RunReconfigure

build reconfigure: phony | ${BUILD_DIR}/.reconfigure

"""
        script += self.extra
        script += "\n\n"

        return script

    def generate_workspaces(self):

        build_project_command = """
rule BuildProject
    command = pushd $project; ninja; popd
"""
        script = build_project_command

        for workspace in self.workspaces:
            script += workspace.generate()

        script += "\n\n"

        return script

    def generate(self):
        script = None
        if self.workspaces is None:
            script = self.generate_products()
            script_file = open(Configuration.current.build_script_path.absolute(), 'w')
            script_file.write(script)
            script_file.close()
        else:
            for workspace in self.workspaces:
                workspace.configure()
            script = self.generate_workspaces()
            
        
