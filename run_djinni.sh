#!/usr/bin/env bash


# Configure

IDL_FILE="idl/ImageProcessor.djinni"
CPP_NAMESPACE="dicekeys"
OBJC_PREFIX="DK"
JAVA_PACKAGE="com.dicekeys.dicekeys"

# Get base dir
BASE_DIR=$(cd "`dirname $0`" && pwd)

# Get java directory from package name
JAVA_DIR=$(echo $JAVA_PACKAGE | tr . /)

GENERATED_OUTPUT_FOLDER="$BASE_DIR/generated_src"

# Output directories for generated src
CPP_OUTPUT_FOLDER="$GENERATED_OUTPUT_FOLDER/cpp"
JAVA_OUTPUT_FOLDER="$GENERATED_OUTPUT_FOLDER/java/$JAVA_DIR"
JNI_OUTPUT_FOLDER="$GENERATED_OUTPUT_FOLDER/jni"
OBJC_OUTPUT_FOLDER="$GENERATED_OUTPUT_FOLDER/objc"

# Briding header
BRIDGING_HEADER="DiceKeys-Bridging-Header"

# Bootstrap

# Make dir, ignore if exists
mkdir -p $GENERATED_OUTPUT_FOLDER

# Purge output dirs
rm -rf $CPP_OUTPUT_FOLDER
rm -rf $JAVA_OUTPUT_FOLDER
rm -rf $JNI_OUTPUT_FOLDER
rm -rf $OBJC_OUTPUT_FOLDER


# Run Djinni

$BASE_DIR/deps/djinni/src/run \
    --cpp-out $CPP_OUTPUT_FOLDER \
    --cpp-namespace $CPP_NAMESPACE \
    --cpp-optional-template "std::experimental::optional" \
    --cpp-optional-header "<experimental/optional>" \
    --ident-cpp-enum FooBar \
    --ident-cpp-field fooBar \
    --ident-cpp-method fooBar \
    --ident-cpp-type FooBar \
    --ident-cpp-enum-type FooBar \
    --ident-cpp-type-param FooBar \
    --ident-cpp-local fooBar \
    --ident-cpp-file FooBar \
    \
    --objc-out $OBJC_OUTPUT_FOLDER \
    --objcpp-out $OBJC_OUTPUT_FOLDER \
    --objc-type-prefix $OBJC_PREFIX \
    --objc-swift-bridging-header $BRIDGING_HEADER \
    \
    --java-out $JAVA_OUTPUT_FOLDER \
    --java-package $JAVA_PACKAGE \
    --ident-java-field fooBar \
    --ident-java-enum FooBar \
    --ident-java-type FooBar \
    \
    --jni-out $JNI_OUTPUT_FOLDER \
    --ident-jni-class NativeFooBar \
    --ident-jni-file NativeFooBar \
    \
    --idl $IDL_FILE

cp "$OBJC_OUTPUT_FOLDER/$BRIDGING_HEADER.h" "$BASE_DIR/project_ios/DiceKeys/$BRIDGING_HEADER.h"

