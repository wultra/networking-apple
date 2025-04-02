#!/bin/bash

set -e # stop sript when error occures
set -u # stop when undefined variable is used
#set -x # print all execution (good for debugging)

SCRIPT_FOLDER=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

IOS_VERSION=$(xcrun simctl list | grep "\-\- iOS" | tail -1 | tr -d - | tr -d " " | tr -d "iOS")
DESTINATION="platform=iOS Simulator,OS=${IOS_VERSION},name=iPhone 16"

pushd "${SCRIPT_FOLDER}"
sh cart-update.sh
popd

pushd "${SCRIPT_FOLDER}/.."

rm -rf "build" # clear build folder

xcrun xcodebuild \
	-derivedDataPath "build" \
    -project "WultraPowerAuthNetworking.xcodeproj" \
    -scheme "WultraPowerAuthNetworkingTests" \
    -destination "${DESTINATION}" \
    -parallel-testing-enabled NO \
    -configuration "Debug" \
    test

popd