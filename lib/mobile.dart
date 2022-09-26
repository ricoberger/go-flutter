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
