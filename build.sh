set -e

SDK="/opt/Android/Sdk"
BUILD_TOOLS="${SDK}/build-tools/29.0.2"
PLATFORM="${SDK}/platforms/android-33"

FLUTTER_ROOT="/opt/flutter"
JAVA_HOME='/opt/android-studio/jbr'

BUILD_DIR=$(realpath "__build")
PROJECT_DIR=$(realpath ".")

FLUTTER_PROJECT_ROOT="$PROJECT_DIR/flutter"
FLUTTER_OUTPUT_DIR="$BUILD_DIR/assets"


rm -rf $BUILD_DIR

mkdir -p $BUILD_DIR/gen $BUILD_DIR/obj $BUILD_DIR/apk
mkdir -p $BUILD_DIR/apk/lib/armeabi-v7a $BUILD_DIR/apk/lib/x86

mkdir -p $BUILD_DIR/apk/lib/arm64-v8a 
mkdir -p $BUILD_DIR/apk/lib/arm



#--------------------------------------------------------------------------------
#--------------------------------------------------------------------------------
#----                                                                      ------
#----        Build Flutter                                                 ------
#----                                                                      ------
#--------------------------------------------------------------------------------
#--------------------------------------------------------------------------------

pushd flutter

mkdir -p $FLUTTER_OUTPUT_DIR



/opt/flutter/bin/cache/dart-sdk/bin/dart \
    pub \
    --color \
    --directory  . \
    get \
    --example \


/opt/flutter/bin/cache/dart-sdk/bin/dart \
    --disable-dart-dev \
    --packages=/opt/flutter/packages/flutter_tools/.dart_tool/package_config.json \
    /opt/flutter/bin/cache/flutter_tools.snapshot \
    --quiet \
    assemble \
    --no-version-check \
    --depfile /home/alfred/Practice/handmade_flutter/flutter_app_test/build/app/intermediates/flutter/debug/flutter_build.d \
    --output $FLUTTER_OUTPUT_DIR \
    -dTargetFile=lib/main.dart \
    -dTargetPlatform=android \
    -dBuildMode=debug \
    -dTrackWidgetCreation=true \
    debug_android_application \

popd


#--------------------------------------------------------------------------------
#--------------------------------------------------------------------------------
#----                                                                      ------
#----        Build APK and add flutter to it                               ------
#----                                                                      ------
#--------------------------------------------------------------------------------
#--------------------------------------------------------------------------------



cp external/lib/arm64-v8a/libflutter.so $BUILD_DIR/apk/lib/arm64-v8a/
cp external/lib/armeabi-v7a/libflutter.so $BUILD_DIR/apk/lib/armeabi-v7a/
cp external/lib/armeabi-v7a/libflutter.so $BUILD_DIR/apk/lib/arm/


CLASSPATH="${PLATFORM}/android.jar"
CLASSPATH="$CLASSPATH:${PROJECT_DIR}/external/jar/flutter_embedding_debug-1.0.0.jar"
CLASSPATH="$CLASSPATH:${PROJECT_DIR}/external/jar/lifecycle-common-2.2.0.jar"

javac \
    -classpath "$CLASSPATH" \
    -d "$BUILD_DIR/obj" \
    java/com/hereket/handmade_flutter/MainActivity.java \
    java/io/flutter/plugins/GeneratedPluginRegistrant.java \


CLASS_FILES=$(find $BUILD_DIR/obj/ -iname "*.class")
"${BUILD_TOOLS}/d8" $CLASS_FILES \
    --output $BUILD_DIR/apk/my_classes.jar


pushd $BUILD_DIR/apk
"${BUILD_TOOLS}/d8" my_classes.jar \
    ${PLATFORM}/android.jar \
    ${PROJECT_DIR}/external/jar/flutter_embedding_debug-1.0.0.jar \
    ${PROJECT_DIR}/external/jar/lifecycle-common-2.2.0.jar \
    ${PROJECT_DIR}/external/jar/lifecycle-runtime-2.2.0.jar \
    ${PROJECT_DIR}/external/jar/core-common-2.2.0.jar \
    ${PROJECT_DIR}/external/jar/core-1.10.0.jar \
    ${PROJECT_DIR}/external/jar/tracing-1.1.0.jar \

popd



"${BUILD_TOOLS}/aapt" package -f -M AndroidManifest.xml -S res \
    -A $FLUTTER_OUTPUT_DIR \
    -I "${PROJECT_DIR}/external/jar/flutter_embedding_debug-1.0.0.jar" \
    -I "${PLATFORM}/android.jar" \
    -F $BUILD_DIR/handmade_flutter.unsigned.apk $BUILD_DIR/apk/



"${BUILD_TOOLS}/zipalign" -f -p 4 \
    $BUILD_DIR/handmade_flutter.unsigned.apk $BUILD_DIR/handmade_flutter.aligned.apk



"${BUILD_TOOLS}/apksigner" sign --ks keystore.jks \
    --ks-key-alias androidkey --ks-pass pass:android \
    --key-pass pass:android --out $BUILD_DIR/handmade_flutter.apk \
    $BUILD_DIR/handmade_flutter.aligned.apk




# ################################################################################
# ## RUN ON DEVICE
# ################################################################################
# "${SDK}/platform-tools/adb" install -r $BUILD_DIR/handmade_flutter.apk
# "${SDK}/platform-tools/adb" shell am start -n com.hereket.handmade_flutter/.MainActivity
