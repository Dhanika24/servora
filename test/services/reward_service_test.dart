import 'package:flutter_test/flutter_test.dart';
import 'package:servora/services/reward_service.dart';

void main() {
  const service = RewardService();

  group('Reward points', () {
    test('Standard job completion earns 10 points', () {
      expect(
        service.calculatePoints(
          rating: 3,
          onTime: false,
          quickResponse: false,
        ),
        10,
      );
    });

    test('Positive rating earns additional points', () {
      expect(
        service.calculatePoints(
          rating: 5,
          onTime: false,
          quickResponse: false,
        ),
        15,
      );
    });

    test('Maximum reward is 22 points', () {
      expect(
        service.calculatePoints(
          rating: 5,
          onTime: true,
          quickResponse: true,
        ),
        22,
      );
    });
  });

  group('Provider ranks', () {
    test('Bronze rank below 50 points', () {
      expect(service.rankForPoints(0), ProviderRank.bronze);
      expect(service.rankForPoints(49), ProviderRank.bronze);
    });

    test('Silver rank starts at 50 points', () {
      expect(service.rankForPoints(50), ProviderRank.silver);
      expect(service.rankForPoints(119), ProviderRank.silver);
    });

    test('Gold rank starts at 120 points', () {
      expect(service.rankForPoints(120), ProviderRank.gold);
    });

    test('Rank service charge percentages are correct', () {
      expect(ProviderRank.bronze.feePercent, 10);
      expect(ProviderRank.silver.feePercent, 8);
      expect(ProviderRank.gold.feePercent, 5);
    });
  });

  group('Service charges', () {
    test('Bronze service charge', () {
      expect(
        service.calculateServiceCharge(
          amount: 2500,
          feePercent: 10,
        ),
        250,
      );
    });

    test('Silver service charge', () {
      expect(
        service.calculateServiceCharge(
          amount: 4500,
          feePercent: 8,
        ),
        360,
      );
    });

    test('Gold service charge', () {
      expect(
        service.calculateServiceCharge(
          amount: 10000,
          feePercent: 5,
        ),
        500,
      );
    });

    test('Service charge rounds to two decimal places', () {
      expect(
        service.calculateServiceCharge(
          amount: 1234.56,
          feePercent: 8,
        ),
        98.76,
      );
    });
  });
}
