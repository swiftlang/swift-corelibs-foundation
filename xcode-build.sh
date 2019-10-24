#!/bin/bash

DERIVED_DATA=xcode-test-build

CLEAN=0
CONFIG=Debug
TEST=0
TESTCASE=""

for i in "$@"
do
    case $i in
        -h)
            echo "usage: $0 [--clean] [--debug|--release] [--test]"
            exit 0
            ;;

        --clean)
            CLEAN=1
            ;;

        --debug)
            CONFIG=Debug
            ;;

        --release)
            CONFIG=Release
            ;;

        --test)
            TEST=1
;;
        *)
            TESTCASE="$i"
            break
            ;;
    esac
done

if [ $CLEAN = 1 ]; then
    echo Cleaning
    rm -rf "${DERIVED_DATA}"
fi

xcodebuild -derivedDataPath $DERIVED_DATA -workspace Foundation.xcworkspace -scheme SwiftFoundation -configuration $CONFIG build || exit 1
xcodebuild -derivedDataPath $DERIVED_DATA -workspace Foundation.xcworkspace -scheme SwiftFoundationNetworking -configuration $CONFIG build || exit 1

if [ $TEST = 1 ]; then
    echo Testing
    xcodebuild -derivedDataPath $DERIVED_DATA -workspace Foundation.xcworkspace -scheme TestFoundation -configuration $CONFIG build || exit 1
    $DERIVED_DATA/Build/Products/$CONFIG/TestFoundation.app/Contents/MacOS/TestFoundation $TESTCASE
fi

