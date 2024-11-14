# This scripts creates merged library for arm64 only for both sim and ios, and then creates xcframework from it.

rm -rf ./libcircom_witnesscalc.xcframework

# Generate fat sim file with arm64 and x86_64
rm -rf ./libs_sim/libcircom_witnesscalc.a
libtool -static -o libs_sim/libcircom_witnesscalc.a libs_sim_arm64/libcircom_witnesscalc.a libs_sim_x86_64/libcircom_witnesscalc.a

xcodebuild -create-xcframework \
-library libs_ios/libcircom_witnesscalc.a \
-headers headers \
-library libs_sim/libcircom_witnesscalc.a \
-headers headers \
-library libs_darwin/libcircom_witnesscalc.a \
-headers headers \
-output libcircom_witnesscalc.xcframework \
&& \
cp -rf ./libcircom_witnesscalc.xcframework ../Libs
