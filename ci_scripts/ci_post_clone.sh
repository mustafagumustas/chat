#!/bin/sh
echo ">>> Running Flutter build and pod install from ci_post_clone.sh <<<"

# Navigate to project root (just in case)
cd $CI_WORKSPACE

# Flutter packages get
flutter pub get

# Flutter build ios and force output to ios/Flutter or build/ios
flutter build ios --release --no-codesign --build-dir=ios/Flutter

# CocoaPods install
cd ios
pod install