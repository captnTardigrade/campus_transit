import 'package:campus_transit/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:campus_transit/widgets/get_location.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Transit',
      theme: ThemeData(
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            fontSize: 16,
          ),
        ),
        colorScheme: ColorScheme.fromSwatch(
          backgroundColor: const Color(0xFFEFEFEF),
          primarySwatch: createMaterialColor(const Color(0xFF514C5E)),
        ),
        cardColor: const Color(0xff504C5D),
        primaryColor: const Color(0xffA6A1C7),
      ),
      home: const MyHomePage(title: 'CampusTransit'),
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
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: const GetLocation(),
      ),
    );
  }
}
