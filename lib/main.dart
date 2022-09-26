import 'dart:io';

import 'package:flutter/material.dart';

import 'package:goflutter/desktop.dart';
import 'package:goflutter/mobile.dart';

void main() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    Desktop().init();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Go + Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Go + Flutter Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isLoading = false;
  String _message = '';

  void _getMessage() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    String tmpMessage = '';
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      tmpMessage = await Desktop().sayHiWithDuration('Gophers', '10s');
    } else {
      tmpMessage = await Mobile().sayHiWithDuration('Gophers', '10s');
    }

    setState(() {
      _isLoading = false;
      _message = tmpMessage;
    });
  }

  Widget buildMessage(BuildContext context) {
    if (_isLoading) {
      return const CircularProgressIndicator();
    }

    return Text(
      _message,
      style: Theme.of(context).textTheme.headline4,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            buildMessage(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getMessage,
        tooltip: 'Say Hi',
        child: const Icon(Icons.campaign),
      ),
    );
  }
}
