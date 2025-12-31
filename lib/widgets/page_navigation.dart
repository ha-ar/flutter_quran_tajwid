import 'package:flutter/material.dart';
import '../services/quran_json_service.dart';

class PageNavigation extends StatefulWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;

  const PageNavigation({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  State<PageNavigation> createState() => _PageNavigationState();
}

class _PageNavigationState extends State<PageNavigation> {
  late TextEditingController _pageController;
  late List<Map<String, dynamic>> _surahs;
  bool _isLoadingSurahs = false;

  @override
  void initState() {
    super.initState();
    _pageController =
        TextEditingController(text: widget.currentPage.toString());
    _loadSurahs();
  }

  @override
  void didUpdateWidget(PageNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPage != widget.currentPage) {
      _pageController.text = widget.currentPage.toString();
    }
  }

  Future<void> _loadSurahs() async {
    setState(() => _isLoadingSurahs = true);
    try {
      final quranService = QuranJsonService();
      await quranService.initialize();
      final surahs = quranService.getAllSurahs();
      setState(() => _surahs = surahs);
    } catch (e) {
      debugPrint('Error loading surahs: $e');
      setState(() => _surahs = []);
    } finally {
      setState(() => _isLoadingSurahs = false);
    }
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= widget.totalPages) {
      widget.onPageChanged(page);
      _pageController.text = page.toString();
    }
  }

  void _goToSurah(int surahNumber) {
    final quranService = QuranJsonService();
    final pageNumber = quranService.getPageForSurah(surahNumber);
    if (pageNumber != null) {
      _goToPage(pageNumber);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page navigation row
          Row(
            children: [
              // Previous button
              IconButton(
                onPressed: widget.currentPage > 1
                    ? () => _goToPage(widget.currentPage - 1)
                    : null,
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Previous Page',
              ),
              // Page input
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: TextField(
                    controller: _pageController,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Page number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (value) {
                      final page = int.tryParse(value);
                      if (page != null) {
                        _goToPage(page);
                      }
                    },
                  ),
                ),
              ),
              // Page info
              SizedBox(
                width: 60,
                child: Text(
                  'of ${widget.totalPages}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
              // Next button
              IconButton(
                onPressed: widget.currentPage < widget.totalPages
                    ? () => _goToPage(widget.currentPage + 1)
                    : null,
                icon: const Icon(Icons.arrow_forward),
                tooltip: 'Next Page',
              ),
            ],
          ),
          // Surah selector
          if (!_isLoadingSurahs && _surahs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: DropdownButton<int>(
                isExpanded: true,
                hint: const Text('Go to Surah...'),
                value: null,
                items: _surahs.map((surah) {
                  final surahNumber = surah['number'] as int;
                  final surahName = surah['name'] as String;
                  return DropdownMenuItem<int>(
                    value: surahNumber,
                    child: Text(
                      '$surahNumber. $surahName',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (surahNumber) {
                  if (surahNumber != null) {
                    _goToSurah(surahNumber);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
