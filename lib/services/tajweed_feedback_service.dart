
/// Provides semantic feedback for Quran recitation errors by comparing
/// expected vs transcription.
class TajweedFeedbackService {
  /// Analyzes the mismatch between [expected] and [actual] Arabic words
  /// and returns a specific, user-friendly feedback string.
  ///
  /// Returns null if no specific pattern is found or if similarity is too low/high.
  static String? analyzeMistake(String expected, String actual) {
    // Basic normalization for comparison
    final exp = _normalizeForComparison(expected);
    final act = _normalizeForComparison(actual);

    if (exp == act) return null;

    // 1. Check for Common Letter Confusions (Makharij)
    final confusion = _checkLetterConfusion(exp, act);
    if (confusion != null) return confusion;

    // 2. Check for Missing Letters (often Madd/Elongation)
    if (exp.length > act.length) {
      if (exp.contains('ا') && !act.contains('ا')) {
        return "Check your Madd (elongation). You may have shortened an Alif.";
      }
      if (exp.contains('و') && !act.contains('و')) {
        return "Check your Madd (elongation). You may have shortened a Waw.";
      }
      if (exp.contains('ي') && !act.contains('ي')) {
        return "Check your Madd (elongation). You may have shortened a Ya.";
      }
       return "Review the word thoroughly; some letters seem missing.";
    }

    // 3. Check for Extra Letters
    if (act.length > exp.length) {
       return "Be careful not to add extra vowel sounds (Ishba').";
    }
    
    return "Pronunciation needs improvement. Listen to the reference audio.";
  }

  static String _normalizeForComparison(String text) {
    return text
        .replaceAll(RegExp(r'[\u064B-\u0652]'), '') // Remove diacritics
        .replaceAll(RegExp(r'[\u0670]'), 'ا') // Dagger alif -> Normal Alif for diff
        .replaceAll(RegExp(r'[\u0671]'), 'ا')
        .replaceAll(RegExp(r'[\u0640]'), '')
        .replaceAll(RegExp(r'[.،؛؟!]'), '')
        .replaceAll(RegExp(r'[ٱأإآ]'), 'ا')
        .trim();
  }

  static String? _checkLetterConfusion(String exp, String act) {
    // Map of (Expected Char -> Actual Char) => Feedback Message
    final rules = {
      // Qaf vs Kaf
      'ق': {'ك': "Ensure strict articulation of Qaf (ق) from the throat, distinguishing it from Kaf (ك)."},
      'ك': {'ق': "Keep Kaf (ك) light; do not make it deep like Qaf (ق)."},
      
      // Sad vs Sin
      'ص': {'س': "Emphasize Sad (ص) with a full mouth (Tafkheem). Don't mix it with Sin (س)."},
      'س': {'ص': "Keep Sin (س) light (Tarqeeq). Don't mix it with Sad (ص)."},
      
      // Dad vs Dal
      'ض': {'د': "Dad (ض) is unique; use the side of the tongue. It sounded like Dal (د).",
            'ظ': "Dad (ض) shouldn't sound like Zha (ظ)."},
      'د': {'ض': "Keep Dal (د) clear and light."},

      // Ta vs Taa (Emphatic)
      'ط': {'ت': "Ta (ط) is emphatic/heavy. It sounded like a light Ta (ت)."},
      'ت': {'ط': "Keep Ta (ت) light. Don't make it heavy like Ta (ط)."},

      // Ha vs Haa
      'ح': {'ه': "Sharpen your Ha (ح) from the middle throat. It sounded like soft Haa (ه)."},
      'ه': {'ح': "Soften the Haa (ه) from the deepest throat."},

      // Ain vs Hamza
      'ع': {'ا': "Clarify the Ain (ع) from the middle throat.",
            'ء': "Clarify the Ain (ع) from the middle throat."},
      
      // Thal vs Zay/Sin
      'ذ': {'ز': "Thal (ذ) is interdental (tongue tip). Don't buzz match Zay (ز).",
            'س': "Thal (ذ) is interdental. Don't mix with Sin (س)."},
            
      // Tha vs Sin
      'ث': {'س': "Tha (ث) is interdental (tongue tip between teeth). It sounded like Sin (س)."}
    };

    // Simple diff check: Find the first differing character that matches a rule
    // This is naive but effective for single-letter swaps in short words.
    // Ideally we align the strings, but simple scan finds obvious swaps.
    
    // We iterate through expected chars and see if the corresponding actual char matches a known error pattern
    // Note: alignment issues might make index-based comparison flaky. 
    // Better approach: Check if Expected has char X, Actual does NOT, but Actual HAS char Y (the common error).
    
    for (var entry in rules.entries) {
      final targetChar = entry.key;
      final errorMap = entry.value;
      
      if (exp.contains(targetChar) && !act.contains(targetChar)) {
        // Expected char is missing. Did they swap it?
        for (var errorEntry in errorMap.entries) {
          final wrongChar = errorEntry.key;
          if (act.contains(wrongChar)) {
             // Found a potential swap pattern!
             // Double check via position if possible, but presence is a strong indicator in the context of a mismatch
             return errorEntry.value;
          }
        }
      }
    }
    
    return null;
  }
}
