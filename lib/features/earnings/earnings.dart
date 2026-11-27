part of '../../main.dart';

class ProviderEarnings extends StatefulWidget {
  const ProviderEarnings({super.key});

  @override
  State<ProviderEarnings> createState() => _ProviderEarningsState();
}

class _ProviderEarningsState extends State<ProviderEarnings> {
  String period = 'This month';
  String category = 'All services';

  late final Stream<QuerySnapshot<RowData>> earningsStream;

  final periods = const [
    'Today',
    'This month',
    'This year',
    'All time',
  ];

  @override
  void initState() {
    super.initState();

    earningsStream = db
        .collection('jobs')
        .where('assigned', isEqualTo: uid)
        .snapshots(includeMetadataChanges: true);
  }

  double amountValue(dynamic value) {
    if (value is num && value.isFinite && value >= 0) {
      return value.toDouble();
    }

    return 0;
  }

  String money(num value) {
    return servoraMoney(value);
  }

  DateTime? completionDate(RowData job) {
    return sriLankaDateTime(job['reviewedAt']) ??
        sriLankaDateTime(job['finished']);
  }

  bool matchesPeriod(RowData job) {
    if (period == 'All time') return true;

    final date = completionDate(job);

    if (date == null) return false;

    final now = sriLankaDateTime(
      DateTime.now().millisecondsSinceEpoch,
    )!;

    switch (period) {
      case 'Today':
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;

      case 'This month':
        return date.year == now.year && date.month == now.month;

      case 'This year':
        return date.year == now.year;

      default:
        return true;
    }
  }

  bool matchesCategory(RowData job) {
    return category == 'All services' || job['category'] == category;
  }

  double grossTotal(List<RowData> jobs) {
    return jobs.fold<double>(
      0,
      (total, job) => total + amountValue(job['amount']),
    );
  }

  double chargeTotal(List<RowData> jobs) {
    return jobs.fold<double>(
      0,
      (total, job) => total + amountValue(job['serviceCharge']),
    );
  }

  bool hasFinancialDetails(RowData job) {
    final amount = job['amount'];
    final charge = job['serviceCharge'];

    return amount is num &&
        amount.isFinite &&
        amount >= 0 &&
        charge is num &&
        charge.isFinite &&
        charge >= 0 &&
        charge <= amount;
  }

