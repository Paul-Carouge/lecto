import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecto/core/router/app_router.dart';
import 'package:lecto/core/theme/theme_provider.dart';
import 'package:lecto/core/database/database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.create();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ProviderScope(child: LectoApp()));
}

class LectoApp extends ConsumerWidget {
  const LectoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = ref.watch(themeDataProvider);
    return MaterialApp(
      title: 'Lecto',
      debugShowCheckedModeBanner: false,
      theme: themeData,
      initialRoute: '/',
      onGenerateRoute: AppRouter.onGenerateRoute,
      builder: (context, child) {
        return AnimatedTheme(
          data: themeData,
          duration: const Duration(milliseconds: 300),
          child: child!,
        );
      },
    );
  }
}
