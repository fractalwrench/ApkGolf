#!/usr/bin/env bash -ex

rm -rf build
mkdir -p build/apk

: ${ANDROID_HOME:?"Need to set ANDROID_HOME"}

echo "Creating base apk"
cp app/AndroidManifest.xml build/apk/
echo "Creating empty classes.dex"
touch build/apk/classes.dex

python3 zipcrush.py build/app-unsigned.apk build/apk/*

echo "Signing archive"
KEYSTORE_PASS=android $ANDROID_HOME/build-tools/26.0.2/apksigner sign --v1-signing-enabled false --ks app/keystore.jks --out build/signed-release.apk --ks-pass env:KEYSTORE_PASS --ks-key-alias android --min-sdk-version 24 build/app-unsigned.apk

set +x

echo
echo
echo
echo "#######################################"
echo "RESULTING APK SIZE: $(stat -f '%z' build/signed-release.apk)"

