import 'package:flutter_test/flutter_test.dart';
import 'package:servora/main.dart';

void main() {
  test('Servora application can be created', () {
    const app = Servora();

    expect(app, isA<Servora>());
  });
}
