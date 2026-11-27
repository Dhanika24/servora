import 'dart:math' as math;

import '../strategies/recommendation_strategy.dart';

double rating(Map<String, dynamic> p) {
  return ((p['stars'] as num) + 15) / ((p['jobs'] as num) + 4);
}

double averageRating(Map<String, dynamic> p) {
  final jobs = p['jobs'] as num;

  return jobs == 0 ? 0 : (p['stars'] as num) / jobs;
}

double predictedRating(
    Map<String, dynamic> provider, Map<String, dynamic>? job) {
  final baseline = rating(provider) / 5;

  if (job == null) return baseline;

  final budget = job['budget'] as num;

  if (budget <= 0) return baseline;

  final history = List<Map>.from(
    provider['examples'] ?? [],
  ).where((entry) {
    return entry['budget'] is num &&
        entry['budget'] > 0 &&
        entry['stars'] is num &&
        entry['stars'] >= 1 &&
        entry['stars'] <= 5;
  }).toList();

  double gap(Map entry) {
    return (math.log(entry['budget']) - math.log(budget)).abs();
  }

  history.sort(
    (a, b) => gap(a).compareTo(gap(b)),
  );

  double total = baseline;
  double weights = 1;

  for (final example in history.take(3)) {
    final weight = 1 / (1 + gap(example));

    total += weight * (example['stars'] as num) / 5;
    weights += weight;
  }

  return total / weights;
}

double reliability(Map<String, dynamic> p) {
  final jobs = p['jobs'] as num;

  return ((p['ontime'] as num) + (p['quick'] as num) + 2) / (2 * jobs + 4);
}

int rankValue(Map<String, dynamic> p) {
  switch (p['level']) {
    case 'Gold':
      return 3;
    case 'Silver':
      return 2;
    default:
      return 1;
  }
}

class RecommendationService {
  const RecommendationService();

  RecommendationFactors factors({
    required Map<String, dynamic> provider,
    required Map<String, dynamic> job,
    required double amount,
    required double hours,
    required double distanceKm,
    required double experienceYears,
  }) {
    return RecommendationFactors(
      budget: math
          .min(
            1.0,
            (job['budget'] as num) / amount,
          )
          .toDouble(),
      quality: predictedRating(provider, job),
      feedback: rating(provider) / 5,
      reliability: reliability(provider),
      completion: 1 / (1 + hours / 24),
      proximity: 1 / (1 + distanceKm / 10),
      experience: math
          .min(
            1.0,
            experienceYears / 10,
          )
          .toDouble(),
      rank: rankValue(provider) / 3,
    );
  }

  double score({
    required Map<String, dynamic> provider,
    required Map<String, dynamic> job,
    required double amount,
    required double hours,
    required double distanceKm,
    required double experienceYears,
    required String priority,
  }) {
    final values = factors(
      provider: provider,
      job: job,
      amount: amount,
      hours: hours,
      distanceKm: distanceKm,
      experienceYears: experienceYears,
    );

    return strategyForPriority(priority).score(values);
  }
}
