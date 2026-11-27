part of '../../main.dart';

double distance(RowData a, RowData b) {
  return Geolocator.distanceBetween(
        (a['lat'] as num).toDouble(),
        (a['lng'] as num).toDouble(),
        (b['lat'] as num).toDouble(),
        (b['lng'] as num).toDouble(),
      ) /
      1000;
}

class QuoteCandidate {
  final String id;
  final RowData quote;
  final RowData provider;
  final String serviceCategory;

  const QuoteCandidate({
    required this.id,
    required this.quote,
    required this.provider,
    required this.serviceCategory,
  });

  double get amount => (quote['amount'] as num).toDouble();

  double get hours => (quote['hours'] as num).toDouble();

  double get points => (provider['points'] as num).toDouble();

  RowData? get service => providerService(
        provider,
        serviceCategory,
      );

  double get experience => (service?['years'] as num?)?.toDouble() ?? 0.0;

  String get experienceLabel => service == null
      ? 'Service no longer listed'
      : '${service!['years']} years';

  String get availabilityLabel => service == null
      ? 'Service no longer listed'
      : service!['available'] == true
          ? 'Available'
          : 'Not accepting new requests';

  double get jobs => (provider['jobs'] as num).toDouble();

  String get name => quote['name'].toString();
}

const recommendationService = RecommendationService();

double quotationScore(
  QuoteCandidate candidate,
  RowData job,
  String priority,
) {
  return recommendationService.score(
    provider: candidate.provider,
    job: job,
    amount: candidate.amount,
    hours: candidate.hours,
    distanceKm: distance(candidate.provider, job),
    experienceYears: candidate.experience,
    priority: priority,
  );
}

class Discover extends StatefulWidget {
  final RowData? job;
  final String? jobId;

  const Discover({
    this.job,
    this.jobId,
    super.key,
  });

  @override
  State<Discover> createState() => _Discover();
}

class _Discover extends State<Discover> {
  String sorting = 'Recommended for you';
  String priority = 'Quality';

  bool withinBudget = false;
  double minimumRating = 0;
  String rankFilter = 'All ranks';

  bool showFilters = false;
  bool accepting = false;

  final selected = <String>{};

  final sortingOptions = const [
    'Recommended for you',
    'Best quality',
    'Lowest quotation',
    'Fastest completion',
    'Highest rank',
    'Best customer feedback',
    'Nearest provider',
    'Most experienced',
    'Most completed jobs',
    'Most reliable',
    'Best value for money',
  ];

  double sortValue(
    QuoteCandidate candidate,
    RowData job,
  ) {
    final p = candidate.provider;

    switch (sorting) {
      case 'Best quality':
        return 0.75 * predictedRating(p, job) + 0.25 * reliability(p);

      case 'Lowest quotation':
        return -candidate.amount;

      case 'Fastest completion':
        return -candidate.hours;

      case 'Highest rank':
        return candidate.points;

      case 'Best customer feedback':
        return candidate.jobs == 0 ? -1 : rating(p);

      case 'Nearest provider':
        return -distance(p, job);

      case 'Most experienced':
        return candidate.experience;

      case 'Most completed jobs':
        return candidate.jobs;

      case 'Most reliable':
        return reliability(p);

      case 'Best value for money':
        return predictedRating(p, job) / candidate.amount;

      default:
        return quotationScore(candidate, job, priority);
    }
  }

  int compareCandidates(
    QuoteCandidate a,
    QuoteCandidate b,
    RowData job,
  ) {
    final result = sortValue(b, job).compareTo(
      sortValue(a, job),
    );

    if (result != 0) return result;

    final priceComparison = a.amount.compareTo(b.amount);

    if (priceComparison != 0) return priceComparison;

    return a.id.compareTo(b.id);
  }

  bool matchesFilters(
    QuoteCandidate candidate,
    RowData job,
  ) {
    if (withinBudget && candidate.amount > (job['budget'] as num)) {
      return false;
    }

    if (rankFilter != 'All ranks' &&
        candidate.provider['level'] != rankFilter) {
      return false;
    }

    if (minimumRating > 0 &&
        averageRating(candidate.provider) < minimumRating) {
      return false;
    }

    return true;
  }

