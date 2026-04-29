#!/bin/bash

set -e # stop sript when error occures
set -u # stop when undefined variable is used
#set -x # print all execution (good for debugging)
set -o pipefail

SCRIPT_FOLDER=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
XCODE_PROJECT="WultraPowerAuthNetworking.xcodeproj"
XCODE_SCHEME="WultraPowerAuthNetworkingTests"
BUILD_FOLDER="build"

# Function that resolved the best available simulator for the test run
function getSimulatorDestination {
  local scriptUrl="https://raw.githubusercontent.com/wultra/wultra-infrastructure/refs/heads/mobile-release/mobile-utils/get-ios-sim.js"
  curl -fsSL "${scriptUrl}" | node - -p "${SCRIPT_FOLDER}/.." "${XCODE_PROJECT}" "${XCODE_SCHEME}"
}

# Resolve the newest available iOS Simulator destination through the shared Node helper.
echo "Resolving the best simulator for the ${XCODE_SCHEME}..."
DESTINATION=$(getSimulatorDestination)

echo "Simulator to use: ${DESTINATION}"

pushd "${SCRIPT_FOLDER}/.."

rm -rf "${BUILD_FOLDER}" # clear build folder

echo "Resolving SPM dependencies..."

xcrun xcodebuild \
  -project "${XCODE_PROJECT}" \
  -resolvePackageDependencies \
  -onlyUsePackageVersionsFromResolvedFile

  echo "Starting the test"

xcrun xcodebuild \
  -derivedDataPath "${BUILD_FOLDER}" \
  -project "${XCODE_PROJECT}" \
  -scheme "${XCODE_SCHEME}" \
  -destination "${DESTINATION}" \
  -parallel-testing-enabled NO \
  -configuration "Debug" \
  -onlyUsePackageVersionsFromResolvedFile \
  test

popd
