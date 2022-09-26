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
