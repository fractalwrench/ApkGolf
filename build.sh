#!/usr/bin/env bash

rm -rf build
mkdir -p build/apk

set -x

# Use zopfli compression if available
recompress() {
    if hash advzip 2>/dev/null; then
        advzip -4 -i 256 --recompress "$@"
    else
        echo "Use advcomp for better compression (http://www.advancemame.it/download) / (brew install advancecomp)"
    fi
}

#TODO ensure that ANDROID_HOME is set

echo "Creating base apk"
cp app/AndroidManifest.xml build/apk/
echo "Creating empty classes.dex"
touch build/apk/classes.dex

echo "Creating unsigned archive"
zip -j -r build/app-unsigned.apk build/apk

recompress build/app-unsigned.apk

echo "Signing archive"
KEYSTORE_PASS=android $ANDROID_HOME/build-tools/26.0.2/apksigner sign --v1-signing-enabled false --ks app/keystore.jks --out build/signed-release.apk --ks-pass env:KEYSTORE_PASS --ks-key-alias android --min-sdk-version 24 build/app-unsigned.apk

set +x

echo
echo
echo
echo "#######################################"
echo "RESULTING APK SIZE: $(stat -f '%z' build/signed-release.apk)"

