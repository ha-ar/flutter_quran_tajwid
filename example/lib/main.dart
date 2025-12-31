import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quran_tajwid/flutter_quran_tajwid.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: .env file not found. Some features might not work.");
  }

  // Initialize the Quran JSON data before running the app
  await QuranJsonService().initialize();

  // Load custom fonts programmatically
  await QuranFontLoader.loadFonts();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran Recitation Assistant',
      theme: ThemeData(useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _pageController = TextEditingController(
    text: '1',
  );
  int _totalPages = 604;

  @override
  void initState() {
    super.initState();
    // Try to get total pages from service; fallback to 604
    final service = QuranJsonService();
    try {
      _totalPages = service.getTotalPages();
    } catch (_) {
      _totalPages = 604;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openRecitation() {
    final page = int.tryParse(_pageController.text) ?? 1;
    final target = page.clamp(1, _totalPages);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecitationScreen(
          initialPageNumber: target,
          onRecitationComplete: (result) {
            debugPrint('Recitation Result JSON:');
            debugPrint(result.toJsonString());
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quran Recitation Example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Start Page',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'Enter page number (1-$_totalPages)',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _openRecitation,
                ),
              ),
              onSubmitted: (_) => _openRecitation(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _openRecitation,
              child: const Text('Open Recitation'),
            ),
            const SizedBox(height: 24),
            const Text('Or preview quick start:'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const RecitationScreen(initialPageNumber: 1),
                  ),
                );
              },
              child: const Text('Open Page 1 (Al-Fatiha)'),
            ),
          ],
        ),
      ),
    );
  }
}
