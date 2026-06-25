import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'supabase_config.dart';
import 'data/services/notificacion_local_service.dart';
import 'data/services/fcm_service.dart';
import 'domain/controllers/auth_controller.dart';
import 'domain/controllers/mascota_controller.dart';
import 'domain/controllers/cita_controller.dart';
import 'domain/controllers/veterinario_controller.dart';
import 'domain/controllers/servicio_controller.dart';
import 'domain/controllers/solicitud_adopcion_controller.dart';
import 'domain/controllers/admin_controller.dart';
import 'presentation/screens/admin/admin_home_screen.dart';
import 'presentation/screens/login/login_screen.dart';
import 'presentation/screens/login/register_screen.dart';
import 'presentation/screens/usuario/home_screen.dart';
import 'presentation/screens/veterinario/vet_home_screen.dart';
import 'presentation/screens/veterinario/vet_citas_screen.dart';
import 'presentation/screens/veterinario/vet_mascotas_screen.dart';
import 'presentation/screens/veterinario/vet_perfil_screen.dart';
import 'presentation/screens/usuario/mis_mascotas_screen.dart';
import 'presentation/screens/usuario/adopciones_screen.dart';
import 'presentation/screens/usuario/servicios_screen.dart';
import 'presentation/screens/usuario/solicitudes_adopcion_screen.dart';
import 'presentation/screens/veterinario/urgencias_screen.dart';
import 'presentation/screens/usuario/urgencias_usuario_screen.dart';
import 'presentation/screens/usuario/perfil_screen.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/usuario/mapa_veterinarios_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase (necesario para FCM)
  // Se captura PlatformException y FirebaseException por si los archivos de
  // configuración nativos no están presentes o el canal de plataforma falla,
  // evitando que la app crashee; FCM quedará deshabilitado en ese caso.
  bool firebaseDisponible = false;
  try {
    await Firebase.initializeApp();
    firebaseDisponible = true;
  } on PlatformException catch (e) {
    debugPrint('Firebase no pudo inicializarse (PlatformException): $e');
  } on FirebaseException catch (e) {
    debugPrint('Firebase no pudo inicializarse (FirebaseException): $e');
  } catch (e) {
    debugPrint('Firebase error inesperado: $e');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // Inicializar notificaciones locales (vibración, recordatorios)
  await NotificacionLocalService.instance.init();

  // Inicializar FCM solo si Firebase se inicializó correctamente
  if (firebaseDisponible) {
    await FcmService.instance.init();
  } else {
    debugPrint('FCM deshabilitado: Firebase no disponible.');
  }

  // Registrar handler: al tocar una push notification abre el home
  // (el usuario verá el badge y podrá abrir el panel de notificaciones)
  NotificacionLocalService.instance.setOnTap((payload) {
    debugPrint('Push tocada con payload: $payload');
    // La app ya está abierta o se abre — el navigatorKey permite navegar
    final ctx = MyApp.navigatorKey.currentContext;
    if (ctx == null) return;
    // Navegar según el tipo de notificación
    if (payload != null && payload.startsWith('adopcion:')) {
      Navigator.of(ctx).pushNamedAndRemoveUntil('/home', (r) => false);
    } else if (payload != null && payload.startsWith('cita:')) {
      Navigator.of(ctx).pushNamedAndRemoveUntil('/vet_home', (r) => false);
    }
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()..tryRestoreSession()),
        ChangeNotifierProvider(create: (_) => MascotaController()),
        ChangeNotifierProvider(create: (_) => CitaController()),
        ChangeNotifierProvider(create: (_) => VeterinarioController()),
        ChangeNotifierProvider(create: (_) => ServicioController()),
        ChangeNotifierProvider(create: (_) => SolicitudAdopcionController()),
        ChangeNotifierProvider(create: (_) => AdminController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Huellitas',
      debugShowCheckedModeBanner: false,
      navigatorKey: MyApp.navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6B35)),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        useMaterial3: true,
      ),
      home: Consumer<AuthController>(
        builder: (context, authController, _) {
          if (authController.isInitializing) {
            return const SplashScreen();
          }
          if (authController.isAuthenticated) {
            if (authController.currentUser?.rol == 'veterinario') {
              return const VetHomeScreen();
            }
            if (authController.currentUser?.rol == 'administrador') {
              return const AdminHomeScreen();
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
        '/admin_home': (context) => const AdminHomeScreen(),
        '/vet_home': (context) => const VetHomeScreen(),
        '/mis_mascotas': (context) => const MisMascotasScreen(),
        '/adopciones': (context) => const AdopcionesScreen(),
        '/solicitudes_adopcion': (context) => const SolicitudesAdopcionScreen(),
        '/servicios': (context) => const ServiciosScreen(),

        '/urgencias': (context) => const UrgenciasScreen(),
        '/urgencias_usuario': (context) => const UrgenciasUsuarioScreen(),
        '/perfil': (context) => const PerfilScreen(),
        '/vet_citas': (context) => const VetCitasScreen(),
        '/vet_mascotas': (context) => const VetMascotasScreen(),
        '/vet_perfil': (context) => const VetPerfilScreen(),
        '/mapa_veterinarios': (context) => const MapaVeterinariosScreen(),
      },
    );
  }
}
