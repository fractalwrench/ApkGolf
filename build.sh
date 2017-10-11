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

echo "Creating base AndroidManifest.xml"
$ANDROID_HOME/build-tools/26.0.2/aapt p -M app/AndroidManifest.xml -S app/res -I $ANDROID_HOME/platforms/android-26/android.jar -f -F build/base.apk
unzip build/base.apk -d build/apk

# Don't use the original manifest with all the generated junk, use the compiled xml from layout instead
rm build/apk/AndroidManifest.xml
rm build/apk/resources.arsc
mv build/apk/res/layout/manifest.xml build/apk/AndroidManifest.xml
rm -rf build/apk/res

echo "Creating empty classes.dex"
touch build/apk/classes.dex

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

