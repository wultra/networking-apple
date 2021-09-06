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
    OBJROOT=build/iOS \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES

xcrun xcodebuild archive \
    -project "WultraPowerAuthNetworking.xcodeproj" \
    -scheme "WultraPowerAuthNetworking" \
    -configuration "Release" \
    -sdk iphonesimulator \
     OBJROOT=build/simulator \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES

xcrun xcodebuild \
    -create-xcframework \
    -framework "build/iOS/UninstalledProducts/iphoneos/WultraPowerAuthNetworking.framework" \
    -framework "build/simulator/UninstalledProducts/iphonesimulator/WultraPowerAuthNetworking.framework" \
    -output "build/WultraPowerAuthNetworking.xcframework"

popd