  Widget sectionTitle(String title) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }

  Widget netCard(double net, int incompleteCount, bool cached) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF007D70), Color(0xFF003F38)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  color: Color(0xFFD9F5EC), size: 22),
              SizedBox(width: 10),
              Expanded(
                  child: Text('Recorded net earnings',
                      style: TextStyle(
                          color: Color(0xFFD9F5EC),
                          fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 12),
          Text(money(net),
              style: theme.textTheme.headlineMedium
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('$period · $category',
              style: const TextStyle(color: Color(0xFFD9F5EC))),
          const SizedBox(height: 8),
          const Text('After recorded service charges',
              style: TextStyle(color: Color(0xFFD9F5EC), fontSize: 12)),
          if (incompleteCount > 0) ...[
            const SizedBox(height: 8),
            Text('Known financial records only ($incompleteCount incomplete).',
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
          if (cached) ...[
            const SizedBox(height: 8),
            const Text('Showing saved data',
                style: TextStyle(color: Color(0xFFD9F5EC), fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget financialCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? description,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withAlpha(24),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(height: 8),
            Text(title,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colors.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(value,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(description, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  Widget summaryGrid(List<Widget> children) {
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 300 &&
              MediaQuery.textScalerOf(context).scale(14) <= 19
          ? 2
          : 1;
      const gap = 8.0;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    });
  }

  Widget financialBar(
      {required String label,
      required double value,
      required double maximum,
      required Color color,
      String? detail}) {
    final theme = Theme.of(context);
    final fraction = maximum > 0 && maximum.isFinite
        ? (value / maximum).clamp(0.0, 1.0).toDouble()
        : 0.0;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(label, style: theme.textTheme.titleSmall),
              Text(money(value),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          if (detail != null) Text(detail, style: theme.textTheme.bodySmall),
          const SizedBox(height: 7),
          LinearProgressIndicator(
            value: fraction,
            color: color,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
            semanticsLabel: label,
            semanticsValue: money(value),
          ),
        ],
      ),
    );
  }

  Widget analyticsCard(String title, String subtitle, List<Widget> children) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 5),
            Text(subtitle,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget earningsTrend(List<RowData> financialJobs) {
    final totals = <DateTime, double>{};
    for (final job in financialJobs) {
      final date = completionDate(job);
      if (date == null) continue;
      final bucket = switch (period) {
        'Today' => DateTime.utc(date.year, date.month, date.day, date.hour),
        'This month' => DateTime.utc(date.year, date.month, date.day),
        'This year' => DateTime.utc(date.year, date.month),
        _ => DateTime.utc(date.year),
      };
      final net =
          amountValue(job['amount']) - amountValue(job['serviceCharge']);
      totals[bucket] = (totals[bucket] ?? 0) + net;
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final visible =
        entries.skip(entries.length > 6 ? entries.length - 6 : 0).toList();
    final maximum = visible.fold<double>(
        0, (highest, entry) => entry.value > highest ? entry.value : highest);
    final localizations = MaterialLocalizations.of(context);
    String label(DateTime date) => switch (period) {
          'Today' => localizations
              .formatTimeOfDay(TimeOfDay(hour: date.hour, minute: 0)),
          'This month' => localizations.formatShortDate(date),
          'This year' => localizations.formatMonthYear(date),
          _ => date.year.toString(),
        };
    final unit = switch (period) {
      'Today' => 'hours',
      'This month' => 'days',
      'This year' => 'months',
      _ => 'years',
    };
    return analyticsCard(
      'Net earnings over time',
      'Recorded $unit only · Sri Lanka time. Bars scaled to the largest displayed value.',
      [
        if (entries.isEmpty)
          const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('No dated records with complete financial details.')),
        if (entries.length > visible.length)
          Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                  'Latest ${visible.length} of ${entries.length} recorded $unit.')),
        for (final entry in visible)
          financialBar(
              label: label(entry.key),
              value: entry.value,
              maximum: maximum,
              color: Theme.of(context).colorScheme.primary),
      ],
    );
  }

  Widget serviceBreakdown(List<RowData> jobs) {
    final totals = <String, double>{};
    for (final job in jobs) {
      final name = job['category']?.toString() ?? 'Other';
      totals[name] = (totals[name] ?? 0) + amountValue(job['amount']);
    }
    final total = grossTotal(jobs);
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return analyticsCard('Gross earnings by service',
        'Share of recorded gross earnings in the selected period.', [
      if (entries.isEmpty)
        const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('No completed jobs for this period.')),
      for (final entry in entries)
        financialBar(
            label: entry.key,
            value: entry.value,
            maximum: total,
            color: Theme.of(context).colorScheme.primary,
            detail: total > 0
                ? '${(entry.value / total * 100).toStringAsFixed(1)}% of gross earnings'
                : 'No recorded gross value'),
    ]);
  }

  Widget transactionCard(String id, RowData job) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final amount = job['amount'];
    final charge = amountValue(job['serviceCharge']);
    final complete = hasFinancialDetails(job);
    final reviewed = sriLankaDateTime(job['reviewedAt']) != null;
    final categoryName = job['category']?.toString() ?? 'Service';
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              ServiceCategoryIcon(category: categoryName, size: 42),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job['title']?.toString() ?? 'Completed service',
                      style: theme.textTheme.titleMedium),
                  Text(categoryName, style: theme.textTheme.bodySmall),
                ],
              )),
            ]),
            const SizedBox(height: 10),
            Text('Customer: ${job['name'] ?? '-'}'),
            Text(
                reviewed
                    ? 'Reviewed: ${servoraDateLabel(context, job['reviewedAt'])}'
                    : 'Work submitted: ${servoraDateLabel(context, job['finished'])}',
                style: theme.textTheme.bodySmall),
            const Divider(),
            Text(
                'Gross amount: ${amount is num && amount.isFinite && amount >= 0 ? money(amount) : 'Unavailable'}'),
            if (complete) ...[
              const SizedBox(height: 4),
              Text(
                  'Service charge: ${money(charge)} (${job['feePercent'] ?? '-'}%)'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recorded net earnings',
                        style: TextStyle(
                            color: colors.onPrimaryContainer, fontSize: 12)),
                    Text(money(amountValue(amount) - charge),
                        style: theme.textTheme.titleLarge
                            ?.copyWith(color: colors.onPrimaryContainer)),
                  ],
                ),
              ),
            ] else
              Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('Financial details incomplete.',
                      style: TextStyle(color: colors.error))),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => go(context, Job(id: id)),
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('View job details'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<RowData>>(
      stream: earningsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return page('Earnings', [
            const Text('Unable to load your earnings.'),
          ]);
        }

        if (!snapshot.hasData) {
          return page('Earnings', [
            const LinearProgressIndicator(),
          ]);
        }

        final documents = snapshot.data!.docs;

        final completed = documents
            .where(
              (doc) => doc.data()['status'] == 'completed',
            )
            .toList();

        final lifetimeJobs = completed.map((doc) => doc.data()).toList();

        final selected = completed.where((doc) {
          final job = doc.data();

          return matchesCategory(job) && matchesPeriod(job);
        }).toList();

        selected.sort((a, b) {
          final aDate = completionDate(a.data());
          final bDate = completionDate(b.data());

          final aTime = aDate?.millisecondsSinceEpoch ?? 0;

          final bTime = bDate?.millisecondsSinceEpoch ?? 0;

          final order = bTime.compareTo(aTime);
          return order == 0 ? a.id.compareTo(b.id) : order;
        });

        final selectedJobs = selected.map((doc) => doc.data()).toList();

        final financialJobs = selectedJobs.where(hasFinancialDetails).toList();

        final incompleteCount = selectedJobs.length - financialJobs.length;

        final gross = grossTotal(selectedJobs);
        final charges = chargeTotal(financialJobs);

        final net = grossTotal(financialJobs) - charges;

        final pending = documents.map((doc) => doc.data()).where((job) {
          return matchesCategory(job) &&
              const [
                'booked',
                'in progress',
                'awaiting review',
              ].contains(job['status']);
        }).toList();

        final pendingAmount = grossTotal(pending);

        final unknownDateCount = lifetimeJobs
            .where(
              (job) => matchesCategory(job) && completionDate(job) == null,
            )
            .length;

        final theme = Theme.of(context);
        final colors = theme.colorScheme;
        final dark = theme.brightness == Brightness.dark;
        final amber = dark ? const Color(0xFFFCD34D) : const Color(0xFFB45309);
        final blue = dark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8);
        final cached = snapshot.data!.metadata.isFromCache;

        return page('Earnings', [
          sectionTitle('Business overview'),
          const Text('Track your recorded earnings and service performance.'),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Reporting period', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final option in periods)
                        ChoiceChip(
                          label: Text(option),
                          selected: period == option,
                          onSelected: (value) {
                            if (value) setState(() => period = option);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  select(
                      'Service category',
                      category,
                      ['All services', ...categories],
                      (value) => setState(() => category = value)),
                ],
              ),
            ),
          ),
          netCard(net, incompleteCount, cached),
          summaryGrid([
            financialCard(
                title: 'Gross earnings',
                value: money(gross),
                icon: Icons.trending_up,
                color: colors.primary),
            financialCard(
                title: 'Recorded service charges',
                value: money(charges),
                icon: Icons.receipt_long_outlined,
                color: amber),
            financialCard(
                title: 'Pending job value',
                value: money(pendingAmount),
                icon: Icons.pending_actions,
                color: blue,
                description: '${pending.length} active jobs · all dates'),
            financialCard(
                title: 'Completed jobs',
                value: selectedJobs.length.toString(),
                icon: Icons.task_alt,
                color: colors.primary),
          ]),
          if (incompleteCount > 0 ||
              (period != 'All time' && unknownDateCount > 0))
            Card(
              margin: EdgeInsets.zero,
              color: colors.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reporting notes',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: colors.onTertiaryContainer)),
                    if (incompleteCount > 0)
                      Text(
                          '$incompleteCount completed jobs have incomplete financial details. '
                          'Only complete financial records contribute to net earnings and service charge totals.',
                          style: TextStyle(color: colors.onTertiaryContainer)),
                    if (period != 'All time' && unknownDateCount > 0)
                      Text(
                          '$unknownDateCount completed jobs have no recorded date and are excluded from this period.',
                          style: TextStyle(color: colors.onTertiaryContainer)),
                  ],
                ),
              ),
            ),
          sectionTitle('Business analytics'),
          earningsTrend(financialJobs),
          serviceBreakdown(selectedJobs),
          financialCard(
              title: 'Lifetime gross earnings',
              value: money(grossTotal(lifetimeJobs)),
              icon: Icons.account_balance_wallet_outlined,
              color: colors.primary,
              description:
                  '${lifetimeJobs.length} completed jobs · all services and dates'),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: colors.primary),
                  const SizedBox(width: 10),
                  const Expanded(
                      child: Text(
                          'Amounts represent agreed job values and calculated service charges, '
                          'not verified payment transactions. Older jobs without review dates '
                          'use their work submission dates. Pending job values are before deductions.')),
                ],
              ),
            ),
          ),
          sectionTitle('Earnings history'),
          Text('${selected.length} completed jobs · $period · $category',
              style: theme.textTheme.bodySmall),
          if (selected.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text('No earnings recorded for this period.',
                    textAlign: TextAlign.center),
              ),
            ),
          for (final doc in selected) transactionCard(doc.id, doc.data()),
        ]);
      },
    );
  }
}
