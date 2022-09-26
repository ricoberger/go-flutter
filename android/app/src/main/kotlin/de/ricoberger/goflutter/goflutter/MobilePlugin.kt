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
