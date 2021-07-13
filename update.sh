#rm -rf ~/Library/Caches/org.carthage.CarthageKit/dependencies/
xcodebuild -version
#time carthage12 update --platform iOS --configuration Debug
#time carthage update  --use-xcframeworks --platform iOS --configuration Debug --cache-builds $1
time swncarthage update --skip-simulators --platform iOS --configuration Debug --cache-builds $1