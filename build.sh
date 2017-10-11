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

echo "Creating base apk"
cp app/AndroidManifest.xml build/apk/

echo "Creating unsigned archive"
zip -j -r build/app-unsigned.apk build/apk

recompress build/app-unsigned.apk

echo "Signing archive"
$ANDROID_HOME/build-tools/26.0.2/apksigner sign --v1-signing-enabled false --key key.pk8 --cert key.x509.pem --in build/app-unsigned.apk --out build/signed-release.apk --min-sdk-version 24

set +x

echo
echo
echo
echo "#######################################"
echo "RESULTING APK SIZE: $(stat -f '%z' build/signed-release.apk)"

echo "Copying to project root dir"
cp build/signed-release.apk signed-release.apk
