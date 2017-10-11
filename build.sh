#!/usr/bin/env bash

set -e

rm -rf build
mkdir -p build/apk

: ${ANDROID_HOME:?"Need to set ANDROID_HOME"}

# Use zopfli compression if available
recompress() {
    if hash advzip 2>/dev/null; then
        advzip -4 -i 256 --recompress "$@"
    else
        echo "Use advcomp for better compression (http://www.advancemame.it/download) / (brew install advancecomp)"
    fi
}

set -x

echo "Creating keystore"
keytool -genkeypair -keyalg EC -keysize 256 -v -keystore build/keystore.jks -storepass android -dname 'C=' -alias android -keypass android

echo "Creating base apk"
cp app/AndroidManifest.xml build/apk/

echo "Creating unsigned archive"
zip -j -r build/app-unsigned.apk build/apk

recompress build/app-unsigned.apk

echo "Signing archive"
$ANDROID_HOME/build-tools/26.0.2/apksigner sign --v1-signing-enabled false --ks build/keystore.jks --out build/signed-release.apk --ks-pass pass:android --ks-key-alias android --min-sdk-version 24 build/app-unsigned.apk

set +x

echo
echo
echo
echo "#######################################"
echo "RESULTING APK SIZE: $(stat -f '%z' build/signed-release.apk)"

echo "Copying to project root dir"
cp build/signed-release.apk signed-release.apk
