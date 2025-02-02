import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trialerror/screens/get_started.dart';
import 'package:trialerror/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://kcgzoijenfmjcasnpkjp.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtjZ3pvaWplbmZtamNhc25wa2pwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg0MTA3MjksImV4cCI6MjA1Mzk4NjcyOX0.VG6uQvo9pKbKcde-w7JEyhiTcw2uHCCfz3PCG3EmvgQ',
  );

  runApp(FairShare());
}

class FairShare extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Sharing App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color.fromARGB(255, 145, 228, 219), // Teal background color
      ),
      home: AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else {
          final session = supabase.auth.currentSession;
          if (session != null) {
            // User is logged in, show the StartPage
            return StartPage();
          } else {
            // User is not logged in, show the HomeScreen
            return StartPage();
          }
        }
      },
    );
  }
}
