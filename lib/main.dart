import 'package:flutter/material.dart';
import 'ui/main_screen.dart';
import 'ui/styles.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(FreqTalkApp());
}

class FreqTalkApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FreqTalk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: TacticalTheme.accent,
        scaffoldBackgroundColor: TacticalTheme.background,
      ),
      home: MainScreen(),
    );
  }
}
