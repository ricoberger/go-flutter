.PHONY: bindings-android
bindings-android:
	mkdir -p android/app/src/libs
	gomobile bind -o android/app/src/libs/mobile.aar -target=android github.com/ricoberger/go-flutter/cmd/mobile

.PHONY: bindings-ios
bindings-ios:
	mkdir -p ios/Runner/libs
	gomobile bind -o ios/Runner/libs/mobile.xcframework -target=ios github.com/ricoberger/go-flutter/cmd/mobile

.PHONY: library-macos
library-macos:
	GOARCH=amd64 GOOS=darwin CGO_ENABLED=1 go build -buildmode c-shared -o macos/desktop.x64.dylib github.com/ricoberger/go-flutter/cmd/desktop
	GOARCH=arm64 GOOS=darwin CGO_ENABLED=1 go build -buildmode c-shared -o macos/desktop.arm64.dylib github.com/ricoberger/go-flutter/cmd/desktop
	lipo -create macos/desktop.x64.dylib macos/desktop.arm64.dylib -output macos/desktop.dylib

.PHONY: library-linux
library-linux:
	GOOS=linux GOARCH=amd64 CGO_ENABLED=1 go build -buildmode c-shared -o linux/desktop.so github.com/ricoberger/go-flutter/cmd/desktop

.PHONY: library-windows
library-windows:
	GOOS=windows GOARCH=amd64 CGO_ENABLED=1 go build -buildmode c-shared -o windows/desktop.dll github.com/ricoberger/go-flutter/cmd/desktop
