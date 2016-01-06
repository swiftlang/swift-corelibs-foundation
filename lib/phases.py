# This source file is part of the Swift.org open source project
#
# Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
#
# See http://swift.org/LICENSE.txt for license information
# See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
#

from .config import Configuration
from .target import TargetConditional
from .path import Path
import os

class BuildAction:
    input = None
    output = None
    _product = None
    dependencies = None
    skipRule = False

    def __init__(self, input=None, output=None):
        self.input = input
        self.output = output
    
    @property
    def product(self):
        return self._product

    def set_product(self, product):
        self._product = product

    def generate_dependencies(self, extra = None):
        if self.dependencies is not None and len(self.dependencies) > 0:
            rule = " |"
            for dep in self.dependencies:
                rule += " " + dep.name
            if extra is not None:
                rule += " " + extra
            return rule
        else:
            if extra is not None:
                return " | " + extra
            return ""

    def add_dependency(self, phase):
        if self.dependencies is None:
            self.dependencies = [phase]
        else:
            self.dependencies.append(phase)


class Cp(BuildAction):
    def __init__(self, source, destination):
        BuildAction.__init__(self, input=source, output=destination)

    def generate(self):
        return """
build """ + self.output.relative() + """: Cp """ + self.input.relative() + self.generate_dependencies() + """
"""

class CompileSource(BuildAction):
    path = None
    def __init__(self, path, product):
        BuildAction.__init__(self, input=path, output=Configuration.current.build_directory.path_by_appending(product.name).path_by_appending(path.relative() + ".o"))
        self.path = path

    @staticmethod
    def compile(source, phase):
        ext = source.extension()
        if ext == ".c" or ext == ".m":
            return CompileC(source, phase.product)
        elif ext == ".mm" or ext == ".cpp" or ext == ".CC":
            return CompileCxx(source, phase.product)
        elif ext == ".S" or ext == ".s":
            return Assemble(source, phase.product)
        elif ext == ".swift":
            return CompileSwift(source, phase.product, phase)
        else:
            return None


class CompileC(CompileSource):
    def __init__(self, path, product):
        CompileSource.__init__(self, path, product)

    def generate(self):
        generated = """
build """ + self.output.relative() + """: CompileC """ + self.path.relative() + self.generate_dependencies() + """
    flags = """
        generated += " -I" + Configuration.current.build_directory.path_by_appending(self.product.name).relative()
        generated += " -I" + Configuration.current.build_directory.relative()
        generated += " -I" + Configuration.current.build_directory.path_by_appending(self.product.name).relative() + self.product.ROOT_HEADERS_FOLDER_PATH
        generated += " -I" + Configuration.current.build_directory.path_by_appending(self.product.name).relative() + self.product.PUBLIC_HEADERS_FOLDER_PATH
        generated += " -I" + Configuration.current.build_directory.path_by_appending(self.product.name).relative() + self.product.PRIVATE_HEADERS_FOLDER_PATH
        generated += " -I" + Configuration.current.build_directory.path_by_appending(self.product.name).relative() + self.product.PROJECT_HEADERS_FOLDER_PATH
        cflags = TargetConditional.value(self.product.CFLAGS)
        if cflags is not None:
            generated += " " + cflags
        prefix = TargetConditional.value(self.product.GCC_PREFIX_HEADER)
        if prefix is not None:
            generated += " -include " + prefix
        generated += "\n"
        if self.path.extension() == ".m" or "-x objective-c" in generated:
            self.product.needs_objc = True
        return generated


class CompileCxx(CompileSource):
    def __init__(self, path, product):
        CompileSource.__init__(self, path, product)

    def generate(self):
        generated = """
build """ + self.output.relative() + """: CompileCxx """ + self.path.relative() + self.generate_dependencies() + """
    flags = """
        generated += "-I" + Configuration.current.build_directory.path_by_appending(self.product.name).relative() + " -I" + Configuration.current.build_directory.relative()
        cflags = TargetConditional.value(self.product.CFLAGS)
        if cflags is not None:
            generated += " " + cflags
        cxxflags = TargetConditional.value(self.product.CXXFLAGS)
        if cxxflags is not None:
            generated += " " + cxxflags
        prefix = TargetConditional.value(self.product.GCC_PREFIX_HEADER)
        if prefix is not None:
            generated += " -include " + prefix
        generated += "\n"
        if self.path.extension() == ".mm" or "-x objective-c" in generated:
            self.product.needs_objc = True
        self.product.needs_stdcxx = True
        return generated


