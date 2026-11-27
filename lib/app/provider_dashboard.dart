part of '../main.dart';

class ProviderDashboard extends StatefulWidget {
  final RowData member;

  const ProviderDashboard({
    required this.member,
    super.key,
  });

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> {
  late final Stream<DocumentSnapshot<RowData>> profileStream;
  late final Stream<QuerySnapshot<RowData>> jobStream;

  @override
  void initState() {
    super.initState();

    profileStream = db
        .collection('providers')
        .doc(uid)
        .snapshots(includeMetadataChanges: true);

    jobStream = db
        .collection('jobs')
        .where('assigned', isEqualTo: uid)
        .snapshots(includeMetadataChanges: true);
  }

  String get providerName {
    final name = widget.member['name']?.toString().trim() ?? '';

    return name.isEmpty ? 'Professional' : name.split(RegExp(r'\s+')).first;
  }

  String numberLabel(dynamic value) {
    return value is num && value.isFinite ? value.toString() : '-';
  }

  Widget sectionHeader(
    String title, {
    String? button,
    VoidCallback? onTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        if (button != null)
          TextButton(
            onPressed: onTap,
            child: Text(button),
          ),
      ],
    );
  }

  Widget metric(
    IconData icon,
    String value,
    String label,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget responsiveGrid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(12) / 12;

        final columns = constraints.maxWidth < 280 || scale > 1.4 ? 1 : 2;

        const spacing = 8.0;

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

  Widget rankCard(RowData profile) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final rank = profile['level']?.toString() ?? 'Unranked';
    final dark = theme.brightness == Brightness.dark;

    final rankColor = switch (rank) {
      'Gold' => dark ? const Color(0xFFFFD66B) : const Color(0xFF956A00),
      'Silver' => dark ? const Color(0xFFC6D5DF) : const Color(0xFF526A7A),
      'Bronze' => dark ? const Color(0xFFF0B78E) : const Color(0xFF96592D),
      _ => colors.primary,
    };

    final rawPoints = profile['points'];
    final points = rawPoints is num && rawPoints.isFinite && rawPoints >= 0
        ? rawPoints.toInt()
        : null;

    final progress = points == null
        ? 0.0
        : points >= 120
            ? 1.0
            : points < 50
                ? points / 50
                : (points - 50) / 70;

    final progressLabel = points == null
        ? 'Membership progress unavailable'
        : points >= 120
            ? 'Highest membership rank achieved'
            : points < 50
                ? '${50 - points} points to Silver'
                : '${120 - points} points to Gold';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: rankColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    color: rankColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$rank membership',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (points != null)
              LinearProgressIndicator(
                value: progress,
                color: rankColor,
                minHeight: 7,
                borderRadius: BorderRadius.circular(10),
              ),
            if (points != null) const SizedBox(height: 8),
            Text(
              progressLabel,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget profileOverview() {
    return StreamBuilder<DocumentSnapshot<RowData>>(
      stream: profileStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text(
            'Unable to load your service profile.',
          );
        }

        if (!snapshot.hasData) {
          return const LinearProgressIndicator();
        }

        final profile = snapshot.data!.data();

        if (profile == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Complete your service profile to get started.',
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () => go(
                      context,
                      const MyServices(),
                    ),
                    child: const Text('Set up my services'),
                  ),
                ],
              ),
            ),
          );
        }

        final colors = Theme.of(context).colorScheme;
        final jobs = profile['jobs'];
        final stars = profile['stars'];

        final rating = jobs is num &&
                jobs.isFinite &&
                jobs > 0 &&
                stars is num &&
                stars.isFinite
            ? (stars / jobs).toStringAsFixed(1)
            : 'Not rated';

        final services = activeServiceCategories(profile);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (snapshot.data!.metadata.isFromCache)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('Showing saved profile data.'),
              ),
            rankCard(profile),
            const SizedBox(height: 8),
            responsiveGrid([
              metric(
                Icons.star_rounded,
                rating,
                'Customer rating',
              ),
              metric(
                Icons.task_alt_rounded,
                numberLabel(jobs),
                'Completed jobs',
              ),
              metric(
                Icons.bolt_rounded,
                numberLabel(profile['points']),
                'Reward points',
              ),
              metric(
                Icons.percent_rounded,
                '${numberLabel(profile['fee'])}%',
                'Service charge',
              ),
            ]),
            const SizedBox(height: 14),
            sectionHeader('Available services'),
            const SizedBox(height: 6),
            if (services.isEmpty)
              const Text(
                'No services are currently available.',
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final category in services)
                    Chip(
                      backgroundColor: colors.primaryContainer,
                      avatar: ServiceCategoryIcon(
                        category: category,
                        size: 28,
                      ),
                      label: Text(
                        category,
                        style: TextStyle(
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget earningsCard(
    List<QueryDocumentSnapshot<RowData>> jobs,
    bool cached,
  ) {
    final theme = Theme.of(context);

    const offset = Duration(hours: 5, minutes: 30);

    final now = DateTime.now().toUtc().add(offset);

    final start = DateTime.utc(now.year, now.month)
        .subtract(offset)
        .millisecondsSinceEpoch;

    final end = DateTime.utc(now.year, now.month + 1)
        .subtract(offset)
        .millisecondsSinceEpoch;

    double net = 0;
    bool incomplete = false;

    for (final doc in jobs) {
      final job = doc.data();

      if (job['status'] != 'completed') continue;

      final date = job['reviewedAt'] ?? job['finished'];

      if (date is! num || !date.isFinite || date <= 0) {
        incomplete = true;
        continue;
      }

      if (date < start || date >= end) continue;

      final amount = job['amount'];
      final charge = job['serviceCharge'];

      if (amount is num &&
          charge is num &&
          amount.isFinite &&
          charge.isFinite &&
          amount >= 0 &&
          charge >= 0 &&
          charge <= amount) {
        net += (amount - charge).toDouble();
      } else {
        incomplete = true;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: Color(0xFFD9F5EC),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'This month',
                  style: TextStyle(
                    color: Color(0xFFD9F5EC),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            servoraMoney(net),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Recorded net earnings',
            style: TextStyle(
              color: Color(0xFFD9F5EC),
            ),
          ),
          if (cached || incomplete) ...[
            const SizedBox(height: 10),
            Text(
              [
                if (cached) 'Saved data.',
                if (incomplete) 'Some records could not be included.',
              ].join(' '),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  num activity(RowData job) {
    for (final key in [
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

  Widget businessAction(
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    final colors = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: colors.onPrimaryContainer, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colors.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }

  void openJobs() {
    _openMainTab(context, _ServoraTab.jobs, const JobList(provider: true));
  }

  Widget activeJobs(
    List<QueryDocumentSnapshot<RowData>> jobs,
    bool cached,
  ) {
    final active = jobs.where((doc) {
      return const [
        'booked',
        'in progress',
        'awaiting review',
      ].contains(doc.data()['status']);
    }).toList();

    active.sort((a, b) {
      final result = activity(b.data()).compareTo(activity(a.data()));

      return result == 0 ? a.id.compareTo(b.id) : result;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sectionHeader(
          'Active jobs',
          button: 'View all',
          onTap: openJobs,
        ),
        const SizedBox(height: 10),
        if (cached)
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text('Showing saved job data.'),
          ),
        if (active.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(
                    Icons.work_outline_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cached
                          ? 'No active jobs in saved data.'
                          : 'No active jobs right now.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        for (final doc in active.take(2))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: CustomerRequestCard(
              key: ValueKey(doc.id),
              jobId: doc.id,
              job: doc.data(),
            ),
          ),
        if (active.length > 2)
          Text(
            'Showing 2 of ${active.length} active jobs',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }

  Widget dashboardContent(
    AsyncSnapshot<QuerySnapshot<RowData>> snapshot,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final jobs = snapshot.data?.docs;

    final cached = snapshot.data?.metadata.isFromCache ?? false;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        Text(
          'Hello, $providerName!',
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Manage your service business.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        if (snapshot.hasError)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Unable to load earnings and jobs.',
              ),
            ),
          )
        else if (jobs == null)
          const LinearProgressIndicator()
        else
          earningsCard(jobs, cached),
        const SizedBox(height: 16),
        sectionHeader('Your performance'),
        const SizedBox(height: 8),
        profileOverview(),
        const SizedBox(height: 16),
        ServoraHeroBanner(
          provider: true,
          compact: true,
          title: 'Find new service requests',
          description: 'Discover work that matches your services.',
          buttonLabel: 'Find requests',
          onPressed: () =>
              _openMainTab(context, _ServoraTab.requests, const Inbox()),
        ),
        const SizedBox(height: 16),
        sectionHeader('Manage your business'),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              businessAction(
                Icons.home_repair_service_outlined,
                'My services',
                () => go(context, const MyServices()),
              ),
              const Divider(height: 1, indent: 66, endIndent: 14),
              businessAction(
                Icons.request_quote_outlined,
                'My quotations',
                () => go(context, const MyQuotations()),
              ),
              const Divider(height: 1, indent: 66, endIndent: 14),
              businessAction(
                Icons.photo_library_outlined,
                'My portfolio',
                () => go(context, Profile(id: uid)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (snapshot.hasError)
          OutlinedButton(
            onPressed: openJobs,
            child: const Text('Open my jobs'),
          )
        else if (jobs != null)
          activeJobs(jobs, cached),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: () => go(
              context,
              const NotificationCenter(provider: true),
            ),
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
            child: StreamBuilder<QuerySnapshot<RowData>>(
              stream: jobStream,
              builder: (context, snapshot) {
                return dashboardContent(snapshot);
              },
            ),
          ),
        ),
      ),
    );
  }
}
