# This source file is part of the Swift.org open source project
#
# Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
#
# See http://swift.org/LICENSE.txt for license information
# See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
#

from .config import Configuration
from .phases import CompileC
from .phases import CompileCxx
from .phases import Assemble
from .phases import BuildAction
from .phases import MergeSwiftModule
from .target import OSType
from .path import Path

import os

class Product(BuildAction):
    name = None
    product_name = None
    phases = []
    installed_headers = []
    CFLAGS = None
    CXXFLAGS = None
    LDFLAGS = None
    ASFLAGS = None
    SWIFTCFLAGS = ""
    needs_stdcxx = False
    needs_objc = False
    GCC_PREFIX_HEADER = None
    PUBLIC_HEADERS_FOLDER_PATH = os.path.join("usr", "include")
    PUBLIC_MODULE_FOLDER_PATH = os.path.join("usr", "include")
    PRIVATE_HEADERS_FOLDER_PATH = os.path.join("usr", "local", "include")

    def __init__(self, name):
        self.name = name

    def generate(self):
        generated = "\n\n"
        for phase in self.phases:
            generated += phase.generate()
        return generated

    def add_phase(self, phase):
        phase.set_product(self)
        if len(self.phases) > 0:
            phase.previous = self.phases[-1]
        self.phases.append(phase)

    @property
    def product(self):
        return Configuration.current.build_directory.path_by_appending(self.name).path_by_appending(self.product_name)

    @property
    def public_module_path(self):
        return Path.path(Configuration.current.build_directory.path_by_appending(self.name).absolute() + "/" + self.PUBLIC_MODULE_FOLDER_PATH)

    @property
    def public_headers_path(self):
        return Path.path(Configuration.current.build_directory.path_by_appending(self.name).absolute() + "/" + self.PUBLIC_HEADERS_FOLDER_PATH)

    @property
    def private_headers_path(self):
        return Path.path(Configuration.current.build_directory.path_by_appending(self.name).absolute() + "/" + self.PRIVATE_HEADERS_FOLDER_PATH)

    @property
    def project_headers_path(self):
        return Path.path(Configuration.current.build_directory.path_by_appending(self.name).absolute() + "/" + self.PROJECT_HEADERS_FOLDER_PATH)

class Library(Product):
    runtime_object = ''
    rule = None
    def __init__(self, name):
        Product.__init__(self, name)

    def generate(self, flags, objects = []):
        generated = ""
        if len(objects) == 0:
            generated = Product.generate(self)
            for phase in self.phases:
                objects += phase.objects

        product_flags = " ".join(flags)
        if self.LDFLAGS is not None:
            product_flags += " " + self.LDFLAGS
        if self.needs_stdcxx:
            product_flags += " -lstdc++"

        generated += """
build """ + self.product.relative() + """: """ + self.rule + """ """ + self.runtime_object + """ """ + " ".join(objects) + """ """ + self.generate_dependencies() + """
    flags = """ + product_flags
        if self.needs_objc:
            generated += """
    start = ${TARGET_BOOTSTRAP_DIR}/usr/lib/objc-begin.o 
    end = ${TARGET_BOOTSTRAP_DIR}/usr/lib/objc-end.o
"""

        generated += """

build """ + self.product_name + """: phony | """ + self.product.relative() + """

default """ + self.product_name + """

"""

        return objects, generated


class DynamicLibrary(Library):
    def __init__(self, name, uses_swift_runtime_object = True):
        Library.__init__(self, name)
        self.name = name
        self.uses_swift_runtime_object = uses_swift_runtime_object

    def generate(self, objects = []):
        self.rule = "Link"
        self.product_name = Configuration.current.target.dynamic_library_prefix + self.name + Configuration.current.target.dynamic_library_suffix
        if (Configuration.current.target.sdk == OSType.Linux or Configuration.current.target.sdk == OSType.FreeBSD) and self.uses_swift_runtime_object:
            self.runtime_object = '${SDKROOT}/lib/swift/${OS}/${ARCH}/swiftrt.o'
            return Library.generate(self, ["-shared", "-Wl,-soname," + self.product_name, "-Wl,--no-undefined"], objects)
        else:
            return Library.generate(self, ["-shared"], objects)


