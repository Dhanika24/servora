import 'package:flutter_test/flutter_test.dart';
import 'package:servora/core/validators/validation.dart';

void main() {
  group('Customer request budget validation', () {
    const minimumBudget = 1;
    const maximumBudget = 100000000;
    const errorMessage = 'Enter a valid budget.';

    num validateBudget(dynamic value) {
      return validatedNumber(
        value,
        minimumBudget,
        maximumBudget,
        errorMessage,
      );
    }

    test('accepts a valid positive budget', () {
      expect(validateBudget(5000), 5000);
    });

    test('accepts a decimal budget', () {
      expect(validateBudget(2500.50), 2500.50);
    });

    test('accepts the minimum permitted budget', () {
      expect(validateBudget(minimumBudget), minimumBudget);
    });

    test('accepts the maximum permitted budget', () {
      expect(validateBudget(maximumBudget), maximumBudget);
    });

    test('rejects a budget below the minimum', () {
      expect(() => validateBudget(0.99), throwsException);
    });

    test('rejects a zero budget', () {
      expect(() => validateBudget(0), throwsException);
    });

    test('rejects a negative budget', () {
      expect(() => validateBudget(-1000), throwsException);
    });

    test('rejects a budget above the maximum', () {
      expect(
        () => validateBudget(maximumBudget + 1),
        throwsException,
      );
    });

    test('rejects a missing budget', () {
      expect(() => validateBudget(null), throwsException);
    });

    test('rejects an empty budget string', () {
      expect(() => validateBudget(''), throwsException);
    });

    test('rejects non-numeric input', () {
      expect(() => validateBudget('invalid'), throwsException);
    });

    test('rejects positive infinity', () {
      expect(
        () => validateBudget(double.infinity),
        throwsException,
      );
    });

    test('rejects negative infinity', () {
      expect(
        () => validateBudget(double.negativeInfinity),
        throwsException,
      );
    });

    test('rejects NaN', () {
      expect(
        () => validateBudget(double.nan),
        throwsException,
      );
    });
  });
}
