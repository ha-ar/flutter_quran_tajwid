import 'package:flutter/material.dart';
import '../models/highlighted_word.dart';

class SurahDisplay extends StatelessWidget {
  final String surahName;
  final List<HighlightedWord> highlightedWords;
  final ScrollController?
      scrollController; // optional, passed from parent for lazy loading

  const SurahDisplay({
    super.key,
    required this.surahName,
    required this.highlightedWords,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    // Organize words into lines (max 15 lines or fewer if Surah is short)
    final lines = _organizeIntoLines(highlightedWords);

    return Column(
      children: [
        // Surah Title
        Text(
          surahName,
          style: const TextStyle(
            color: Color(0xFF064E3B),
            fontSize: 24,
            fontWeight: FontWeight.w700,
            fontFamily: 'ArabicUI',
          ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 20),

        // Scrollable Surah Text Container. Use provided controller if available so parent
        // can observe scroll events (for lazy loading additional lines).
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Column(
                  // spacing handled by SizedBox between children if needed
                  children: lines
                      .map((line) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: _buildLine(context, line),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Organize words into lines for better display
  List<List<HighlightedWord>> _organizeIntoLines(List<HighlightedWord> words) {
    if (words.isEmpty) return [];

    final lines = <List<HighlightedWord>>[];
    var currentLine = <HighlightedWord>[];
    var currentLineWidth = 0.0;
    const maxLineWidth = 350.0; // Approximate width per line
    const avgWordWidth = 40.0; // Average word width in pixels

    for (final word in words) {
      // Estimate word width (approximate)
      final wordWidth = avgWordWidth + (word.text.length * 3.5);

      if (currentLineWidth + wordWidth > maxLineWidth &&
          currentLine.isNotEmpty) {
        // Start new line
        lines.add(List<HighlightedWord>.from(currentLine));
        currentLine = [word];
        currentLineWidth = wordWidth;
      } else {
        // Add to current line
        currentLine.add(word);
        currentLineWidth += wordWidth + 6; // 6 for spacing
      }

      // Limit to 15 lines max
      if (lines.length >= 15 && currentLineWidth > 0) {
        lines.add(List<HighlightedWord>.from(currentLine));
        break;
      }
    }

    // Add remaining words to last line
    if (currentLine.isNotEmpty && lines.length < 15) {
      lines.add(currentLine);
    }

    return lines;
  }

  /// Build a single line of words
  Widget _buildLine(BuildContext context, List<HighlightedWord> wordsInLine) {
    return Wrap(
      spacing: 6,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children:
          wordsInLine.map((word) => _buildWordWidget(context, word)).toList(),
    );
  }

  /// Build individual word widget with proper styling
  Widget _buildWordWidget(BuildContext context, HighlightedWord word) {
    Color backgroundColor;
    Color textColor;
    Color borderColor;

    switch (word.status) {
      case WordStatus.recitedCorrect:
        backgroundColor = const Color(0xFFD1F4E8);
        textColor = const Color(0xFF064E3B);
        borderColor = const Color(0xFF10B981);
        break;
      case WordStatus.recitedTajweedError:
        backgroundColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFF7F1D1D);
        borderColor = const Color(0xFFDC2626);
        break;
      case WordStatus.unrecited || WordStatus.recitedNearMiss:
        backgroundColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF374151);
        borderColor = const Color(0xFFE5E7EB);
        break;
    }

    return GestureDetector(
      onTap: word.tajweedError != null
          ? () {
              _showErrorTooltip(context, word.tajweedError!);
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1.5),
          // Add subtle shadow for depth
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: 30),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (word.tajweedError != null)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(
                  Icons.error_outline,
                  size: 16,
                  color: borderColor,
                ),
              ),
            Text(
              word.text,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 18,
                fontFamily: 'Quranic',
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorTooltip(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error,
          style: const TextStyle(fontFamily: 'ArabicUI'),
        ),
        duration: const Duration(seconds: 4),
        backgroundColor: const Color(0xFF991B1B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
