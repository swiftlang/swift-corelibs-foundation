# This source file is part of the Swift.org open source project
#
# Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
#
# See http://swift.org/LICENSE.txt for license information
# See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
#

from subprocess import call
from .config import Configuration
from .path import Path
import os

class Workspace:
    projects = []
    def __init__(self, projects):
        self.projects = projects

    def configure(self):
        if Configuration.current.system_root is None:
            Configuration.current.system_root = Path("./sysroots/" + Configuration.current.target.triple)
        if Configuration.current.toolchain is None:
            Configuration.current.toolchain = Path("./toolchains/" + Configuration.current.target.triple)
        if Configuration.current.bootstrap_directory is None:
            Configuration.current.bootstrap_directory = Path("./bootstrap")
        for project in self.projects:
            working_dir = Configuration.current.source_root.path_by_appending(project).absolute()
            cmd = [Configuration.current.command[0], "--target", Configuration.current.target.triple]
            if Configuration.current.system_root is not None:
                cmd.append("--sysroot=" + Configuration.current.system_root.relative(working_dir))
            if Configuration.current.toolchain is not None:
                cmd.append("--toolchain=" + Configuration.current.toolchain.relative(working_dir))
            if Configuration.current.bootstrap_directory is not None:
                cmd.append("--bootstrap=" + Configuration.current.bootstrap_directory.relative(working_dir))

            if Configuration.current.verbose:
                cmd.append("--verbose")
                print("cd " + working_dir)
                print("    " + " ".join(cmd))
            status = call(cmd, cwd=working_dir)
            if status != 0:
                exit(status) # pass the exit value along if one of the sub-configurations fails

    def generate(self):
        generated = ""
        for project in self.projects:
            generated += """
build """ + os.path.basename(project) + """: BuildProject 
    project = """ + project + """

"""
        generated += """
build all: phony | """ + " ".join(reversed(self.projects)) + """

default all
"""

        return generated