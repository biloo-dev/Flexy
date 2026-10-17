import 'package:flutter_test/flutter_test.dart';

String normalizePhone(String raw) {
  String clean = raw.replaceAll(RegExp(r'\D'), '');
  if (clean.startsWith('213') && clean.length > 9) {
    clean = '0${clean.substring(3)}';
  } else if (!clean.startsWith('0') && clean.length == 9) {
    clean = '0$clean';
  }
  return clean;
}

void main() {
  group('Phone Autocomplete Normalization & Prefix Matching Tests', () {
    const candidateNumbers = [
      '+213659812181',
      '0659812345',
      '661234567',
      '0771234567',
    ];

    test('Normalizes numbers starting with +213 or missing 0', () {
      expect(normalizePhone('+213659812181'), equals('0659812181'));
      expect(normalizePhone('661234567'), equals('0661234567'));
    });

    test('Returns exact matching prefix ghost suffix for "0659"', () {
      const input = '0659';
      final normInput = normalizePhone(input);

      final match = candidateNumbers
          .map((p) => normalizePhone(p))
          .firstWhere((p) => p.startsWith(normInput) && p != normInput, orElse: () => '');

      expect(match, equals('0659812181'));
      final remainingGhost = match.substring(normInput.length);
      expect(remainingGhost, equals('812181'));
    });

    test('Returns empty string when input has no matching prefix', () {
      const input = '099';
      final normInput = normalizePhone(input);

      final match = candidateNumbers
          .map((p) => normalizePhone(p))
          .firstWhere((p) => p.startsWith(normInput) && p != normInput, orElse: () => '');

      expect(match, isEmpty);
    });
  });
}
