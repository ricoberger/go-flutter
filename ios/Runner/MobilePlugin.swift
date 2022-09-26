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
