#!/bin/sh
#===----------------------------------------------------------------------===//
#
# This source file is part of the Swift.org open source project
#
# Copyright (c) 2020 Apple Inc. and the Swift project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
#
# See http://swift.org/LICENSE.txt for license information
# See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
#
#===----------------------------------------------------------------------===//

set -e
#set -xv

# This only needs to run during installation, but that includes "installapi".
[ "$ACTION" = "installapi" -o "$ACTION" = "install" ] || exit 0

[ "$SKIP_INSTALL" != "YES" ] || exit 0
[ "$SWIFT_INSTALL_MODULES" = "YES" ] || exit 0

srcmodule="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.swiftmodule"
dstpath="${INSTALL_ROOT}/${INSTALL_PATH}/"

if [ ! -d "$srcmodule" ]; then
    echo "Cannot find Swift module at $srcmodule" >&2
    exit 1
fi

mkdir -p "$dstpath"
cp -r "$srcmodule" "$dstpath"
