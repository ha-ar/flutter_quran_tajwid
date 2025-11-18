import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/quran_json_service.dart';
import 'screens/recitation_screen.dart';

void main() async {
  await dotenv.load();
  // Initialize JSON-based Quran data
  await QuranJsonService().initialize();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran Recitation Assistant',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF064E3B),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF064E3B),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            fontFamily: 'ArabicUI',
          ),
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            color: Color(0xFF064E3B),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'ArabicUI',
          ),
          titleMedium: TextStyle(
            color: Color(0xFF064E3B),
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'ArabicUI',
          ),
          bodyMedium: TextStyle(
            color: Color(0xFF374151),
            fontSize: 14,
            fontFamily: 'ArabicUI',
          ),
          bodySmall: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 12,
            fontFamily: 'ArabicUI',
          ),
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF064E3B), width: 2),
            ),
          ),
        ),
      ),
      home: const RecitationScreen(),
    );
  }
}