class Assemble(CompileSource):
    def __init__(self, path, product):
        CompileSource.__init__(self, path, product)

    def generate(self):
        generated = """
build """ + self.output.relative() + """: Assemble """ + self.path.relative() + self.generate_dependencies() + """
    flags = """
        asflags = TargetConditional.value(self.product.ASFLAGS)
        if asflags is not None:
            generated += " " + asflags
        return generated


class CompileSwift(CompileSource):
    phase = None
    def __init__(self, path, product, phase):
        CompileSource.__init__(self, path, product)
        self.phase = phase

    def generate(self):
        generated = """
build """ + self.output.relative() + """: CompileSwift """ + self.path.relative() + self.generate_dependencies() + """
    module_sources = """ + self.module_sources + """
    module_name = """ + self.product.name + """
    flags = """
        generated += " -I" + Configuration.current.build_directory.path_by_appending(self.product.name).relative()
        generated += " -I" + Configuration.current.build_directory.path_by_appending(self.product.name).relative() + self.product.ROOT_HEADERS_FOLDER_PATH
        generated += " -I" + Configuration.current.build_directory.relative()
        swiftflags = TargetConditional.value(self.product.SWIFTCFLAGS)
        if swiftflags is not None:
            generated += " " + swiftflags
        return generated

    @property
    def module_sources(self):
        sources = self.phase.module_sources(primary=self.path.absolute())
        return " ".join(sources)
    

class BuildPhase(BuildAction):
    previous = None
    name = None
    dependencies = None
    actions = None
    def __init__(self, name):
        BuildAction.__init__(self)
        self.dependencies = []
        self.actions = []
        self.name = name

    def generate(self):
        generated = ""
        for action in self.actions:
            action.dependencies = self.dependencies
            generated += action.generate() + "\n"

        rule = "build " + self.name + ": phony"

        if self.previous is not None or len(self.actions) > 0:
            rule += " |"
            if self.previous is not None:
                rule += " " + self.previous.name
            for action in self.actions:
                rule += " " + action.output.relative()
        rule += "\n"
        return generated + "\n" + rule

    @property
    def objects(self):
        return []


class CopyHeaders(BuildPhase):
    _public = []
    _private = []
    _project = []
    _module = None
    def __init__(self, public, private, project, module=None):
        BuildPhase.__init__(self, "CopyHeaders")
        if public is not None:
            self._public = public
        if private is not None:
            self._private = private
        if project is not None:
            self._project = project
        self._module = module

    @property
    def product(self):
        return self._product
    
    def set_product(self, product):
        BuildAction.set_product(self, product)
        self.actions = []

        module = Path.path(TargetConditional.value(self._module))
        if module is not None:
            action = Cp(module, self.product.public_module_path.path_by_appending("module.modulemap"))
            self.actions.append(action)
            action.set_product(product)

        for value in self._public:
            header = Path.path(TargetConditional.value(value))
            if header is None:
                continue
            action = Cp(header, self.product.public_headers_path.path_by_appending(header.basename()))
            self.actions.append(action)
            action.set_product(product)

        for value in self._private:
            header = Path.path(TargetConditional.value(value))
            if header is None:
                continue
            action = Cp(header, self.product.private_headers_path.path_by_appending(header.basename()))
            self.actions.append(action)
            action.set_product(product)

        for value in self._project:
            header = Path.path(TargetConditional.value(value))
            if header is None:
                continue
            action = Cp(header, self.product.project_headers_path.path_by_appending(header.basename()))
            self.actions.append(action)
            action.set_product(product)

class CopyResources(BuildPhase):
    _resources = []
    _resourcesDir = None
    
    def __init__(self, outputDir, resources):
        BuildPhase.__init__(self, "CopyResources")
        if resources is not None:
            self._resources = resources
            self._resourcesDir = outputDir

    @property
    def product(self):
        return self._product
    
    def set_product(self, product):
        BuildAction.set_product(self, product)
        self.actions = []

        for value in self._resources:
            resource = Path.path(TargetConditional.value(value))
            if resource is None:
                continue
        
            action = Cp(resource, Configuration.current.build_directory.path_by_appending(self._resourcesDir).path_by_appending(resource.basename()))
            self.actions.append(action)
            action.set_product(product)

