#!/usr/bin/env bash

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

echo "Compiling certificate generation program"

success=0

gcc -o build/generate_cert generate_cert.c -lssl -lcrypto -ldl

if [ $? -eq 0 ]; then
    echo "Generating cert"
    cd build
    ./generate_cert
    if [ $? -eq 0 ]; then
	cd ..
        openssl x509 -in build/cert.pem -noout -text
        if [ $? -eq 0 ]; then
            openssl pkcs8 -topk8 -in build/key.pem -out build/key.pk8 -outform DER -nocrypt
            if [ $? -eq 0 ]; then
                echo "Success"
                success=1
            fi
        fi
    else
	cd ..
    fi
fi

if [ $success -eq 0 ]; then
    echo "Failed to generate cert. Using pre-generated cert."
    rm build/cert.pem
    rm build/key.pk8
    cp cert.pem build/
    cp key.pk8 build/
fi

set -e

echo "Creating base apk"
cp app/AndroidManifest.xml build/apk/

echo "Creating unsigned archive"
zip -j -r build/app-unsigned.apk build/apk

recompress build/app-unsigned.apk

echo "Signing archive"
$ANDROID_HOME/build-tools/26.0.2/apksigner sign --v1-signing-enabled false --key build/key.pk8 --cert build/cert.pem --in build/app-unsigned.apk --out build/signed-release.apk --min-sdk-version 24

set +x

echo
echo
echo
echo "#######################################"
echo "RESULTING APK SIZE: $(stat -f '%z' build/signed-release.apk)"

echo "Copying to project root dir"
cp build/signed-release.apk signed-release.apk
