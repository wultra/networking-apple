#!/bin/bash

set -e # stop sript when error occures
set -u # stop when undefined variable is used
#set -x # print all execution (good for debugging)

SCRIPT_FOLDER=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
pushd "${SCRIPT_FOLDER}/.."

echo "---------------------------------------------------"
echo "Resolving Swift package dependencies"
echo "---------------------------------------------------"
xcrun xcodebuild -resolvePackageDependencies \
    -project "WultraPowerAuthNetworking.xcodeproj"

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
    -onlyUsePackageVersionsFromResolvedFile \
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
    -onlyUsePackageVersionsFromResolvedFile \
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
    -onlyUsePackageVersionsFromResolvedFile \
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
    -onlyUsePackageVersionsFromResolvedFile \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO
popd
