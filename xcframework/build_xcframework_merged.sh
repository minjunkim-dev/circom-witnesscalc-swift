# This scripts creates merged library for arm64 only for both sim and ios, and then creates xcframework from it.

rm -rf ./libwitness.xcframework

xcodebuild -create-xcframework \
-library libs_ios/libwitness.a \
-headers headers \
-library libs_sim/libwitness.a \
-headers headers \
-output libwitness.xcframework \
&& \
cp -rf ./libwitness.xcframework ../Libs
