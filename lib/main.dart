import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import 'domain/controllers/auth_controller.dart';
import 'domain/controllers/mascota_controller.dart';
import 'presentation/screens/login/login_screen.dart';
import 'presentation/screens/login/register_screen.dart';
import 'presentation/screens/usuario/home_screen.dart';
import 'presentation/screens/veterinario/vet_home_screen.dart';
import 'presentation/screens/usuario/mis_mascotas_screen.dart';
import 'presentation/screens/usuario/adopciones_screen.dart';
import 'presentation/screens/usuario/servicios_screen.dart';
import 'presentation/screens/veterinario/nuevo_paciente_screen.dart';
import 'presentation/screens/veterinario/consultas_virtuales_screen.dart';
import 'presentation/screens/veterinario/urgencias_screen.dart';
import 'presentation/screens/veterinario/inventario_screen.dart';
import 'presentation/screens/usuario/perfil_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseAnonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()..tryRestoreSession()),
        ChangeNotifierProvider(create: (_) => MascotaController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Huellitas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6B35)),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        useMaterial3: true,
      ),
      home: Consumer<AuthController>(
        builder: (context, authController, _) {
          if (authController.isAuthenticated) {
            if (authController.currentUser?.rol == 'veterinario') {
              return const VetHomeScreen();
            }
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/vet_home': (context) => const VetHomeScreen(),
        '/mis_mascotas': (context) => const MisMascotasScreen(),
        '/adopciones': (context) => const AdopcionesScreen(),
        '/servicios': (context) => const ServiciosScreen(),
        '/nuevo_paciente': (context) => const NuevoPacienteScreen(),
        '/consultas_virtuales': (context) => const ConsultasVirtualesScreen(),
        '/urgencias': (context) => const UrgenciasScreen(),
        '/inventario': (context) => const InventarioScreen(),
        '/perfil': (context) => const PerfilScreen(),
      },
    );
  }
}
