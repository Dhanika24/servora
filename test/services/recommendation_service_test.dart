import 'package:flutter_test/flutter_test.dart';
import 'package:servora/services/recommendation_service.dart';
import 'package:servora/strategies/recommendation_strategy.dart';

void main() {
  const service = RecommendationService();

  const factors = RecommendationFactors(
    budget: 1.0,
    quality: 0.8,
    feedback: 0.7,
    reliability: 0.6,
    completion: 0.5,
    proximity: 0.4,
    experience: 0.3,
    rank: 0.2,
  );

  final provider = <String, dynamic>{
    'stars': 0,
    'jobs': 0,
    'ontime': 0,
    'quick': 0,
    'level': 'Bronze',
    'examples': [],
  };

  const job = <String, dynamic>{
    'budget': 3000,
  };

  group('Recommendation strategies', () {
    test('Balanced scoring preserves original weights', () {
      expect(
        const BalancedRecommendation().score(factors),
        closeTo(0.67, 0.000001),
      );
    });

    test('Budget priority increases budget influence', () {
      expect(
        strategyForPriority('Budget').score(factors),
        closeTo(0.769, 0.000001),
      );
    });

    test('Quality priority uses predicted quality', () {
      expect(
        strategyForPriority('Quality').score(factors),
        closeTo(0.709, 0.000001),
      );
    });

    test('Distance priority uses proximity', () {
      expect(
        strategyForPriority('Distance').score(factors),
        closeTo(0.589, 0.000001),
      );
    });

    test('Fast completion priority uses completion score', () {
      expect(
        strategyForPriority('Fast completion').score(factors),
        closeTo(0.619, 0.000001),
      );
    });

    test('Unknown priority uses balanced strategy', () {
      expect(
        strategyForPriority('Unknown').score(factors),
        closeTo(0.67, 0.000001),
      );
    });
  });

  group('Recommendation engine', () {
    test('New provider receives a baseline rating', () {
      expect(
        rating(provider),
        closeTo(3.75, 0.000001),
      );
    });

    test('New provider reliability uses baseline', () {
      expect(
        reliability(provider),
        closeTo(0.5, 0.000001),
      );
    });

    test('Historical similar jobs influence prediction', () {
      final historicalProvider = {
        ...provider,
        'examples': [
          {'budget': 3000, 'stars': 5},
        ],
      };

      expect(
        predictedRating(historicalProvider, job),
        closeTo(0.875, 0.000001),
      );
    });

    test('Invalid historical examples are excluded', () {
      final historicalProvider = {
        ...provider,
        'examples': [
          {'budget': -100, 'stars': 5},
          {'budget': 3000, 'stars': 8},
        ],
      };

      expect(
        predictedRating(historicalProvider, job),
        closeTo(0.75, 0.000001),
      );
    });

    test('Lower quotation improves budget priority', () {
      double score(double amount) {
        return service.score(
          provider: provider,
          job: job,
          amount: amount,
          hours: 3,
          distanceKm: 5,
          experienceYears: 3,
          priority: 'Budget',
        );
      }

      expect(score(2500), greaterThan(score(6000)));
    });

    test('Nearby provider receives better distance score', () {
      double score(double distanceKm) {
        return service.score(
          provider: provider,
          job: job,
          amount: 2500,
          hours: 3,
          distanceKm: distanceKm,
          experienceYears: 3,
          priority: 'Distance',
        );
      }

      expect(score(2), greaterThan(score(20)));
    });

    test('Faster completion improves time priority', () {
      double score(double hours) {
        return service.score(
          provider: provider,
          job: job,
          amount: 2500,
          hours: hours,
          distanceKm: 5,
          experienceYears: 3,
          priority: 'Fast completion',
        );
      }

      expect(score(2), greaterThan(score(48)));
    });

    test('Relevant experience improves recommendation', () {
      double score(double experience) {
        return service.score(
          provider: provider,
          job: job,
          amount: 2500,
          hours: 3,
          distanceKm: 5,
          experienceYears: experience,
          priority: 'Quality',
        );
      }

      expect(score(10), greaterThan(score(1)));
    });
  });
}