  void toggleSelection(String id) {
    setState(() {
      if (selected.contains(id)) {
        selected.remove(id);
      } else if (selected.length < 2) {
        selected.add(id);
      }
    });
  }

  String ratingText(RowData p) {
    final jobs = (p['jobs'] as num).toInt();

    if (jobs == 0) return 'Not rated yet';

    return '${averageRating(p).toStringAsFixed(1)}/5 '
        '($jobs ${jobs == 1 ? 'review' : 'reviews'})';
  }

  Future<void> acceptQuotation(
    QuoteCandidate candidate,
  ) async {
    if (accepting || widget.jobId == null) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    final jobId = widget.jobId;

    if (userId == null) return;

    final confirmedQuotation =
        Map<String, dynamic>.unmodifiable(candidate.quote);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Accept quotation?'),
        scrollable: true,
        content: Text(
          'Provider: ${confirmedQuotation['name']}\n'
          'Amount: ${servoraMoney(confirmedQuotation['amount'])}\n'
          'Completion time: ${confirmedQuotation['hours']} hours\n\n'
          'Included services:\n'
          '${confirmedQuotation['note']}\n\n'
          'By accepting, you confirm these quotation details.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted || accepting) return;

    if (FirebaseAuth.instance.currentUser?.uid != userId ||
        widget.jobId != jobId) {
      return;
    }

    setState(() => accepting = true);

    try {
      await send('accept', {
        'jobId': jobId,
        'provider': candidate.id,
        'confirmedQuotation': confirmedQuotation,
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => accepting = false);
      }
    }
  }

  Widget filters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Within my budget'),
              value: withinBudget,
              onChanged: (value) => setState(() {
                withinBudget = value;
                selected.clear();
              }),
            ),
            select(
              'Provider rank',
              rankFilter,
              ['All ranks', 'Bronze', 'Silver', 'Gold'],
              (value) => setState(() {
                rankFilter = value;
                selected.clear();
              }),
            ),
            const SizedBox(height: 12),
            Text(
              'Minimum rating: '
              '${minimumRating.toStringAsFixed(1)}',
            ),
            Slider(
              value: minimumRating,
              min: 0,
              max: 5,
              divisions: 10,
              onChanged: (value) => setState(() {
                minimumRating = value;
                selected.clear();
              }),
            ),
            OutlinedButton(
              onPressed: () => setState(() {
                withinBudget = false;
                minimumRating = 0;
                rankFilter = 'All ranks';
                selected.clear();
              }),
              child: const Text('Reset filters'),
            ),
          ],
        ),
      ),
    );
  }

  Widget recommendationBadge(
    String label,
    IconData icon,
    Color foreground,
    Color background,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: foreground,
            size: 16,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget providerMetric(
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withAlpha(100),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: colors.primary,
            size: 22,
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget providerMetricGrid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final largeText = MediaQuery.textScalerOf(context).scale(12) > 18;

        final columns = constraints.maxWidth < 240 || largeText ? 1 : 2;

        const spacing = 10.0;

        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(
                width: width,
                child: child,
              ),
          ],
        );
      },
    );
  }

  String providerInitials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2);

    final initials = words
        .map(
          (word) => String.fromCharCode(
            word.runes.first,
          ).toUpperCase(),
        )
        .join();

    return initials.isEmpty ? 'P' : initials;
  }

  Widget candidateCard(
    QuoteCandidate candidate,
    RowData job,
    bool recommended,
    bool canCompare,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    final p = candidate.provider;

    final isSelected = selected.contains(candidate.id);

    final affordable = candidate.amount <= (job['budget'] as num);

    final score = quotationScore(candidate, job, priority);

    final rank = p['level']?.toString() ?? 'Unranked';

    final rankColor = switch (rank) {
      'Gold' => dark ? const Color(0xFFFFD66B) : const Color(0xFF956A00),
      'Silver' => dark ? const Color(0xFFC6D5DF) : const Color(0xFF526A7A),
      'Bronze' => dark ? const Color(0xFFF0B78E) : const Color(0xFF96592D),
      _ => colors.primary,
    };

    final budgetColor = affordable
        ? colors.primary
        : dark
            ? const Color(0xFFFCD34D)
            : const Color(0xFFB45309);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: recommended || isSelected
              ? colors.primary
              : colors.outlineVariant,
          width: recommended || isSelected ? 1.5 : 0.8,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (recommended) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: colors.onPrimaryContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Top recommended match',
                        style: TextStyle(
                          color: colors.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: colors.primaryContainer,
                  foregroundColor: colors.onPrimaryContainer,
                  child: Text(
                    providerInitials(candidate.name),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidate.name,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        candidate.serviceCategory,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          recommendationBadge(
                            rank,
                            Icons.workspace_premium_rounded,
                            rankColor,
                            rankColor.withAlpha(25),
                          ),
                          recommendationBadge(
                            '${candidate.points.toStringAsFixed(0)} points',
                            Icons.bolt_rounded,
                            colors.primary,
                            colors.primaryContainer,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quoted price',
                    style: TextStyle(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    servoraMoney(candidate.amount),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: recommendationBadge(
                affordable ? 'Within your budget' : 'Above your budget',
                affordable ? Icons.check_circle_outline : Icons.info_outline,
                budgetColor,
                budgetColor.withAlpha(25),
              ),
            ),
            if (canCompare) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Recommendation score',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    score.isFinite ? score.toStringAsFixed(3) : 'Unavailable',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (score.isFinite)
                LinearProgressIndicator(
                  value: score.clamp(0.0, 1.0).toDouble(),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(10),
                ),
              const SizedBox(height: 8),
              Text(
                'Relative match score based on your '
                'selected priority. It is not a guarantee '
                'of service quality.',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 22),
            providerMetricGrid([
              providerMetric(
                Icons.star_outline_rounded,
                'Customer feedback',
                ratingText(p),
              ),
              providerMetric(
                Icons.schedule_rounded,
                'Completion time',
                '${candidate.hours} hours',
              ),
              providerMetric(
                Icons.location_on_outlined,
                'Approximate distance',
                '${distance(p, job).toStringAsFixed(1)} km',
              ),
              providerMetric(
                Icons.work_history_outlined,
                'Service experience',
                candidate.experienceLabel,
              ),
              providerMetric(
                Icons.task_alt_rounded,
                'Completed jobs',
                candidate.jobs.toStringAsFixed(0),
              ),
              providerMetric(
                Icons.event_available_outlined,
                'Availability',
                candidate.availabilityLabel,
              ),
            ]),
            const SizedBox(height: 20),
            Text(
              'Quotation details',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              candidate.quote['note']?.toString() ??
                  'No additional details provided.',
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Submitted: ${servoraDateLabel(context, candidate.quote['created'])}',
              style: theme.textTheme.bodySmall,
            ),
            if (candidate.quote['updatedAt'] != null)
              Text(
                'Last updated: ${servoraDateLabel(context, candidate.quote['updatedAt'])}',
                style: theme.textTheme.bodySmall,
              ),
            const SizedBox(height: 8),
            Text(
              'Distance is an approximate straight-line estimate.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => go(
                context,
                Profile(id: candidate.id),
              ),
              icon: const Icon(Icons.person_outline_rounded),
              label: const Text('View provider profile'),
            ),
            if (canCompare) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: isSelected || selected.length < 2
                    ? () => toggleSelection(candidate.id)
                    : null,
                icon: Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.compare_arrows_rounded,
                ),
                label: Text(
                  isSelected ? 'Selected for comparison' : 'Add to comparison',
                ),
              ),
            ],
            const SizedBox(height: 16),
            JobContactPanel(
              jobId: widget.jobId!,
              contactUid: candidate.id,
              label: 'Contact provider',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: accepting ? null : () => acceptQuotation(candidate),
              icon: const Icon(
                Icons.check_circle_outline,
              ),
              label: Text(
                accepting ? 'Processing...' : 'Accept quotation',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget comparisonPage(
    List<QuoteCandidate> picks,
    RowData job,
  ) {
    final a = picks[0];
    final b = picks[1];

    final scoreA = quotationScore(a, job, priority);
    final scoreB = quotationScore(b, job, priority);

    final tied = (scoreA - scoreB).abs() < 0.000001;

    final recommendation = tied
        ? 'Both providers have similar recommendation scores.'
        : scoreA > scoreB
            ? '${a.name} is the stronger recommended match.'
            : '${b.name} is the stronger recommended match.';

    final values = <String, List<String>>{
      'Quoted price': [
        (servoraMoney(a.amount)),
        (servoraMoney(b.amount)),
      ],
      'Budget compatibility': [
        a.amount <= (job['budget'] as num) ? 'Within budget' : 'Above budget',
        b.amount <= (job['budget'] as num) ? 'Within budget' : 'Above budget',
      ],
      'Completion time': [
        '${a.hours} hours',
        '${b.hours} hours',
      ],
      'Customer feedback': [
        ratingText(a.provider),
        ratingText(b.provider),
      ],
      'Service experience': [
        a.experienceLabel,
        b.experienceLabel,
      ],
      'Availability': [
        a.availabilityLabel,
        b.availabilityLabel,
      ],
      'Approximate distance': [
        '${distance(a.provider, job).toStringAsFixed(1)} km',
        '${distance(b.provider, job).toStringAsFixed(1)} km',
      ],
      'Completed jobs': [
        a.jobs.toStringAsFixed(0),
        b.jobs.toStringAsFixed(0),
      ],
      'On-time jobs': [
        a.provider['ontime'].toString(),
        b.provider['ontime'].toString(),
      ],
      'Quick responses': [
        a.provider['quick'].toString(),
        b.provider['quick'].toString(),
      ],
      'Reward points': [
        a.points.toStringAsFixed(0),
        b.points.toStringAsFixed(0),
      ],
      'Membership rank': [
        a.provider['level'].toString(),
        b.provider['level'].toString(),
      ],
      'Recommendation score': [
        scoreA.toStringAsFixed(3),
        scoreB.toStringAsFixed(3),
      ],
      'Quotation details': [
        a.quote['note']?.toString() ?? '-',
        b.quote['note']?.toString() ?? '-',
      ],
    };

    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;

        Widget identity(
          QuoteCandidate candidate,
          bool stronger,
        ) {
          return Expanded(
            child: Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: stronger ? colors.primary : colors.outlineVariant,
                  width: stronger ? 1.5 : 0.8,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: colors.primaryContainer,
                      foregroundColor: colors.onPrimaryContainer,
                      child: Text(
                        providerInitials(candidate.name),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      candidate.name,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      candidate.provider['level'].toString(),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                    if (stronger) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Stronger match',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }

        Widget comparisonRow(
          String label,
          List<String> pair,
        ) {
          return Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          pair[0],
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                        ),
                        color: colors.outlineVariant,
                      ),
                      Expanded(
                        child: Text(
                          pair[1],
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        return page('Compare quotations', [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF007D70),
                  Color(0xFF003F38),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFFD9F5EC),
                  size: 36,
                ),
                const SizedBox(height: 16),
                Text(
                  'Intelligent recommendation',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  recommendation,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Your priority: $priority',
                  style: const TextStyle(
                    color: Color(0xFFD9F5EC),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Compare your providers',
            style: theme.textTheme.titleLarge,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              identity(a, !tied && scoreA > scoreB),
              const SizedBox(width: 10),
              identity(b, !tied && scoreB > scoreA),
            ],
          ),
          Text(
            '${a.name} is shown on the left and '
            '${b.name} on the right throughout this comparison.',
            style: theme.textTheme.bodySmall,
          ),
          for (final entry in values.entries)
            comparisonRow(
              entry.key,
              entry.value,
            ),
          Text(
            'Recommendation scores are relative estimates. '
            'Distances are approximate straight-line distances. '
            'Ratings and performance statistics reflect '
            'recorded provider history.',
            style: theme.textTheme.bodySmall,
          ),
          Text(
            'Explore provider portfolios',
            style: theme.textTheme.titleLarge,
          ),
          for (final candidate in picks)
            OutlinedButton.icon(
              onPressed: () => go(
                context,
                Profile(id: candidate.id),
              ),
              icon: const Icon(
                Icons.person_outline_rounded,
              ),
              label: Text(
                'View ${candidate.name}',
              ),
            ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Return to quotations'),
          ),
          Text(
            'Return to the quotations page for the latest '
            'information before accepting a provider.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ]);
      },
    );
  }

  String? _quotationReadKey;

  late Stream<DocumentSnapshot<RowData>> _quotationJobStream;

  late Stream<QuerySnapshot<RowData>> _quotationListStream;

  @override
  Widget build(BuildContext context) {
    if (widget.jobId == null) {
      return page('Service quotations', [
        const Text(
          'Open a service request from My jobs '
          'to view its quotations.',
        ),
      ]);
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return page('Service quotations', [
        const Text('Sign in to view quotations.'),
      ]);
    }

    final jobId = widget.jobId!;

    final readKey = '$currentUserId/$jobId';

    if (_quotationReadKey != readKey) {
      final jobRef = db.collection('jobs').doc(jobId);

      _quotationJobStream = jobRef.snapshots(
        includeMetadataChanges: true,
      );

      _quotationListStream = jobRef.collection('quotes').snapshots(
            includeMetadataChanges: true,
          );

      _quotationReadKey = readKey;
    }

    return StreamBuilder<DocumentSnapshot<RowData>>(
      key: ValueKey(readKey),
      stream: _quotationJobStream,
      builder: (context, jobSnapshot) {
        if (jobSnapshot.hasError) {
          return page('Service quotations', [
            const Text('Unable to load the service request.'),
          ]);
        }

        if (!jobSnapshot.hasData) {
          return page('Service quotations', [
            const LinearProgressIndicator(),
          ]);
        }

        final job = jobSnapshot.data!.data();

        if (job == null ||
            job['owner'] != currentUserId ||
            FirebaseAuth.instance.currentUser?.uid != currentUserId) {
          return page('Service quotations', [
            const Text('Service request unavailable.'),
          ]);
        }

        if (job['status'] != 'open') {
          return page('Service quotations', [
            const Text('This request is no longer open.'),
          ]);
        }

        return page('Service quotations', [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ServiceCategoryIcon(
                  category: job['category'].toString(),
                  size: 62,
                ),
                const SizedBox(height: 16),
                Text(
                  'Find your best match',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  job['title'].toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Your budget: ${servoraMoney(job['budget'])}",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Service area: ${job['area']}",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot<RowData>>(
            stream: _quotationListStream,
            builder: (context, quoteSnapshot) {
              if (quoteSnapshot.hasError) {
                return const Text('Unable to load quotations.');
              }

              if (!quoteSnapshot.hasData) {
                return const LinearProgressIndicator();
              }

              final quotations = quoteSnapshot.data!.docs;

              if (quotations.isEmpty) {
                return card(
                  'Waiting for quotations',
                  'Providers have not submitted quotations yet.',
                );
              }

              final providerIds =
                  quotations.map((quote) => quote.id).toSet().toList()..sort();

              final providerKey =
                  providerIds.map((id) => '${id.length}:$id').join();

              return _QuotationProviderProfiles(
                key: ValueKey(providerKey),
                providerIds: providerIds,
                userId: currentUserId,
                builder: (context, profiles, profilesFromCache) {
                  final candidates = <QuoteCandidate>[
                    for (final quote in quotations)
                      if (profiles.containsKey(quote.id))
                        QuoteCandidate(
                          id: quote.id,
                          quote: quote.data(),
                          provider: profiles[quote.id]!,
                          serviceCategory: job['category'].toString(),
                        ),
                  ];

                  if (candidates.isEmpty) {
                    return card(
                      'Provider profiles unavailable',
                      'Quotations exist, but their provider profiles '
                          'could not be found.',
                    );
                  }

                  final canCompare = candidates.length >= 2;

                  final visible = candidates.where((candidate) {
                    return !canCompare || matchesFilters(candidate, job);
                  }).toList();

                  visible.sort(
                    (a, b) => compareCandidates(a, b, job),
                  );

                  final picks = visible
                      .where(
                        (candidate) => selected.contains(candidate.id),
                      )
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (profilesFromCache ||
                          quoteSnapshot.data!.metadata.isFromCache ||
                          jobSnapshot.data!.metadata.isFromCache)
                        const Text(
                          'Showing saved quotation information. '
                          'Updates may be delayed.',
                        ),
                      if (candidates.length < quotations.length)
                        Text(
                          '${quotations.length - candidates.length} '
                          'provider profiles are currently unavailable.',
                        ),
                      Text(
                        '${quotations.length} '
                        '${quotations.length == 1 ? 'quotation' : 'quotations'} '
                        'received',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (canCompare) ...[
                        select(
                          'Sort by',
                          sorting,
                          sortingOptions,
                          (value) => setState(() {
                            sorting = value;
                          }),
                        ),
                        const SizedBox(height: 12),
                        if (sorting == 'Recommended for you')
                          select(
                            'My priority',
                            priority,
                            [
                              'Quality',
                              'Budget',
                              'Distance',
                              'Fast completion',
                            ],
                            (value) => setState(() {
                              priority = value;
                            }),
                          ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => setState(() {
                            showFilters = !showFilters;
                          }),
                          icon: const Icon(Icons.tune),
                          label: Text(
                            showFilters ? 'Hide filters' : 'Show filters',
                          ),
                        ),
                        if (showFilters) filters(),
                        FilledButton.icon(
                          onPressed: picks.length == 2
                              ? () => go(
                                    context,
                                    comparisonPage(picks, job),
                                  )
                              : null,
                          icon: const Icon(Icons.compare_arrows),
                          label: Text(
                            'Compare quotations (${picks.length}/2)',
                          ),
                        ),
                        if (selected.isNotEmpty)
                          TextButton(
                            onPressed: () => setState(() {
                              selected.clear();
                            }),
                            child: const Text('Clear selection'),
                          ),
                        const SizedBox(height: 14),
                      ],
                      if (visible.isEmpty)
                        const Text(
                          'No quotations match the current filters.',
                        ),
                      for (int i = 0; i < visible.length; i++)
                        candidateCard(
                          visible[i],
                          job,
                          canCompare &&
                              sorting == 'Recommended for you' &&
                              i == 0,
                          canCompare,
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ]);
      },
    );
  }
}

class _QuotationProviderProfiles extends StatefulWidget {
  final List<String> providerIds;

  final String userId;

  final Widget Function(
    BuildContext context,
    Map<String, RowData> profiles,
    bool fromCache,
  ) builder;

  const _QuotationProviderProfiles({
    required this.providerIds,
    required this.userId,
    required this.builder,
    super.key,
  });

  @override
  State<_QuotationProviderProfiles> createState() =>
      _QuotationProviderProfilesState();
}

class _QuotationProviderProfilesState
    extends State<_QuotationProviderProfiles> {
  static const int batchSize = 10;

  final subscriptions = <StreamSubscription<QuerySnapshot<RowData>>>[];

  final snapshots = <int, QuerySnapshot<RowData>>{};

  final failedBatches = <int>{};

  int expectedBatches = 0;

  @override
  void initState() {
    super.initState();

    final ids = widget.providerIds;

    for (var offset = 0; offset < ids.length; offset += batchSize) {
      final batch = ids.skip(offset).take(batchSize).toList();

      final batchIndex = expectedBatches++;

      final subscription = db
          .collection('providers')
          .where(
            FieldPath.documentId,
            whereIn: batch,
          )
          .snapshots(
            includeMetadataChanges: true,
          )
          .listen(
        (snapshot) {
          if (!mounted) return;

          if (FirebaseAuth.instance.currentUser?.uid != widget.userId) {
            return;
          }

          setState(() {
            snapshots[batchIndex] = snapshot;
            failedBatches.remove(batchIndex);
          });
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!mounted) return;

          setState(() {
            failedBatches.add(batchIndex);
          });
        },
      );

      subscriptions.add(subscription);
    }
  }

  @override
  void dispose() {
    for (final subscription in subscriptions) {
      unawaited(subscription.cancel());
    }

    subscriptions.clear();
    snapshots.clear();
    failedBatches.clear();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser?.uid != widget.userId) {
      return const SizedBox.shrink();
    }

    if (failedBatches.isNotEmpty) {
      return card(
        'Unable to load provider profiles',
        'Check your internet connection and reopen this page.',
      );
    }

    if (snapshots.length < expectedBatches) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(
          semanticsLabel: 'Loading matching provider profiles',
        ),
      );
    }

    final profiles = <String, RowData>{};

    var fromCache = false;

    for (final snapshot in snapshots.values) {
      fromCache = fromCache || snapshot.metadata.isFromCache;

      for (final document in snapshot.docs) {
        profiles[document.id] = document.data();
      }
    }

    return widget.builder(
      context,
      profiles,
      fromCache,
    );
  }
}
