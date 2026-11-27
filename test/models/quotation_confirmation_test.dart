import 'package:flutter_test/flutter_test.dart';
import 'package:servora/models/service_quotation.dart';

void main() {
  late Map<String, dynamic> quotation;

  setUp(() {
    quotation = {
      'provider': 'provider1',
      'name': 'Test Provider',
      'amount': 2000,
      'hours': 4,
      'note': 'Repair and installation',
      'created': 1000000,
    };
  });

  group('Quotation confirmation consistency', () {
    test('accepts unchanged quotation', () {
      expect(
        ServiceQuotation.matchesConfirmation(
          quotation,
          Map<String, dynamic>.from(quotation),
        ),
        isTrue,
      );
    });

    test('rejects changed amount', () {
      expect(
        ServiceQuotation.matchesConfirmation(
          {...quotation, 'amount': 3000},
          quotation,
        ),
        isFalse,
      );
    });

    test('rejects changed completion duration', () {
      expect(
        ServiceQuotation.matchesConfirmation(
          {...quotation, 'hours': 8},
          quotation,
        ),
        isFalse,
      );
    });

    test('rejects changed quotation description', () {
      expect(
        ServiceQuotation.matchesConfirmation(
          {...quotation, 'note': 'Labour only'},
          quotation,
        ),
        isFalse,
      );
    });

    test('rejects updated quotation revision', () {
      expect(
        ServiceQuotation.matchesConfirmation(
          {...quotation, 'updatedAt': 2000000},
          quotation,
        ),
        isFalse,
      );
    });

    test('rejects replaced quotation', () {
      expect(
        ServiceQuotation.matchesConfirmation(
          {...quotation, 'created': 3000000},
          quotation,
        ),
        isFalse,
      );
    });

    test('rejects missing confirmation details', () {
      expect(
        ServiceQuotation.matchesConfirmation(
          quotation,
          null,
        ),
        isFalse,
      );

      expect(
        ServiceQuotation.matchesConfirmation(
          quotation,
          <String, dynamic>{'amount': 2000},
        ),
        isFalse,
      );
    });
  });
}
