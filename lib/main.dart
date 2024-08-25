import 'package:firebase_core/firebase_core.dart';
 
import 'package:flutter/material.dart';

import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

// import 'package:whatsapp_messenger/common/extension/custom_theme_extension.dart';

import 'package:whatsapp_messenger/common/routes/routes.dart';

import 'package:whatsapp_messenger/common/theme/dark_theme.dart';

import 'package:whatsapp_messenger/common/theme/light_theme.dart';

import 'package:whatsapp_messenger/feature/auth/controller/auth_controller.dart';

import 'package:whatsapp_messenger/feature/chat/pages/gemini_chat.dart';

// import 'package:whatsapp_messenger/feature/chat/pages/camera_preview_page.dart';

import 'package:whatsapp_messenger/feature/home/pages/home_page.dart';

// import 'package:whatsapp_messenger/features/auth/pages/login_page.dart';

// import 'package:whatsapp_messenger/feature/auth/pages/verification_page.dart';

import 'package:whatsapp_messenger/feature/welcome/pages/welcome_page.dart';

import 'package:whatsapp_messenger/firebase_options.dart';



void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner:false ,
      title: 'Flutter Demo',
      theme: lightTheme(),
      darkTheme: darkTheme(),
      home: ref.watch(userInfoAuthProvider).when(
        data: (user) {
          FlutterNativeSplash.remove();
          if (user == null) return const WelcomePage();
          return const HomePage();
        },
        error: (error, trace) {
          return Scaffold(
            body: Center(
              child: Text('$error'),
            ),
          );
        },
        loading: () {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
      // home: GeminiChat(),
      onGenerateRoute: Routes.onGenerateRoute,
    );
  }
}
