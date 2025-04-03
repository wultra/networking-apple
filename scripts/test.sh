#!/bin/bash

set -e # stop sript when error occures
set -u # stop when undefined variable is used
#set -x # print all execution (good for debugging)

SCRIPT_FOLDER=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# find latest iOS SDK available
IOS_VERSION=$(xcrun simctl list | grep "\-\- iOS" | tail -1 | tr -d - | tr -d " " | tr -d "iOS")
# find the first simulator for this sdk
SIMULATOR=$(xcrun simctl list | grep "\-\- iOS ${IOS_VERSION} \-\-" -A 1 | tail -1 | sed -E 's/^[[:space:]]+//; s/\(.*//; s/[[:space:]]+$//')
DESTINATION="platform=iOS Simulator,OS=${IOS_VERSION},name=${SIMULATOR}"

echo "Destination resolved: ${DESTINATION}"

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