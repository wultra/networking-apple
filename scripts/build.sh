#!/bin/bash

set -e # stop sript when error occures
set -u # stop when undefined variable is used
#set -x # print all execution (good for debugging)

SCRIPT_FOLDER=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
"$SCRIPT_FOLDER/cart-update.sh"
pushd "${SCRIPT_FOLDER}/.."

echo "---------------------------------------------------"
echo "iOS"
echo "---------------------------------------------------"
xcrun xcodebuild build \
    -project "WultraPowerAuthNetworking.xcodeproj" \
    -scheme "WultraPowerAuthNetworking" \
    -configuration "Release" \
    -destination "generic/platform=iOS" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO
echo "---------------------------------------------------"
echo "iOS Simulator"
echo "---------------------------------------------------"
xcrun xcodebuild build \
    -project "WultraPowerAuthNetworking.xcodeproj" \
    -scheme "WultraPowerAuthNetworking" \
    -configuration "Release" \
    -destination "generic/platform=iOS Simulator" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO
echo "---------------------------------------------------"
echo "mac Catalyst"
echo "---------------------------------------------------"
xcrun xcodebuild build \
    -project "WultraPowerAuthNetworking.xcodeproj" \
    -scheme "WultraPowerAuthNetworking" \
    -configuration "Release" \
    -destination "platform=macOS,variant=Mac Catalyst" \
    SUPPORTS_MACCATALYST=YES \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO
echo "---------------------------------------------------"
echo "tvOS"
echo "---------------------------------------------------"
xcrun xcodebuild build \
    -project "WultraPowerAuthNetworking.xcodeproj" \
    -scheme "WultraPowerAuthNetworking" \
    -configuration "Release" \
    -destination "generic/platform=tvOS" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO
echo "---------------------------------------------------"
echo "tvOS Simulator"
echo "---------------------------------------------------"
xcrun xcodebuild build \
    -project "WultraPowerAuthNetworking.xcodeproj" \
    -scheme "WultraPowerAuthNetworking" \
    -configuration "Release" \
    -destination "generic/platform=tvOS Simulator" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO
popd