# Go and Flutter

This project shows the integration of [Go](https://go.dev) into a mobile and desktop [Flutter](https://flutter.dev) application on Android, iOS, Linux, macOS and Windows. In the project we are using Go 1.19 and Flutter 3.3.2 (Dart 2.18.1). You can verify you installation by running `go version` and `flutter doctor`.

For the Android and iOS application we also have to install the [`gomobile`](https://github.com/golang/go/wiki/Mobile) tools. This can be done by running the following commands:

```sh
go install golang.org/x/mobile/cmd/gomobile@latest
gomobile init
```

To build the Go code for Android we also have to set the `ANDROID_HOME` and `ANDROID_NDK_HOME` environment variables. In the following we are using the Android SDK which is installed in `/Users/ricoberger/Library/Android/sdk` and the NDK (Version 23.2.8568313) which is installed in `/Users/ricoberger/Library/Android/sdk/ndk/23.2.8568313`.

```sh
export ANDROID_HOME=/Users/ricoberger/Library/Android/sdk
export ANDROID_NDK_HOME=/Users/ricoberger/Library/Android/sdk/ndk/23.2.8568313
```

## Setting up the Android and iOS application

The Go code for our Android and iOS applications lives in a package named [`mobile`](./cmd/mobile/mobile.go). The package exports two functions: `SayHi` and `SayHiWithDuration`:

```go
package mobile

import (
    "fmt"
    "time"
)

// SayHi returns a greeting message for the given name.
func SayHi(name string) (string, error) {
    return fmt.Sprintf("Hi %s!", name), nil
}

// SayHiWithDuration returns a greeting message for the given name, but simulates a heavier task by sleeping for the
// given duration, before the greeting is returned.
func SayHiWithDuration(name, duration string) (string, error) {
    parsedDuration, err := time.ParseDuration(duration)
    if err != nil {
        return "", err
    }

    time.Sleep(parsedDuration)

    return fmt.Sprintf("Hi %s!", name), nil
}
```

To be able to use our two functions in the Flutter project, we have to build our Go code using `gomobile`, by running the following commands:

```sh
mkdir -p android/app/src/libs
gomobile bind -o android/app/src/libs/mobile.aar -target=android github.com/ricoberger/go-flutter/cmd/mobile

mkdir -p ios/Runner/libs
gomobile bind -o ios/Runner/libs/mobile.xcframework -target=ios github.com/ricoberger/go-flutter/cmd/mobile
```

### Android

This will create a `android/app/src/libs/mobile.aar` file for **Android** and a `ios/Runner/libs/mobile.xcframework` file for iOS. These two files can now be used in the native Android and iOS code.

To use the `mobile.aar` in the Android project, we have to adjust the `android/app/build.gradle` file to include the following lines at the end of the file:

```sh
repositories {
    flatDir{
      dirs './src/libs'
    }
}

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version"

    implementation fileTree(dir: 'libs', include: ['*.jar', '*.aar'])
    implementation (name: 'mobile', ext: 'aar')
}
```

To use the Go function we create a new file named `MobilePlugin.kt` which provides a `FlutterMethodChannel` named `ricoberger.de/go-flutter`. This channel is used to call our exported Go function from our Flutter application.

```kotlin
package de.ricoberger.goflutter.goflutter

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.*
import io.flutter.plugin.common.MethodChannel.*
import java.lang.Exception
import java.util.concurrent.Executors;

import mobile.Mobile;

class MobilePlugin : FlutterPlugin, MethodCallHandler {
  private lateinit var channel : MethodChannel

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    val taskQueue = flutterPluginBinding.binaryMessenger.makeBackgroundTaskQueue()
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "ricoberger.de/go-flutter", StandardMethodCodec.INSTANCE, taskQueue)
    channel.setMethodCallHandler(this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "sayHi") {
      val name = call.argument<String>("name")

      if (name == null) {
        result.error("BAD_ARGUMENTS", null, null)
      } else {
        sayHi(name, result)
      }
    } else if (call.method == "sayHiWithDuration") {
      val name = call.argument<String>("name")
      val duration = call.argument<String>("duration")

      if (name == null || duration == null) {
        result.error("BAD_ARGUMENTS", null, null)
      } else {
        sayHiWithDuration(name, duration, result)
      }
    } else {
      result.notImplemented()
    }
  }

  private fun sayHi(name: String, result: MethodChannel.Result) {
    try {
      val data: String = Mobile.sayHi(name)
      result.success(data)
    } catch (e: Exception) {
      result.error("SAY_HI_FAILED", e.localizedMessage, null)
    }
  }

  private fun sayHiWithDuration(name: String, duration: String, result: MethodChannel.Result) {
    try {
      val data: String = Mobile.sayHiWithDuration(name, duration)
      result.success(data)
    } catch (e: Exception) {
      result.error("SAY_HI_WITH_DURATION_FAILED", e.localizedMessage, null)
    }
  }
}
```

In the last step we have to add our plugin to the `MainActivity.kt` file:

```kotlin
package de.ricoberger.goflutter.goflutter

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

class MainActivity: FlutterActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    flutterEngine.plugins.add(MobilePlugin())
  }
}
```

### iOS

To use the `mobile.xcframework` in the **iOS** project, the `ios` folder must be opened in Xcode. In Xcode the file can be added by creating a new group in the `Runner` folder named `libs`. Then we can right clicking on the `libs` group and selecting `Add Files to "Runner"...`. In the following dialoge the `mobile.xcframework` file can be selected. After clicking on `Add` the file should be available in the iOS Xcode project.

To use the Go function we create a new file named `MobilePlugin.swift` which provides a `FlutterMethodChannel` named `ricoberger.de/go-flutter`. This channel is used to call our exported Go function from our Flutter application.

```swift
import UIKit
import Flutter
import Mobile

public class MobilePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    // Note: In release 2.10, the Task Queue API is only available on the master channel for iOS.
    // let taskQueue = registrar.messenger.makeBackgroundTaskQueue()
    // let channel = FlutterMethodChannel(name: "kubenav.io", binaryMessenger: registrar.messenger(), codec: FlutterStandardMethodCodec.sharedInstance, taskQueue: taskQueue)
    let channel = FlutterMethodChannel(name: "ricoberger.de/go-flutter", binaryMessenger: registrar.messenger())
    let instance = MobilePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "sayHi" {
      if let args = call.arguments as? Dictionary<String, Any>,
        let name = args["name"] as? String
      {
        sayHi(name: name, result: result)
      } else {
        result(FlutterError(code: "BAD_ARGUMENTS", message: nil, details: nil))
      }
    } else if call.method == "sayHiWithDuration" {
      if let args = call.arguments as? Dictionary<String, Any>,
        let name = args["name"] as? String,
        let duration = args["duration"] as? String
      {
        sayHiWithDuration(name: name, duration: duration, result: result)
      } else {
        result(FlutterError(code: "BAD_ARGUMENTS", message: nil, details: nil))
      }
    } else {
      result(FlutterMethodNotImplemented)
    }
  }

  private func sayHi(name: String, result: FlutterResult) {
    var error: NSError?

    let data = MobileSayHi(name, &error)
    if error != nil {
      result(FlutterError(code: "SAY_HI_FAILED", message: error?.localizedDescription ?? "", details: nil))
    } else {
      result(data)
    }
  }

  private func sayHiWithDuration(name: String, duration: String, result: FlutterResult) {
    var error: NSError?

    let data = MobileSayHiWithDuration(name, duration, &error)
    if error != nil {
      result(FlutterError(code: "SAY_HI_WITH_DURATION_FAILED", message: error?.localizedDescription ?? "", details: nil))
    } else {
      result(data)
    }
  }
}
```

In the last step we have to register our plugin in the  `AppDelegate.swift` file:

```swift
import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    MobilePlugin.register(with: registrar(forPlugin: "ricoberger.de/go-flutter")!)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### Flutter

To use the created channle in the Flutter code a `MethodChannel` with the name `ricoberger.de/go-flutter` is required. To call the defined methods the `invokeMethod` function can be used. The `invokeMethod` function takes the method name as first argument and an optional map of arguments as second argument. The final code of our `mobile.dart` file looks as follows:

```dart
import 'dart:async';

import 'package:flutter/services.dart';

class Mobile {
  static const platform = MethodChannel('ricoberger.de/go-flutter');

  Mobile();

  Future<String> sayHi(String name) async {
    try {
      final String result = await platform.invokeMethod(
        'sayHi',
        <String, dynamic>{
          'name': name,
        },
      );

      return result;
    } catch (err) {
      return Future.error(err);
    }
  }

  Future<String> sayHiWithDuration(String name, String duration) async {
    try {
      final String result = await platform.invokeMethod(
        'sayHiWithDuration',
        <String, dynamic>{
          'name': name,
          'duration': duration,
        },
      );

      return result;
    } catch (err) {
      return Future.error(err);
    }
  }
}
```

## Setting up the Linux, macOS and Windows application

The Go code for the Linux, macOS and Windows version of the application, lives in a file called `cmd/desktop/desktop.go`. The package name for our Go code must be `main` and exports the `SayHi` and `SayHiWithDuration` functions. It also exports a `Init` function which must be called before any other function to initalize the Dart API.

```go
package main

// #include <stdlib.h>
import "C"

import (
    "fmt"
    "time"
    "unsafe"

    "github.com/ricoberger/go-flutter/cmd/desktop/dart_api_dl"
)

// Init is used to initalize the Dart API and must be called before any other exported function.
//
//export Init
func Init(api unsafe.Pointer) {
    dart_api_dl.Init(api)
}

// FreePointer can be used to free a returned pointer.
//
//export FreePointer
func FreePointer(ptr *C.char) {
    C.free(unsafe.Pointer(ptr))
}

// SayHi returns a greeting message for the given name.
//
//export SayHi
func SayHi(port C.long, nameC *C.char, nameLen C.int) {
    name := C.GoStringN(nameC, nameLen)

    go sayHi(int64(port), name)
}

func sayHi(port int64, name string) {
    dart_api_dl.SendToPort(port, fmt.Sprintf("Hi %s!", name))
}

// SayHiWithDuration returns a greeting message for the given name, but simulates a heavier task by sleeping for the
// given duration, before the greeting is returned.
//
//export SayHiWithDuration
func SayHiWithDuration(port C.long, nameC *C.char, nameLen C.int, durationC *C.char, durationLen C.int) {
    name := C.GoStringN(nameC, nameLen)
    duration := C.GoStringN(durationC, durationLen)

    go sayHiWithDuration(int64(port), name, duration)
}

func sayHiWithDuration(port int64, name, duration string) {
    parsedDuration, err := time.ParseDuration(duration)
    if err != nil {
        dart_api_dl.SendToPort(port, fmt.Sprintf("Error: %s", err.Error()))
        return
    }

    time.Sleep(parsedDuration)

    dart_api_dl.SendToPort(port, fmt.Sprintf("Hi %s!", name))
}

func main() {}
```

As it can be seen in the above code, we also have to create a package `dart_api_dl`, which is used to initalize the Dart API and to send the results of our Go functions back to the Flutter application:

```go
package dart_api_dl

// #include <stdlib.h>
// #include "stdint.h"
// #include "include/dart_api_dl.c"
//
// bool GoDart_PostCObject(Dart_Port_DL port, Dart_CObject* obj) {
//   return Dart_PostCObject_DL(port, obj);
// }
import "C"

import (
    "unsafe"
)

func Init(api unsafe.Pointer) {
    if C.Dart_InitializeApiDL(api) != 0 {
        panic("Failed to initialize Dart DL C API: Version mismatch. Must update \"include/\" to match Dart SDK version")
    }
}

func SendToPort(port int64, data string) {
    ret := C.CString(data)

    var obj C.Dart_CObject
    obj._type = C.Dart_CObject_kString

    // cgo does not support unions so we are forced to do this
    *(**C.char)(unsafe.Pointer(&obj.value)) = ret
    C.GoDart_PostCObject(C.int64_t(port), &obj)

    C.free(unsafe.Pointer(ret))
}
```

The content of the `cmd/desktop/dart_api_dl/includes` folder can be found at [https://github.com/dart-lang/sdk/tree/2.18.1/runtime/include](https://github.com/dart-lang/sdk/tree/2.18.1/runtime/include). Download the files for your dart version and place them in the `includes` folder.

In the next step we have build our Go code into a C shared library for all supported platforms. This can be achieved by setting the `-buildmode c-shared` flag, which build the listed main package, plus all packages it imports, into a C shared library.

### Linux

To build the Go code for the **Linux** version, we have to create a `desktop.so` file, which can be loaded by Flutter application:

```sh
GOOS=linux GOARCH=amd64 CGO_ENABLED=1 go build -buildmode c-shared -o linux/desktop.so github.com/ricoberger/go-flutter/cmd/desktop
```

When a release version of the Flutter application is created the `desktop.so` file must be copied to the release build:

```sh
flutter build linux --release
cp linux/desktop.so build/linux/x64/release/bundle/lib/
```

### macOS

To build the Go code for the **macOS** version, we have to create a `desktop.dylib` file, which can be loaded by Flutter application. To support Intel and Apple Silicon chips, a universal binary must be created by combining the `.dylib` files for both platforms into a single file:

```sh
GOARCH=amd64 GOOS=darwin CGO_ENABLED=1 go build -buildmode c-shared -o macos/desktop.x64.dylib github.com/ricoberger/go-flutter/cmd/desktop
GOARCH=arm64 GOOS=darwin CGO_ENABLED=1 go build -buildmode c-shared -o macos/desktop.arm64.dylib github.com/ricoberger/go-flutter/cmd/desktop
lipo -create macos/desktop.x64.dylib macos/desktop.arm64.dylib -output macos/desktop.dylib
```

The `desktop.dylib` can then be added to the Xcode project. To do this, open the `macos` folder in Xcode. Right click on the `Frameworks` folder, then select `Add Files to "Runner"...`, then select the `desktop.dylib` file and click `Add`.

### Windows

To build the Go code for the **Windows** version, we have to create a `desktop.dll` file, which can be loaded by Flutter application:

```sh
GOOS=windows GOARCH=amd64 CGO_ENABLED=1 go build -buildmode c-shared -o windows/desktop.dll github.com/ricoberger/go-flutter/cmd/desktop
```

When a release version of the Flutter application is created the `desktop.dll` file must be copied to the release build:

```sh
flutter build linux --release
cp windows/kubenav.dll build/windows/runner/Release/
```

### Flutter

Now that we have a C shared library for our Go code on all platforms we can use the `dart:ffi` package to call the C APIs. For that we create a file named `desktop.dart`, where we load our C shared library into a variable named `library`. This variable is then used to get the reference to the C function created from our Go code. Finally we always call the C function.

```dart
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

// ignore: camel_case_types
typedef init_func = Void Function(Pointer<Void>);
typedef InitFunc = void Function(Pointer<Void>);

// ignore: camel_case_types
typedef freepointer_function = Void Function(Pointer<Utf8>);
typedef FreePointerFn = void Function(Pointer<Utf8>);

// ignore: camel_case_types
typedef sayhi_func = Void Function(
  Int64 port,
  Pointer<Utf8> name,
  Int32 nameLen,
);
typedef SayHiFunc = void Function(
  int port,
  Pointer<Utf8> name,
  int nameLen,
);

// ignore: camel_case_types
typedef sayhiwithduration_func = Void Function(
  Int64 port,
  Pointer<Utf8> name,
  Int32 nameLen,
  Pointer<Utf8> duration,
  Int32 durationLen,
);
typedef SayHiWithDurationFunc = void Function(
  int port,
  Pointer<Utf8> name,
  int nameLen,
  Pointer<Utf8> duration,
  int durationLen,
);

class Desktop {
  static final Desktop _instance = Desktop._internal();
  late DynamicLibrary library;

  factory Desktop() {
    return _instance;
  }

  /// [Desktop._internal] is used to load our C shared lbrary into a variable named [library].
  Desktop._internal() {
    String libraryPath = getLibraryPath();
    if (libraryPath == '') {
      exit(0);
    }
    library = DynamicLibrary.open(libraryPath);
  }

  static String getLibraryPath() {
    if (Platform.isWindows) {
      return 'desktop.dll';
    } else if (Platform.isLinux) {
      return 'desktop.so';
    } else if (Platform.isMacOS) {
      return 'desktop.dylib';
    } else {
      return '';
    }
  }

  /// [init] must be called before all other functions, to allow the usage of the symbolds defined in `dart_api_dl.h`.
  Future<void> init() async {
    var initC = library.lookup<NativeFunction<init_func>>('Init');
    final init = initC.asFunction<InitFunc>();
    init(NativeApi.initializeApiDLData);
  }

  /// [sayHi] implements a wrapper around our Go functions. Instead of directly calling the exported functions and
  /// waiting for the results, we are using async callbacks to not block our UI.
  ///
  /// For this we open a long-lived port for receiving messages. This port is then passed to the Go function. In the Go
  /// code we spawn a new Go routine as soon as possible and return the called function. The we send the results of the
  /// executed Go code to the given port. When we received the result we can close the stream and return the result.
  Future<String> sayHi(
    String name,
  ) async {
    var sayHiC = library.lookup<NativeFunction<sayhi_func>>('SayHi');
    final sayHi = sayHiC.asFunction<SayHiFunc>();

    String receiveData = '';
    bool receivedCallback = false;

    var receivePort = ReceivePort()
      ..listen((data) {
        receiveData = data;
        receivedCallback = true;
      });
    final nativeSendPort = receivePort.sendPort.nativePort;

    sayHi(
      nativeSendPort,
      name.toNativeUtf8(),
      name.length,
    );

    while (!receivedCallback) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    receivePort.close();

    return receiveData;
  }

  Future<String> sayHiWithDuration(
    String name,
    String duration,
  ) async {
    var sayHiWithDurationC = library
        .lookup<NativeFunction<sayhiwithduration_func>>('SayHiWithDuration');
    final sayHiWithDuration =
        sayHiWithDurationC.asFunction<SayHiWithDurationFunc>();

    String receiveData = '';
    bool receivedCallback = false;

    var receivePort = ReceivePort()
      ..listen((data) {
        receiveData = data;
        receivedCallback = true;
      });
    final nativeSendPort = receivePort.sendPort.nativePort;

    sayHiWithDuration(
      nativeSendPort,
      name.toNativeUtf8(),
      name.length,
      duration.toNativeUtf8(),
      duration.length,
    );

    while (!receivedCallback) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    receivePort.close();

    return receiveData;
  }
}
```

## The final Flutter application

The `Mobile` and `Desktop` class can then be used in our Flutter application as follows:

```dart
String tmpMessage = '';
if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
  tmpMessage = await Desktop().sayHiWithDuration('Gophers', '10s');
} else {
  tmpMessage = await Mobile().sayHiWithDuration('Gophers', '10s');
}
```

To use the desktop implementation we have to call the `init()` method in our `main` function:

```dart
void main() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    Desktop().init();
  }

  runApp(const MyApp());
}
```
