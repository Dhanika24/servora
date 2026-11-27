part of '../main.dart';

class CustomerDashboard extends StatefulWidget {
  final RowData member;

  const CustomerDashboard({
    required this.member,
    super.key,
  });

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  late final Stream<QuerySnapshot<RowData>> jobStream;

  @override
  void initState() {
    super.initState();

    jobStream = db
        .collection('jobs')
        .where('owner', isEqualTo: uid)
        .snapshots(includeMetadataChanges: true);
  }

  String get customerName {
    final name = widget.member['name']?.toString().trim() ?? '';

    if (name.isEmpty) return 'Customer';

    return name.split(RegExp(r'\s+')).first;
  }

  void requestService([String? category]) {
    go(
      context,
      Editor(
        mode: 'post',
        initial: category == null ? null : {'category': category},
      ),
    );
  }

  void openJobs() {
    _openMainTab(context, _ServoraTab.jobs, const JobList(provider: false));
  }

  Widget sectionHeader(
    String title, {
    String? actionLabel,
    VoidCallback? onPressed,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onPressed,
            child: Text(actionLabel),
          ),
      ],
    );
  }

  Widget serviceGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = MediaQuery.textScalerOf(context).scale(12) / 12;

        final columns = scale > 1.3
            ? 2
            : width >= 320
                ? 4
                : width >= 250
                    ? 3
                    : 2;

        const spacing = 8.0;

        final tileWidth = (width - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final category in categories)
              SizedBox(
                width: tileWidth,
                child: ServiceCategoryTile(
                  category: category,
                  onTap: () => requestService(category),
                ),
              ),
          ],
        );
      },
    );
  }

  num latestActivity(RowData job) {
    for (final key in [
      'reviewedAt',
      'finished',
      'startedAt',
      'bookedAt',
      'created',
    ]) {
      final value = job[key];

      if (value is num && value.isFinite && value > 0) {
        return value;
      }
    }

    return 0;
  }

  Widget emptyRequests() {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.assignment_outlined,
                size: 36,
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No active requests',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Your service requests will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => requestService(),
              child: const Text('Request a service'),
            ),
          ],
        ),
      ),
    );
  }

  Widget activeRequests() {
    return StreamBuilder<QuerySnapshot<RowData>>(
      stream: jobStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.cloud_off_outlined),
                  const SizedBox(height: 8),
                  const Text(
                    'Unable to load your requests.',
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: openJobs,
                    child: const Text('Open my jobs'),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: LinearProgressIndicator(),
            ),
          );
        }

        final jobs = snapshot.data!.docs.where((doc) {
          return const [
            'open',
            'booked',
            'in progress',
            'awaiting review',
          ].contains(doc.data()['status']);
        }).toList();

        jobs.sort((a, b) {
          final result =
              latestActivity(b.data()).compareTo(latestActivity(a.data()));

          return result == 0 ? a.id.compareTo(b.id) : result;
        });

        if (jobs.isEmpty && !snapshot.data!.metadata.isFromCache) {
          return emptyRequests();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (snapshot.data!.metadata.isFromCache)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Showing saved requests.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            for (final job in jobs.take(2))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: CustomerRequestCard(
                  key: ValueKey(job.id),
                  jobId: job.id,
                  job: job.data(),
                ),
              ),
            if (jobs.length > 2)
              Text(
                'Showing 2 of ${jobs.length} active requests',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const ServoraBrand(markSize: 36),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(
              Icons.notifications_none_rounded,
            ),
            onPressed: () => _openMainTab(context, _ServoraTab.alerts,
                const NotificationCenter(provider: false)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 680,
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              children: [
                Text(
                  'Hello, $customerName!',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'What service do you need today?',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                ServoraHeroBanner(
                  compact: true,
                  title: 'Find the right professional.',
                  description: 'Compare quotations from local professionals.',
                  buttonLabel: 'Request a service',
                  onPressed: () => requestService(),
                ),
                const SizedBox(height: 20),
                sectionHeader('Service categories'),
                const SizedBox(height: 10),
                serviceGrid(),
                const SizedBox(height: 18),
                sectionHeader(
                  'Active requests',
                  actionLabel: 'View all',
                  onPressed: openJobs,
                ),
                const SizedBox(height: 10),
                activeRequests(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomerRequestCard extends StatelessWidget {
  final String jobId;
  final RowData job;

  const CustomerRequestCard({
    required this.jobId,
    required this.job,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final status = job['status']?.toString() ?? '';
    final category = job['category']?.toString() ?? 'Service';

    final label = switch (status) {
      'open' => 'Open',
      'booked' => 'Booked',
      'in progress' => 'In progress',
      'awaiting review' => 'Awaiting review',
      'completed' => 'Completed',
      _ => 'Status unavailable',
    };

    final badgeBackground = status == 'awaiting review'
        ? colors.tertiaryContainer
        : status == 'in progress'
            ? colors.secondaryContainer
            : colors.primaryContainer;

    final badgeForeground = status == 'awaiting review'
        ? colors.onTertiaryContainer
        : status == 'in progress'
            ? colors.onSecondaryContainer
            : colors.onPrimaryContainer;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => go(
          context,
          Job(id: jobId),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ServiceCategoryIcon(
                    category: category,
                    size: 44,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job['title']?.toString() ?? 'Service request',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$category - ${job['area'] ?? ''}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBackground,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: badgeForeground,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (status == 'open')
                    _CustomerQuoteCount(
                      key: ValueKey(jobId),
                      jobId: jobId,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                job['amount'] != null
                    ? 'Agreed price: ${servoraMoney(job['amount'])}'
                    : 'Budget: ${servoraMoney(job['budget'])}',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerQuoteCount extends StatefulWidget {
  final String jobId;

  const _CustomerQuoteCount({
    required this.jobId,
    super.key,
  });

  @override
  State<_CustomerQuoteCount> createState() => _CustomerQuoteCountState();
}

class _CustomerQuoteCountState extends State<_CustomerQuoteCount> {
  late final Stream<QuerySnapshot<RowData>> quoteStream;

  @override
  void initState() {
    super.initState();

    quoteStream = db
        .collection('jobs')
        .doc(widget.jobId)
        .collection('quotes')
        .snapshots(includeMetadataChanges: true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return StreamBuilder<QuerySnapshot<RowData>>(
      stream: quoteStream,
      builder: (context, snapshot) {
        String label;

        if (snapshot.hasError) {
          label = 'Quotation count unavailable';
        } else if (!snapshot.hasData) {
          label = 'Loading quotations...';
        } else {
          final count = snapshot.data!.docs.length;
          final noun = count == 1 ? 'quotation' : 'quotations';

          if (snapshot.data!.metadata.isFromCache) {
            label = '$count $noun (saved)';
          } else {
            label =
                count == 0 ? 'Awaiting quotations' : '$count $noun received';
          }
        }

        return Text(
          label,
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        );
      },
    );
  }
}
