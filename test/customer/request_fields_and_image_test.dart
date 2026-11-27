import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:servora/core/validators/validation.dart';

void main() {
  void testRequiredField(
    String fieldName,
    int maxLength,
    String errorMessage,
  ) {
    group(fieldName, () {
      String validate(dynamic value) {
        return validatedText(
          value,
          maxLength,
          errorMessage,
        );
      }

      test('accepts valid text', () {
        expect(validate('Water tank repair'), 'Water tank repair');
      });

      test('trims surrounding whitespace', () {
        expect(validate('  Water tank repair  '), 'Water tank repair');
      });

      test('rejects missing input', () {
        expect(() => validate(null), throwsException);
      });

      test('rejects empty input', () {
        expect(() => validate(''), throwsException);
      });

      test('rejects whitespace-only input', () {
        expect(() => validate('   '), throwsException);
      });

      test('accepts the maximum permitted length', () {
        final value = List.filled(maxLength, 'a').join();

        expect(validate(value), value);
      });

      test('rejects text exceeding the maximum length', () {
        final value = List.filled(maxLength + 1, 'a').join();

        expect(() => validate(value), throwsException);
      });
    });
  }

  group('Customer request field validation', () {
    testRequiredField(
      'Task title',
      100,
      'Enter a valid task title.',
    );

    testRequiredField(
      'Request description',
      500,
      'Enter a valid description.',
    );

    testRequiredField(
      'Service area',
      80,
      'Enter a valid service area.',
    );
  });

  group('Customer request image validation', () {
    const maximumImageSize = 300 * 1024;

    test('accepts an absent optional image', () {
      expect(validatedImage(null), isNull);
    });

    test('accepts an empty optional image reference', () {
      expect(validatedImage(''), isNull);
    });

    test('accepts non-empty image bytes within the size limit', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);

      final result = validatedImage(bytes);

      expect(result, isNotNull);
      expect(result!.bytes, orderedEquals(bytes));
    });

    test('accepts image bytes at the exact size limit', () {
      final bytes = Uint8List(maximumImageSize);

      final result = validatedImage(bytes);

      expect(result, isNotNull);
      expect(result!.bytes.length, maximumImageSize);
    });

    test('rejects empty image bytes', () {
      expect(
        () => validatedImage(Uint8List(0)),
        throwsException,
      );
    });

    test('rejects image bytes exceeding the size limit', () {
      final bytes = Uint8List(maximumImageSize + 1);

      expect(
        () => validatedImage(bytes),
        throwsException,
      );
    });

    test('rejects an unsupported image data type', () {
      expect(
        () => validatedImage('invalid-image'),
        throwsException,
      );
    });
  });
}
