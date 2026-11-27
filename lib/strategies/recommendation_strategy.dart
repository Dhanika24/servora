class RecommendationFactors {
  final double budget;
  final double quality;
  final double feedback;
  final double reliability;
  final double completion;
  final double proximity;
  final double experience;
  final double rank;

  const RecommendationFactors({
    required this.budget,
    required this.quality,
    required this.feedback,
    required this.reliability,
    required this.completion,
    required this.proximity,
    required this.experience,
    required this.rank,
  });

  double get balancedScore =>
      0.20 * budget +
      0.20 * quality +
      0.15 * feedback +
      0.15 * reliability +
      0.10 * completion +
      0.10 * proximity +
      0.05 * experience +
      0.05 * rank;
}

abstract interface class RecommendationStrategy {
  double score(RecommendationFactors factors);
}

class BalancedRecommendation implements RecommendationStrategy {
  const BalancedRecommendation();

  @override
  double score(RecommendationFactors factors) {
    return factors.balancedScore;
  }
}

enum RecommendationPriority {
  budget,
  quality,
  distance,
  completion,
}

class PriorityRecommendation implements RecommendationStrategy {
  final RecommendationPriority priority;

  const PriorityRecommendation(this.priority);

  @override
  double score(RecommendationFactors factors) {
    final priorityScore = switch (priority) {
      RecommendationPriority.budget => factors.budget,
      RecommendationPriority.quality => factors.quality,
      RecommendationPriority.distance => factors.proximity,
      RecommendationPriority.completion => factors.completion,
    };

    return 0.70 * factors.balancedScore + 0.30 * priorityScore;
  }
}

RecommendationStrategy strategyForPriority(String priority) {
  return switch (priority) {
    'Budget' => const PriorityRecommendation(
        RecommendationPriority.budget,
      ),
    'Quality' => const PriorityRecommendation(
        RecommendationPriority.quality,
      ),
    'Distance' => const PriorityRecommendation(
        RecommendationPriority.distance,
      ),
    'Fast completion' => const PriorityRecommendation(
        RecommendationPriority.completion,
      ),
    _ => const BalancedRecommendation(),
  };
}
