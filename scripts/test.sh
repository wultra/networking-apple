#!/bin/bash

set -e # stop script when error occures
set -u # stop when undefined variable is used
#set -x # print all execution (good for debugging)
set -o pipefail

SCRIPT_FOLDER=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
URL="https://raw.githubusercontent.com/wultra/wultra-infrastructure/refs/heads/mobile-release/mobile-utils/get-ios-sim.js"
XCODE_PROJECT="WultraPowerAuthNetworking.xcodeproj"
XCODE_SCHEME="WultraPowerAuthNetworkingTests"

CONFIG_JSON=""

# Parse parameters of this script
while [[ $# -gt 0 ]]
do
  case "$1" in
    -config)
      CONFIG_JSON="$2"
      shift
      shift
      ;;
    *)
      echo "Unknown parameter ${1}"
      exit 1
      ;;
  esac
done

# Resolve the newest available iOS Simulator destination through the shared Node helper.
DESTINATION=$(curl -fsSL "${URL}" | node - -p "${SCRIPT_FOLDER}/.." "${XCODE_PROJECT}" "${XCODE_SCHEME}")

echo "Destination resolved: ${DESTINATION}"

pushd "${SCRIPT_FOLDER}/.."

rm -rf "build" # clear build folder

# Write integration test config if provided
if [ -n "${CONFIG_JSON}" ]; then
  echo "Writing integration test config..."
  echo "${CONFIG_JSON}" > "WultraPowerAuthNetworkingTests/IntegrationTests/Config/config.json"
fi

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
