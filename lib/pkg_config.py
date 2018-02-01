from __future__ import print_function

import shlex
import subprocess
import sys

from .config import Configuration


class PkgConfig(object):
    class Error(Exception):
        """Raised when information could not be obtained from pkg-config."""

    def __init__(self, package_name):
        """Query pkg-config for information about a package.

        :type package_name: str
        :param package_name: The name of the package to query.
        :raises PkgConfig.Error: When a call to pkg-config fails.
        """
        self.package_name = package_name
        self._cflags = self._call("--cflags")
        self._cflags_only_I = self._call("--cflags-only-I")
        self._cflags_only_other = self._call("--cflags-only-other")
        self._libs = self._call("--libs")
        self._libs_only_l = self._call("--libs-only-l")
        self._libs_only_L = self._call("--libs-only-L")
        self._libs_only_other = self._call("--libs-only-other")

    def _call(self, *pkg_config_args):
        try:
            cmd = [Configuration.current.pkg_config] + list(pkg_config_args) + [self.package_name]
            print("Executing command '{}'".format(cmd), file=sys.stderr)
            return shlex.split(subprocess.check_output(cmd))
        except subprocess.CalledProcessError as e:
            raise self.Error("pkg-config exited with error code {}".format(e.returncode))

    @property
    def swiftc_flags(self):
        """Flags for this package in a format suitable for passing to `swiftc`.

        :rtype: list[str]
        """
        return (
                ["-Xcc {}".format(s) for s in self._cflags_only_other]
                + ["-Xlinker {}".format(s) for s in self._libs_only_other]
                + self._cflags_only_I
                + self._libs_only_L
                + self._libs_only_l)

    @property
    def cflags(self):
        """CFLAGS for this package.

        :rtype: list[str]
        """
        return self._cflags

    @property
    def ldflags(self):
        """LDFLAGS for this package.

        :rtype: list[str]
        """
        return self._libs
