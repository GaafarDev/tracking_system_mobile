import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/tracking/screens/home_screen.dart';
import 'core/services/auth_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Add your providers here
        Provider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'Driver Tracking App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: FutureBuilder<bool>(
          future: AuthService().isLoggedIn(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            return snapshot.data == true ? HomeScreen() : LoginScreen();
          },
        ),
      ),
    );
  }
}
