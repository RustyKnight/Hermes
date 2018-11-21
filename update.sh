#rm -rf ~/Library/Caches/org.carthage.CarthageKit/dependencies/
xcodebuild -version
time carthage update --platform iOS --configuration Debug
rm -rf Carthage/Build/iOS/Cioffi_Core.framework/Frameworks
