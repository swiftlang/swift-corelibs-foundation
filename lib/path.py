# This source file is part of the Swift.org open source project
#
# Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
#
# See http://swift.org/LICENSE.txt for license information
# See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
#

import os

class Path:
	_path = None
	def __init__(self, path):
		if isinstance(path, Path):
			self._path = path.absolute()
		elif os.path.isabs(path):
			self._path = os.path.abspath(path)
		else:
			self._path = path

	def relative(self, base=os.getcwd()):
		return os.path.relpath(self._path, base)

	def absolute(self):
		return self._path

	@staticmethod
	def path(path):
		if path is None:
			return None
		else:
			return Path(path)

	def path_by_appending(self, comps):
		return Path.path(os.path.join(self._path, comps))

	def basename(self):
		return os.path.basename(self._path)

	def extension(self):
		name, ext = os.path.splitext(self._path)
		return ext

	def parent(self):
		path, _ = os.path.split(self._path)
		return Path(path)