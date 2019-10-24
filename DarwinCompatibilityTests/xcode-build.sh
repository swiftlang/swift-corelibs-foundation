#!/bin/bash

DERIVED_DATA=dct-xcode-test-build
if [ "$1" == "--clean" ]; then
    rm -rf "${DERIVED_DATA}"
    shift
fi

if [ "$1" != "" ]; then
    xcodebuild -derivedDataPath $DERIVED_DATA -project DarwinCompatibilityTests.xcodeproj -scheme xdgTestHelper  "-only-testing:DarwinCompatibilityTests/$1" test
else
    xcodebuild -derivedDataPath $DERIVED_DATA -project DarwinCompatibilityTests.xcodeproj -scheme xdgTestHelper  `sed 's/^/-skip-testing:DarwinCompatibilityTests\//g' DarwinCompatibilityTests/TestsToSkip.txt` test
fi
