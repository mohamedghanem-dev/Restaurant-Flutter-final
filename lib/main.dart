import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'widgets/app_theme.dart';
import 'screens/splash_screen.dart';

// Firebase config — نفس config الداشبورد
const _fbOptions = FirebaseOptions(
  apiKey: "AIzaSyD0-TyT2kvB1MaRzZMC3tC_cRpaR2jnUh8",
  authDomain: "my-prject-f1b0f.firebaseapp.com",
  projectId: "my-prject-f1b0f",
  storageBucket: "my-prject-f1b0f.firebasestorage.app",
  messagingSenderId: "858394916257",
  appId: "1:858394916257:web:84ceb0acc2dca94a7b47e0",
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  await Firebase.initializeApp(options: _fbOptions);
  runApp(const AlsharqApp());
}

class AlsharqApp extends StatelessWidget {
  const AlsharqApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مطعم الشرق',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
}
