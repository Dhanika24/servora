import '../core/validators/validation.dart';

class ServiceQuotation {
  final String providerId;
  final String providerName;
  final num amount;
  final num hours;
  final num createdAt;

  const ServiceQuotation({
    required this.providerId,
    required this.providerName,
    required this.amount,
    required this.hours,
    required this.createdAt,
  });

  factory ServiceQuotation.fromMap(
    Map<String, dynamic> data,
  ) {
    final providerId = validatedJobId(
      data['provider'],
    );

    final providerName = data['name'];

    if (providerName is! String || providerName.trim().isEmpty) {
      throw Exception('Invalid provider name.');
    }

    final createdAt = data['created'];

    if (createdAt is! num || !createdAt.isFinite || createdAt <= 0) {
      throw Exception('Invalid quotation date.');
    }

    return ServiceQuotation(
      providerId: providerId,
      providerName: providerName,
      amount: validatedNumber(
        data['amount'],
        1,
        100000000,
        'Invalid quotation amount.',
      ),
      hours: validatedNumber(
        data['hours'],
        1,
        720,
        'Invalid completion time.',
      ),
      createdAt: createdAt,
    );
  }

  static bool matchesConfirmation(
    Map<String, dynamic> current,
    Object? confirmed,
  ) {
    if (confirmed is! Map<String, dynamic>) {
      return false;
    }

    const requiredFields = [
      'provider',
      'name',
      'amount',
      'hours',
      'note',
      'created',
    ];

    for (final field in requiredFields) {
      if (!confirmed.containsKey(field) ||
          !current.containsKey(field) ||
          confirmed[field] != current[field]) {
        return false;
      }
    }

    return confirmed['updatedAt'] == current['updatedAt'];
  }

  int completionDeadline(int bookedAt) {
    return bookedAt + (hours * 3600000).round();
  }

  bool isQuickResponse(num requestCreatedAt) {
    return createdAt - requestCreatedAt <= 3600000;
  }
}
