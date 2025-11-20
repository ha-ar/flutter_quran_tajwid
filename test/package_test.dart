import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quran_tajwid/flutter_quran_tajwid.dart';

void main() {
  test('Package imports successfully', () {
    // Just verifying that the package can be imported and symbols are available
    expect(QuranJsonService, isNotNull);
    expect(RecitationScreen, isNotNull);
  });
}
