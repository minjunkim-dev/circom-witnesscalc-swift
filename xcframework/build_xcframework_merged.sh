# This scripts creates merged library for arm64 only for both sim and ios, and then creates xcframework from it.

rm -rf ./libcircom_witnesscalc.xcframework

xcodebuild -create-xcframework \
-library libs_ios/libcircom_witnesscalc.a \
-headers headers \
-library libs_sim/libcircom_witnesscalc.a \
-headers headers \
-output libcircom_witnesscalc.xcframework \
&& \
cp -rf ./libcircom_witnesscalc.xcframework ../Libs
