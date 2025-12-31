import 'package:flutter/services.dart';

/// Utility class to programmatically load custom fonts.
/// This bypasses the pubspec.yaml font registration which can sometimes fail.
class QuranFontLoader {
  static bool _isLoaded = false;
  static const String uthmaniFamily = 'IndoPak';
  
  // Asset paths - try package path first, then direct path
  static const String _packageFontPath = 'packages/flutter_quran_tajwid/assets/fonts/indopak.woff2';
  static const String _directFontPath = 'assets/fonts/indopak.woff2';

  /// Loads the Uthmani font programmatically from assets.
  /// Call this once at app startup before using the font.
  /// 
  /// Example:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await QuranFontLoader.loadFonts();
  ///   runApp(MyApp());
  /// }
  /// ```
  static Future<void> loadFonts() async {
    if (_isLoaded) return;

    try {
      // Load Uthmani font
      final uthmaniLoader = FontLoader(uthmaniFamily);
      
      ByteData? fontData;
      
      // Try package path first (when used as a dependency)
      try {
        fontData = await rootBundle.load(_packageFontPath);
        // ignore: avoid_print
        print('QuranFontLoader: Loading font from package path');
      } catch (e) {
        // Try direct path (when running example app or standalone)
        try {
          fontData = await rootBundle.load(_directFontPath);
          // ignore: avoid_print
          print('QuranFontLoader: Loading font from direct path');
        } catch (e2) {
          throw Exception('Could not load font from either path. Package path error: $e, Direct path error: $e2');
        }
      }
      
      uthmaniLoader.addFont(Future.value(fontData));
      await uthmaniLoader.load();
      _isLoaded = true;
      
      // ignore: avoid_print
      print('QuranFontLoader: Uthmani font loaded successfully');
    } catch (e) {
      // ignore: avoid_print
      print('QuranFontLoader: Failed to load Uthmani font: $e');
      rethrow;
    }
  }

  /// Check if fonts have been loaded
  static bool get isLoaded => _isLoaded;
}

