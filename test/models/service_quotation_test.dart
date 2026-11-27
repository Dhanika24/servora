import 'package:flutter_test/flutter_test.dart';
import 'package:servora/models/service_quotation.dart';

void main() {
  Map<String, dynamic> quotationData() {
    return {
      'provider': 'provider123',
      'name': 'Test Provider',
      'amount': 2500,
      'hours': 3,
      'created': 1700000000000,
    };
  }

  test('Creates a typed quotation from database data', () {
    final quote = ServiceQuotation.fromMap(
      quotationData(),
    );

    expect(quote.providerId, 'provider123');
    expect(quote.providerName, 'Test Provider');
    expect(quote.amount, 2500);
    expect(quote.hours, 3);
  });

  test('Rejects invalid quotation amount', () {
    final data = quotationData();
    data['amount'] = -100;

    expect(
      () => ServiceQuotation.fromMap(data),
      throwsException,
    );
  });

  test('Rejects invalid completion time', () {
    final data = quotationData();
    data['hours'] = 721;

    expect(
      () => ServiceQuotation.fromMap(data),
      throwsException,
    );
  });

  test('Rejects missing provider name', () {
    final data = quotationData();
    data.remove('name');

    expect(
      () => ServiceQuotation.fromMap(data),
      throwsException,
    );
  });

  test('Rejects invalid quotation timestamp', () {
    final data = quotationData();
    data['created'] = 'invalid';

    expect(
      () => ServiceQuotation.fromMap(data),
      throwsException,
    );
  });

  test('Calculates the booking completion deadline', () {
    final quote = ServiceQuotation.fromMap(
      quotationData(),
    );

    expect(
      quote.completionDeadline(1700000000000),
      1700010800000,
    );
  });

  test('Recognizes a response within one hour', () {
    final quote = ServiceQuotation.fromMap(
      quotationData(),
    );

    expect(
      quote.isQuickResponse(
        quote.createdAt - 3600000,
      ),
      isTrue,
    );
  });

  test('Rejects a response exceeding one hour', () {
    final quote = ServiceQuotation.fromMap(
      quotationData(),
    );

    expect(
      quote.isQuickResponse(
        quote.createdAt - 3600001,
      ),
      isFalse,
    );
  });
}
