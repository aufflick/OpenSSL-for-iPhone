#!/bin/sh

FWNAME=openssl

if [ ! -d lib ]; then
    echo "Please run build-libssl.sh first!"
    exit 1
fi

if [ -d $FWNAME.framework ]; then
    echo "Removing previous $FWNAME.framework copy"
    rm -rf $FWNAME.framework
fi

echo "Creating $FWNAME.framework"
mkdir -p $FWNAME.framework/Headers
DIR="$(cd "$(dirname "$0")" && pwd)"

if [ "$1" == "dynamic" ]; then
    LIBTOOL_FLAGS="-dynamic -undefined dynamic_lookup -ios_version_min 8.0"
    ARCHS="$(lipo -info lib/libcrypto.a)"
    ARCHS="${ARCHS#* are: }"
    for ARCH in $ARCHS; do
        ld -arch_multiple -arch "$ARCH" $LIBTOOL_FLAGS \
            -dylib -all_load -force_cpusubtype_ALL -no_arch_warnings \
            -dylib_install_name openssl.framework/openssl \
            lib/libcrypto.a lib/libssl.a \
            -o openssl.framework/openssl.libtool."$ARCH" \
            -final_output openssl.framework/openssl
    done
    lipo -create -output openssl.framework/openssl openssl.framework/openssl.libtool.*
    rm openssl.framework/openssl.libtool.*
    cp $DIR/"OpenSSL-for-iOS/dynamic-framework-Info.plist" $FWNAME.framework/Info.plist
else
    libtool -no_warning_for_no_symbols -static -o $FWNAME.framework/$FWNAME lib/libcrypto.a lib/libssl.a
    cp $DIR/"OpenSSL-for-iOS/OpenSSL-for-iOS-Info.plist" $FWNAME.framework/Info.plist
fi

cp -r include/$FWNAME/* $FWNAME.framework/Headers/


echo "Created $FWNAME.framework"

check_bitcode=`otool -arch arm64 -l $FWNAME.framework/$FWNAME | grep __bitcode`
if [ -z "$check_bitcode" ]
then
  echo "INFO: $FWNAME.framework doesn't contain Bitcode"
else
  echo "INFO: $FWNAME.framework contains Bitcode"
fi
