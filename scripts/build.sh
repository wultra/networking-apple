#!/bin/bash

set -e # stop sript when error occures
set -u # stop when undefined variable is used
#set -x # print all execution (good for debugging)

SCRIPT_FOLDER=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

pushd "${SCRIPT_FOLDER}"
sh cart-update.sh
popd

pushd "${SCRIPT_FOLDER}/.."

xcrun xcodebuild archive \
    -project "WultraPowerAuthNetworking.xcodeproj" \
    -scheme "WultraPowerAuthNetworking" \
    -configuration "Release" \
    -sdk iphoneos \
    -archivePath "build/ios" \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO

xcrun xcodebuild archive \
    -project "WultraPowerAuthNetworking.xcodeproj" \
    -scheme "WultraPowerAuthNetworking" \
    -configuration "Release" \
    -sdk iphonesimulator \
    -archivePath "build/simulator" \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO

xcrun xcodebuild \
    -create-xcframework \
    -framework "build/ios.xcarchive/Products/Library/Frameworks/WultraPowerAuthNetworking.framework" \
    -framework "build/simulator.xcarchive/Products/Library/Frameworks/WultraPowerAuthNetworking.framework" \
    -output "build/WultraPowerAuthNetworking.xcframework"

popd