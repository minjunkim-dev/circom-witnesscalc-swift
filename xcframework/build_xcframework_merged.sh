# This scripts creates merged library for:
# - iOS arm64
# - iOS sim arm64 and x86_64
# - macOS armg64
# and then creates xcframework from it and puts into $PROJECT_ROOT/Libs folder.

rm -rf ../Libs/libcircom_witnesscalc.xcframework

libtool -static -o sim/libcircom_witnesscalc.a sim_arm64/libcircom_witnesscalc.a sim_x86_64/libcircom_witnesscalc.a \
&& \
xcodebuild -create-xcframework \
-library ios/libcircom_witnesscalc.a \
-headers include \
-library sim/libcircom_witnesscalc.a \
-headers include \
-library darwin/libcircom_witnesscalc.a \
-headers include \
-output ../Libs/libcircom_witnesscalc.xcframework
