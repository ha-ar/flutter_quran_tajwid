import 'package:flutter/material.dart';
import '../models/recitation_summary.dart';

class RecitationSummaryWidget extends StatelessWidget {
  final RecitationSummary summary;

  const RecitationSummaryWidget({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final accuracy =
        (summary.correctWords / summary.totalWords * 100).toStringAsFixed(1);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFA7E6E6)),
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF0F9FF),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recording Results - Surah ${summary.surahName}',
            style: const TextStyle(
              color: Color(0xFF064E3B),
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'ArabicUI',
            ),
          ),
          const SizedBox(height: 20),
          _buildStat('Total Words', summary.totalWords.toString()),
          _buildStat('Correct Words', summary.correctWords.toString(),
              const Color(0xFF059669)),
          _buildStat('Tajweed Errors', summary.errorWords.toString(),
              const Color(0xFFDC2626)),
          _buildStat(
              'Recitation Accuracy', '$accuracy%', const Color(0xFF0284C7)),
          if (summary.tajweedErrors.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            const Text(
              'Error Details:',
              style: TextStyle(
                color: Color(0xFF064E3B),
                fontWeight: FontWeight.w600,
                fontFamily: 'ArabicUI',
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: summary.tajweedErrors.length,
              itemBuilder: (context, index) {
                final error = summary.tajweedErrors[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '"${error.word}"',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            fontFamily: 'Quranic',
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          error.error,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                            fontFamily: 'ArabicUI',
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'ArabicUI',
              color: Color(0xFF374151),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: (color ?? Colors.grey[300])?.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color ?? Colors.grey[700],
                fontFamily: 'ArabicUI',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