class Framework(Product):
    def __init__(self, name):
        Product.__init__(self, name)
        self.product_name = name + ".framework"

    @property
    def public_module_path(self):
        return Configuration.current.build_directory.path_by_appending(self.name).path_by_appending(self.product_name).path_by_appending("Modules")

    @property
    def public_headers_path(self):
        return Configuration.current.build_directory.path_by_appending(self.name).path_by_appending(self.product_name).path_by_appending("Headers")

    @property
    def private_headers_path(self):
        return Configuration.current.build_directory.path_by_appending(self.name).path_by_appending(self.product_name).path_by_appending("PrivateHeaders")

    def generate(self):
        generated = Product.generate(self)
        objects = []
        for phase in self.phases:
            objects += phase.objects
        product_flags = "-shared -Wl,-soname," + Configuration.current.target.dynamic_library_prefix + self.name + Configuration.current.target.dynamic_library_suffix + " -Wl,--no-undefined"
        if self.LDFLAGS is not None:
            product_flags += " " + self.LDFLAGS
        if self.needs_stdcxx:
            product_flags += " -lstdc++"

        generated += """

build """ + self.product.path_by_appending(self.name).relative() + """: Link """ + " ".join(objects) + self.generate_dependencies() + """
    flags = """ + product_flags
        if self.needs_objc:
            generated += """
    start = ${TARGET_BOOTSTRAP_DIR}/usr/lib/objc-begin.o 
    end = ${TARGET_BOOTSTRAP_DIR}/usr/lib/objc-end.o
"""

        generated += """
build """ + self.product_name + """: phony | """ + self.product.relative() + """

default """ + self.product_name + """

build ${TARGET_BOOTSTRAP_DIR}/usr/lib/""" + Configuration.current.target.dynamic_library_prefix + self.name + Configuration.current.target.dynamic_library_suffix + """: Cp """ + self.product.path_by_appending(self.name).relative() + """
"""

        return generated

class StaticLibrary(Library):
    def __init__(self, name):
        Library.__init__(self, name)
        self.name = name

    def generate(self, objects = []):
        self.rule = "Archive"
        self.product_name = Configuration.current.target.static_library_prefix + self.name + Configuration.current.target.static_library_suffix
        self.runtime_object = ''
        return Library.generate(self, [], objects)

class StaticAndDynamicLibrary(StaticLibrary, DynamicLibrary):
    def __init__(self, name):
        StaticLibrary.__init__(self, name)
        DynamicLibrary.__init__(self, name)

    def generate(self):
        objects, generatedForDynamic = DynamicLibrary.generate(self)
        _, generatedForStatic = StaticLibrary.generate(self, objects)
        return generatedForDynamic + generatedForStatic

class Executable(Product):
    def __init__(self, name):
        Product.__init__(self, name)
        self.product_name = name + Configuration.current.target.executable_suffix

    def generate(self):
        generated = Product.generate(self)

        return generated

class Application(Product):
    executable = None
    def __init__(self, name):
        Product.__init__(self, name)
        self.product_name = name + ".app"

    def generate(self):
        generated = Product.generate(self)
        objects = []
        for phase in self.phases:
            objects += phase.objects
        product_flags = ""

        if self.LDFLAGS is not None:
            product_flags += " " + self.LDFLAGS
        if self.needs_stdcxx:
            product_flags += " -lstdc++"


        generated += """
build """ + self.product.path_by_appending(self.name).relative() + ": Link " + " ".join(objects) + self.generate_dependencies() + """
   flags = """ + product_flags
        if self.needs_objc:
            generated += """
    start = ${TARGET_BOOTSTRAP_DIR}/usr/lib/objc-begin.o 
    end = ${TARGET_BOOTSTRAP_DIR}/usr/lib/objc-end.o
"""

        return generated

