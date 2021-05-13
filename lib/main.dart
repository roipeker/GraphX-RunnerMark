import 'package:flutter/material.dart';
import 'package:graphx/graphx.dart';
import 'package:runnermark/runner_engine.dart';
import 'package:url_strategy/url_strategy.dart';

void main() {
  setPathUrlStrategy();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Runner Mark',
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xff535353),
          elevation: 24,
          title: Text(
            'RunnerMark with Flutter + GraphX',
            style: TextStyle(fontSize: 14),
          ),
        ),
        body: SizedBox.expand(
          child: SceneBuilderWidget(
            builder: () => SceneController(front: RunnerScene()),
          ),
        ),
      ),
    );
  }
}
