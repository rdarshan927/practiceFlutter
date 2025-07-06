import 'package:flutter/material.dart';
import 'package:hive/hive.dart' show Hive;
import 'package:hive_flutter/adapters.dart';
import 'package:todoapp/pages/home_page.dart';
import 'package:todoapp/theme/app_theme.dart';

void main() async {

  // initialize Hive
  await Hive.initFlutter();

  // open box
  var box = await Hive.openBox('mybox');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomePage(),
    );
  }

}



