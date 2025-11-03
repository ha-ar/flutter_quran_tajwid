import 'package:string_similarity/string_similarity.dart';

class FuzzyMatchingService {
  static const double _similarityThreshold = 0.4;

  static bool isSimilar(String s1, String s2) {
    final similarity = StringSimilarity.compareTwoStrings(s1, s2);
    return similarity >= _similarityThreshold;
  }
}
