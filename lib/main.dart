import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase (Requires google-services.json on Android)
  await Firebase.initializeApp();
  runApp(const AwanBrothersApp());
}

class AwanBrothersApp extends StatelessWidget {
  const AwanBrothersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Awan Brothers Tours & Travels',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo.shade900),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      home: const Scaffold(body: Center(child: Text("App Loaded Successfully"))),
      
    );
  }
}
