#!/bin/bash

set -e # stop sript when error occures
set -u # stop when undefined variable is used
#set -x # print all execution (good for debugging)
set -o pipefail

SCRIPT_FOLDER=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
URL="https://raw.githubusercontent.com/wultra/wultra-infrastructure/refs/heads/mobile-release/mobile-utils/get-ios-sim.js"
XCODE_PROJECT="WultraPowerAuthNetworking.xcodeproj"
XCODE_SCHEME="WultraPowerAuthNetworkingTests"

# Resolve the newest available iOS Simulator destination through the shared Node helper.
DESTINATION=$(curl -fsSL "${URL}" | node - -p "${SCRIPT_FOLDER}/.." "${XCODE_PROJECT}" "${XCODE_SCHEME}")

echo "Destination resolved: ${DESTINATION}"

pushd "${SCRIPT_FOLDER}/.."

rm -rf "build" # clear build folder

xcrun xcodebuild \
  -project "${XCODE_PROJECT}" \
  -resolvePackageDependencies \
  -onlyUsePackageVersionsFromResolvedFile

xcrun xcodebuild \
  -derivedDataPath "build" \
  -project "${XCODE_PROJECT}" \
  -scheme "${XCODE_SCHEME}" \
  -destination "${DESTINATION}" \
  -parallel-testing-enabled NO \
  -configuration "Debug" \
  -onlyUsePackageVersionsFromResolvedFile \
  test

popd