class CompileSources(BuildPhase):
    _sources = []
    def __init__(self, sources):
        BuildPhase.__init__(self, "CompileSources")
        if sources is not None:
            self._sources = sources

    @property
    def product(self):
        return self._product
    
    def set_product(self, product):
        BuildAction.set_product(self, product)
        self.actions = []

        for value in self._sources:
            source = Path.path(TargetConditional.value(value))
            if source is None:
                continue
            action = CompileSource.compile(source, self)
            if action is None:
                print("Unable to compile source " + source.absolute())
                assert action is not None
            self.actions.append(action)
            action.set_product(product)

    @property
    def objects(self):
        objects = []
        for action in self.actions:
            objects.append(action.output.relative())
        return objects


class MergeSwiftModule:
    name = None
    def __init__(self, module):
        self.name = module\

    @property
    def output(self):
        return Path.path(self.name)


class CompileSwiftSources(BuildPhase):
    _sources = []
    _module = None
    def __init__(self, sources):
        BuildPhase.__init__(self, "CompileSwiftSources")
        if sources is not None:
            self._sources = sources

    @property
    def product(self):
        return self._product
    
    def set_product(self, product):
        BuildAction.set_product(self, product)
        self.actions = []

        for value in self._sources:
            source = Path.path(TargetConditional.value(value))
            if source is None:
                continue
            action = CompileSource.compile(source, self)
            if action is None:
                print("Unable to compile source " + source.absolute())
                assert action is not None
            self.actions.append(action)
            action.set_product(product)
        self._module = Configuration.current.build_directory.path_by_appending(self.product.name).path_by_appending(self.product.name + ".swiftmodule")
        product.add_dependency(MergeSwiftModule(self._module.relative()))

    def module_sources(self, primary):
        modules = []
        for value in self._sources:
            source = Path.path(TargetConditional.value(value))
            if source is None:
                continue
            if source.absolute() != primary:
                modules.append(source.relative())
            else:
                modules.append("-primary-file")
                modules.append(source.relative())
        return modules

    def generate(self):
        generated = BuildPhase.generate(self)
        generated += "\n\n"
        objects = ""
        partial_modules = ""
        partial_docs = ""
        for value in self._sources:
            path = Path.path(value)
            compiled = Configuration.current.build_directory.path_by_appending(self.product.name).path_by_appending(path.relative() + ".o")
            objects += compiled.relative() + " "
            partial_modules += compiled.relative() + ".~partial.swiftmodule "
            partial_docs += compiled.relative() + ".~partial.swiftdoc "

        generated += """
build """ + self._module.relative() + ": MergeSwiftModule " + objects + """
    partials = """ + partial_modules + """
    module_name = """ + self.product.name + """
    flags = -I""" + self.product.public_module_path.relative() + """ """ + TargetConditional.value(self.product.SWIFTCFLAGS) + """ -emit-module-doc-path """ + self._module.parent().path_by_appending(self.product.name).relative() + """.swiftdoc 
"""
        return generated

    @property
    def objects(self):
        objects = []
        for action in self.actions:
            objects.append(action.output.relative())
        return objects

# This builds a Swift executable using one invocation of swiftc (no partial compilation)
class SwiftExecutable(BuildPhase):
    executableName = None
    sources = []
    
    def __init__(self, executableName, sources):
        BuildAction.__init__(self, output=executableName)
        self.executableName = executableName
        self.sources = sources
    
    def generate(self):
        appName = Configuration.current.build_directory.relative() + """/""" + self.executableName + """/""" + self.executableName
        libDependencyName = self.product.product_name
        swiftSources = ""
        for value in self.sources:
            resource = Path.path(TargetConditional.value(value))
            if resource is None:
                continue
            swiftSources += " " + resource.relative()

        return """
build """ + appName + """: SwiftExecutable """ + swiftSources + self.generate_dependencies(libDependencyName) + """
    flags = -I""" + Configuration.current.build_directory.path_by_appending(self.product.name).relative() + self.product.ROOT_HEADERS_FOLDER_PATH + " -I" + Configuration.current.build_directory.path_by_appending(self.product.name).relative() + " -L" + Configuration.current.build_directory.path_by_appending(self.product.name).relative() + " " + TargetConditional.value(self.product.SWIFTCFLAGS) + """
build """ + self.executableName + """: phony | """ + appName + """
"""



