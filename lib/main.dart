import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:ui';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login_screen.dart';
import 'services/user_service.dart';

void main() async {
  final startTime = DateTime.now();
  debugPrint('🚀 [MAIN] Inicio de la aplicación - ${startTime.toIso8601String()}');

  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('✅ [MAIN] WidgetsFlutterBinding completado');

  // Cargar las variables de entorno ANTES de ejecutar la app o servicios
  await dotenv.load(fileName: ".env");

  debugPrint('⏳ [MAIN] Esperando 500ms para estabilizar contexto nativo...');
  await Future.delayed(const Duration(milliseconds: 500));

  bool firebaseInitialized = false;

  try {
    debugPrint('🔥 [MAIN] Inicializando Firebase...');
    await Firebase.initializeApp();
    firebaseInitialized = true;
    debugPrint('✅ [MAIN] Firebase inicializado');

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    debugPrint('❌ [MAIN] Error inicializando Firebase: $e');
  }

  debugPrint('📦 [MAIN] Inicializando Hive/UserService antes de runApp...');
  try {
    await UserService.init(firebaseInitialized);
    debugPrint('✅ [MAIN] Hive/UserService listo');
  } catch (e, stack) {
    debugPrint('❌ [MAIN] Error fatal inicializando Hive: $e');
    if (firebaseInitialized) {
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  debugPrint('📱 [MAIN] Llamando runApp() con destino a LoginScreen');

  // 👇 Ahora la app arranca limpia, directo a la lógica de Login 👇
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Certiva App',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'), // Español
      ],
      locale: const Locale('es', 'ES'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB47EDB)),
        useMaterial3: true,
      ),
      // 👇 DESTINO FIJO AL ABRIR LA APP 👇
      home: const LoginScreen(),
    );
  }
}