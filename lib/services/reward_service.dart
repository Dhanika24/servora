enum ProviderRank {
  bronze('Bronze', 10, 0),
  silver('Silver', 8, 1),
  gold('Gold', 5, 2);

  final String label;
  final int feePercent;
  final int visibility;

  const ProviderRank(
    this.label,
    this.feePercent,
    this.visibility,
  );
}

class RewardService {
  const RewardService();

  int calculatePoints({
    required int rating,
    required bool onTime,
    required bool quickResponse,
  }) {
    return 10 +
        (rating >= 4 ? 5 : 0) +
        (onTime ? 4 : 0) +
        (quickResponse ? 3 : 0);
  }

  ProviderRank rankForPoints(int points) {
    if (points >= 120) {
      return ProviderRank.gold;
    }

    if (points >= 50) {
      return ProviderRank.silver;
    }

    return ProviderRank.bronze;
  }

  double calculateServiceCharge({
    required num amount,
    required num feePercent,
  }) {
    return (amount * feePercent).round() / 100;
  }
}
