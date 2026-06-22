import 'package:flutter/material.dart';

/// Pantalla de espera (Splash Screen) que se muestra al iniciar la aplicación.
/// Muestra un GIF animado en el centro.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF5F3FF), // Fondo lavanda suave
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image(
              image: AssetImage('asest/huell.gif'),
              width: 180,
              height: 180,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}
