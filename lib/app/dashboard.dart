part of '../main.dart';

enum _ServoraTab {
  home,
  requests,
  jobs,
  alerts,
  income,
  account,
}

class Home extends StatefulWidget {
  final RowData member;

  const Home({
    required this.member,
    super.key,
  });

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  _ServoraTab selected = _ServoraTab.home;
  PageStorageBucket navigationStorage = PageStorageBucket();

  bool get provider => widget.member['role'] == 'provider';

  List<_ServoraTab> get tabs => provider
      ? const [
          _ServoraTab.home,
          _ServoraTab.requests,
          _ServoraTab.jobs,
          _ServoraTab.income,
          _ServoraTab.account,
        ]
      : const [
          _ServoraTab.home,
          _ServoraTab.jobs,
          _ServoraTab.alerts,
          _ServoraTab.account,
        ];

  void selectTab(_ServoraTab tab) {
    if (!tabs.contains(tab) || selected == tab) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => selected = tab);
  }

  Widget currentPage() {
    switch (selected) {
      case _ServoraTab.home:
        return provider
            ? ProviderDashboard(member: widget.member)
            : CustomerDashboard(member: widget.member);

      case _ServoraTab.requests:
        return const Inbox();

      case _ServoraTab.jobs:
        return JobList(provider: provider);

      case _ServoraTab.alerts:
        return NotificationCenter(provider: provider);

      case _ServoraTab.income:
        return const ProviderEarnings();

      case _ServoraTab.account:
        return const AccountSettings();
    }
  }

  NavigationDestination destination(_ServoraTab tab) {
    switch (tab) {
      case _ServoraTab.home:
        return const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        );

      case _ServoraTab.requests:
        return const NavigationDestination(
          icon: Icon(Icons.search_outlined),
          selectedIcon: Icon(Icons.search_rounded),
          label: 'Requests',
        );

      case _ServoraTab.jobs:
        return NavigationDestination(
          icon: const Icon(Icons.assignment_outlined),
          selectedIcon: const Icon(Icons.assignment_rounded),
          label: provider ? 'Jobs' : 'My jobs',
        );

      case _ServoraTab.alerts:
        return const NavigationDestination(
          icon: Icon(Icons.notifications_none_rounded),
          selectedIcon: Icon(Icons.notifications_rounded),
          label: 'Alerts',
        );

      case _ServoraTab.income:
        return const NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet_rounded),
          label: 'Income',
        );

      case _ServoraTab.account:
        return const NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Me',
        );
    }
  }

  @override
  void didUpdateWidget(covariant Home oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.member['role'] != widget.member['role']) {
      navigationStorage = PageStorageBucket();
      selected = _ServoraTab.home;
    } else if (!tabs.contains(selected)) {
      selected = _ServoraTab.home;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final currentTabs = tabs;

    final largeText = MediaQuery.textScalerOf(context).scale(12) > 16;

    return PopScope<Object?>(
      canPop: selected == _ServoraTab.home,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && selected != _ServoraTab.home) {
          selectTab(_ServoraTab.home);
        }
      },
      child: Scaffold(
        body: PageStorage(
          bucket: navigationStorage,
          child: KeyedSubtree(
            key: selected == _ServoraTab.home || selected == _ServoraTab.account
                ? PageStorageKey<String>(
                    '${provider ? 'provider' : 'customer'}-${selected.name}',
                  )
                : ValueKey(selected),
            child: currentPage(),
          ),
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(
              top: BorderSide(
                color: colors.outlineVariant.withAlpha(100),
                width: 0.7,
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: currentTabs.indexOf(selected),
            backgroundColor: colors.surface,
            indicatorColor: colors.primaryContainer,
            elevation: 0,
            animationDuration: MediaQuery.of(context).disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 180),
            labelBehavior: largeText
                ? NavigationDestinationLabelBehavior.onlyShowSelected
                : NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (index) {
              selectTab(currentTabs[index]);
            },
            destinations: [
              for (final tab in currentTabs) destination(tab),
            ],
          ),
        ),
      ),
    );
  }
}

void _openMainTab(
  BuildContext context,
  _ServoraTab tab,
  Widget fallback,
) {
  final home = context.findAncestorStateOfType<_HomeState>();

  if (home != null && home.tabs.contains(tab)) {
    home.selectTab(tab);
  } else {
    go(context, fallback);
  }
}

class JobList extends StatefulWidget {
  final bool provider;

  const JobList({
    required this.provider,
    super.key,
  });

  @override
  State<JobList> createState() => _JobListState();
}

class _JobListState extends State<JobList> {
  String statusFilter = 'All jobs';
  String categoryFilter = 'All services';
  String search = '';
  bool newestFirst = true;

  late final Stream<QuerySnapshot<RowData>> jobStream;

  final statusOptions = const [
    'All jobs',
    'Active',
    'Completed',
    'Open',
    'Booked',
    'In progress',
    'Awaiting review',
  ];

  @override
  void initState() {
    super.initState();

    jobStream = db
        .collection('jobs')
        .where(
          widget.provider ? 'assigned' : 'owner',
          isEqualTo: uid,
        )
        .snapshots();
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

  String activityDate(
    BuildContext context,
    RowData job,
  ) {
    final fields = {
      'reviewedAt': 'Reviewed',
      'finished': 'Work submitted',
      'startedAt': 'Started',
      'bookedAt': 'Booked',
      'created': 'Posted',
    };

    for (final entry in fields.entries) {
      final value = job[entry.key];

      if (value is num && value.isFinite && value > 0) {
        return '${entry.value}: '
            '${servoraDateLabel(context, value)}';
      }
    }

    return 'Date not recorded';
  }

  bool matchesFilters(RowData job) {
    final status = job['status'].toString();

    if (statusFilter == 'Active' && status == 'completed') {
      return false;
    }

    if (statusFilter != 'All jobs' &&
        statusFilter != 'Active' &&
        status != statusFilter.toLowerCase()) {
      return false;
    }

    if (categoryFilter != 'All services' && job['category'] != categoryFilter) {
      return false;
    }

    final text = [
      job['title'],
      job['description'],
      job['category'],
      job['area'],
      job['name'],
      job['providerName'],
    ].whereType<String>().join(' ').toLowerCase();

    return text.contains(search.trim().toLowerCase());
  }

  Color statusColor(String status) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return switch (status) {
      'completed' => dark ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
      'awaiting review' =>
        dark ? const Color(0xFFFCD34D) : const Color(0xFFB45309),
      'in progress' => dark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
      'booked' => dark ? const Color(0xFF80D8C6) : const Color(0xFF007D70),
      _ => Theme.of(context).colorScheme.primary,
    };
  }

  Widget summaryCard(String title, int count) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final icon = switch (title) {
      'Active' => Icons.pending_actions_rounded,
      'Completed' => Icons.task_alt_rounded,
      _ => Icons.assignment_outlined,
    };

    return Expanded(
      child: Card(
        margin: const EdgeInsets.all(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 16,
          ),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: colors.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$count',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget historyCard(String id, RowData job) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final status = job['status'].toString();
    final color = statusColor(status);
    final category = job['category']?.toString() ?? 'Service';

    final statusLabel = switch (status) {
      'open' => 'Open',
      'booked' => 'Booked',
      'in progress' => 'In progress',
      'awaiting review' => 'Awaiting review',
      'completed' => 'Completed',
      _ => 'Unknown status',
    };

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ServiceCategoryIcon(
                  category: category,
                  size: 58,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job['title']?.toString() ?? 'Service request',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$category - ${job['area'] ?? ''}',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (widget.provider)
              Text(
                'Customer: ${job['name'] ?? 'Unavailable'}',
                style: theme.textTheme.bodyMedium,
              )
            else if (job['providerName'] != null)
              Text(
                'Provider: ${job['providerName']}',
                style: theme.textTheme.bodyMedium,
              ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withAlpha(130),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job['amount'] != null ? 'Agreed price' : 'Customer budget',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    servoraMoney(job['amount'] ?? job['budget']),
                    style: theme.textTheme.titleLarge
                        ?.copyWith(color: colors.primary),
                  ),
                ],
              ),
            ),
            if (status == 'completed') ...[
              const SizedBox(height: 14),
              if (job['stars'] != null)
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFE9AA26),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${job['stars']}/5 customer rating",
                    ),
                  ],
                ),
              if (widget.provider && job['serviceCharge'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    "Service charge: ${servoraMoney(job['serviceCharge'])}",
                  ),
                ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  color: colors.onSurfaceVariant,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    activityDate(context, job),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => go(
                context,
                Job(id: id),
              ),
              icon: const Icon(
                Icons.arrow_forward_rounded,
              ),
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
      stream: jobStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return page('My jobs', [
            const Text('Unable to load your job history.'),
          ]);
        }

        if (!snapshot.hasData) {
          return page('My jobs', [
            const LinearProgressIndicator(),
          ]);
        }

        final jobs = snapshot.data!.docs.toList();

        final completed = jobs
            .where(
              (job) => job.data()['status'] == 'completed',
            )
            .length;

        final active = jobs.length - completed;

        final visible = jobs
            .where(
              (job) => matchesFilters(job.data()),
            )
            .toList();

        visible.sort((a, b) {
          final result =
              latestActivity(b.data()).compareTo(latestActivity(a.data()));

          if (result == 0) {
            return a.id.compareTo(b.id);
          }

          return newestFirst ? result : -result;
        });

        return page('My jobs', [
          Text(
            widget.provider ? 'Your service history' : 'Your request history',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Row(
            children: [
              summaryCard('Total', jobs.length),
              summaryCard('Active', active),
              summaryCard('Completed', completed),
            ],
          ),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search jobs',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() => search = value);
            },
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in statusOptions)
                if (!widget.provider || option != 'Open')
                  ChoiceChip(
                    label: Text(option),
                    selected: statusFilter == option,
                    onSelected: (_) {
                      setState(() {
                        statusFilter = option;
                      });
                    },
                  ),
            ],
          ),
          select(
            'Service category',
            categoryFilter,
            ['All services', ...categories],
            (value) {
              setState(() => categoryFilter = value);
            },
          ),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                newestFirst = !newestFirst;
              });
            },
            icon: const Icon(Icons.sort),
            label: Text(
              newestFirst ? 'Newest activity first' : 'Oldest activity first',
            ),
          ),
          Text(
            '${visible.length} matching jobs',
          ),
          if (visible.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.history,
                      size: 48,
                      color: ink,
                    ),
                    SizedBox(height: 12),
                    Text('No matching jobs found.'),
                  ],
                ),
              ),
            ),
          for (final job in visible) historyCard(job.id, job.data()),
        ]);
      },
    );
  }
}

class Inbox extends StatelessWidget {
  const Inbox({super.key});

  Widget emptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    String? button,
    VoidCallback? onPressed,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
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
                icon,
                color: colors.onPrimaryContainer,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurfaceVariant,
              ),
            ),
            if (button != null) ...[
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onPressed,
                child: Text(button),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget requestCard(
    BuildContext context,
    QueryDocumentSnapshot<RowData> request,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final job = request.data();

    final category = job['category']?.toString() ?? 'Service';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ServiceCategoryIcon(
                  category: category,
                  size: 60,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job['title']?.toString() ?? 'Service request',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        category,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: colors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    job['area']?.toString() ?? 'Location unavailable',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (job['description'] != null)
              Text(
                job['description'].toString(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer budget',
                    style: TextStyle(
                      color: colors.onPrimaryContainer,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    servoraMoney(job['budget']),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => go(
                context,
                Job(id: request.id),
              ),
              icon: const Icon(
                Icons.arrow_forward_rounded,
              ),
              label: const Text('View request'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return StreamBuilder<DocumentSnapshot<RowData>>(
      stream: db.collection('providers').doc(uid).snapshots(
            includeMetadataChanges: true,
          ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return page('Available requests', [
            emptyState(
              context,
              icon: Icons.cloud_off_outlined,
              title: 'Unable to load services',
              description: 'Check your connection and try again.',
            ),
          ]);
        }

        if (!snapshot.hasData) {
          return page('Available requests', [
            const LinearProgressIndicator(),
          ]);
        }

        final profile = snapshot.data!.data();

        if (profile == null) {
          return page('Available requests', [
            emptyState(
              context,
              icon: Icons.home_repair_service_outlined,
              title: 'Set up your services',
              description:
                  'Create a service profile to discover relevant requests.',
              button: 'My services',
              onPressed: () => go(
                context,
                const MyServices(),
              ),
            ),
          ]);
        }

        final activeCategories = activeServiceCategories(profile);

        if (activeCategories.isEmpty) {
          return page('Available requests', [
            emptyState(
              context,
              icon: Icons.pause_circle_outline,
              title: 'Your services are paused',
              description:
                  'Enable at least one service to receive relevant requests.',
              button: 'Manage my services',
              onPressed: () => go(
                context,
                const MyServices(),
              ),
            ),
          ]);
        }

        return page('Available requests', [
          Text(
            'Find your next job.',
            style: theme.textTheme.headlineMedium,
          ),
          Text(
            'Discover service requests that match your available services.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          if (snapshot.data!.metadata.isFromCache)
            const Text(
              'Showing saved service profile data.',
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your available services',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final category in activeCategories)
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
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot<RowData>>(
            stream: db
                .collection('jobs')
                .where('status', isEqualTo: 'open')
                .where(
                  'category',
                  whereIn: activeCategories,
                )
                .snapshots(includeMetadataChanges: true),
            builder: (context, requestSnapshot) {
              if (requestSnapshot.hasError) {
                return emptyState(
                  context,
                  icon: Icons.cloud_off_outlined,
                  title: 'Requests unavailable',
                  description: 'Unable to load service requests.',
                );
              }

              if (!requestSnapshot.hasData) {
                return const LinearProgressIndicator();
              }

              final requests = requestSnapshot.data!.docs.toList();

              num created(RowData data) {
                final value = data['created'];
                return value is num && value.isFinite ? value : 0;
              }

              requests.sort((a, b) {
                final result = created(b.data()).compareTo(created(a.data()));

                return result == 0 ? a.id.compareTo(b.id) : result;
              });

              final cached = requestSnapshot.data!.metadata.isFromCache;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${requests.length} matching requests',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 14),
                  if (cached)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Showing saved requests.',
                      ),
                    ),
                  if (requests.isEmpty)
                    emptyState(
                      context,
                      icon: Icons.work_outline_rounded,
                      title: 'No matching requests',
                      description: cached
                          ? 'No requests are available in saved data.'
                          : 'New requests matching your services will appear here.',
                    ),
                  for (final request in requests) requestCard(context, request),
                ],
              );
            },
          ),
        ]);
      },
    );
  }
}

class MyQuotations extends StatelessWidget {
  const MyQuotations({super.key});

  @override
  Widget build(BuildContext context) {
    return page('My quotations', [
      StreamBuilder<QuerySnapshot<RowData>>(
        stream: db
            .collectionGroup('quotes')
            .where('provider', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('${snapshot.error}');
          }

          if (!snapshot.hasData) {
            return const LinearProgressIndicator();
          }

          final quotations = snapshot.data!.docs.toList();

          quotations.sort(
            (a, b) => (b.data()['created'] as num)
                .compareTo(a.data()['created'] as num),
          );

          if (quotations.isEmpty) {
            return const Text(
              'You have not submitted any quotations yet.',
            );
          }

          return Column(
            children: [
              for (final quotation in quotations)
                QuotationCard(
                  key: ValueKey(quotation.reference.path),
                  quotation: quotation,
                ),
            ],
          );
        },
      ),
    ]);
  }
}

class QuotationCard extends StatefulWidget {
  final QueryDocumentSnapshot<RowData> quotation;

  const QuotationCard({
    required this.quotation,
    super.key,
  });

  @override
  State<QuotationCard> createState() => _QuotationCardState();
}

class _QuotationCardState extends State<QuotationCard> {
  bool deleting = false;

  Future<void> deleteQuotation() async {
    if (deleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete quotation?'),
          content: const Text(
            'Are you sure you want to delete this quotation? '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    setState(() => deleting = true);

    try {
      final quoteRef = widget.quotation.reference;
      final jobRef = quoteRef.parent.parent;

      if (jobRef == null) {
        throw Exception('Service request not found.');
      }

      await db.runTransaction((transaction) async {
        final jobSnapshot = await transaction.get(jobRef);
        final quoteSnapshot = await transaction.get(quoteRef);

        final job = jobSnapshot.data();
        final quote = quoteSnapshot.data();

        if (job == null) {
          throw Exception('Service request not found.');
        }

        if (quote == null) {
          throw Exception('Quotation no longer exists.');
        }

        if (quote['provider'] != uid) {
          throw Exception(
            'You can only delete your own quotations.',
          );
        }

        if (job['status'] != 'open') {
          throw Exception(
            'This quotation cannot be deleted after booking.',
          );
        }

        transaction.delete(quoteRef);
      });

      if (messenger.mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Quotation deleted successfully.'),
          ),
        );
      }
    } on FirebaseException catch (e) {
      if (messenger.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              e.code == 'permission-denied'
                  ? 'This quotation cannot be deleted.'
                  : e.message ?? 'Unable to delete quotation.',
            ),
          ),
        );
      }
    } catch (e) {
      if (messenger.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => deleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quote = widget.quotation.data();
    final jobRef = widget.quotation.reference.parent.parent;

    if (jobRef == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<DocumentSnapshot<RowData>>(
      stream: jobRef.snapshots(),
      builder: (context, snapshot) {
        final job = snapshot.data?.data();

        final isOpen = job?['status'] == 'open';
        final isAccepted = job?['assigned'] == uid;

        String status = 'Request unavailable';

        if (job != null) {
          if (isOpen) {
            status = 'Pending';
          } else if (isAccepted) {
            status = 'Accepted';
          } else {
            status = 'Not selected';
          }
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          status = 'Loading';
        }

        final statusColor = isAccepted
            ? Colors.green
            : isOpen
                ? Colors.orange.shade800
                : Colors.grey.shade700;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job?['title'] ?? 'Submitted quotation',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  servoraMoney(quote['amount']),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Completion time: ${quote['hours']} hours',
                ),
                const SizedBox(height: 8),
                Text('${quote['note']}'),
                const SizedBox(height: 8),
                Text(
                  'Submitted: ${servoraDateLabel(context, quote['created'])}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (quote['updatedAt'] != null)
                  Text(
                    'Last updated: ${servoraDateLabel(context, quote['updatedAt'])}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(height: 10),
                Chip(
                  label: Text(
                    status,
                    style: TextStyle(color: statusColor),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (job != null)
                      OutlinedButton(
                        onPressed: deleting
                            ? null
                            : () => go(
                                  context,
                                  Job(id: jobRef.id),
                                ),
                        child: const Text('View request'),
                      ),
                    if (isOpen)
                      ProviderQuotationGate(
                        category: job?['category'],
                        child: FilledButton(
                          onPressed: deleting
                              ? null
                              : () => go(
                                    context,
                                    Editor(
                                      mode: 'quote',
                                      jobId: jobRef.id,
                                      initial: quote,
                                    ),
                                  ),
                          child: const Text('Edit quotation'),
                        ),
                      ),
                    if (isOpen)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(
                            color: Colors.red.shade700,
                          ),
                        ),
                        onPressed: deleting ? null : deleteQuotation,
                        icon: const Icon(
                          Icons.delete_outline,
                        ),
                        label: Text(
                          deleting ? 'Deleting...' : 'Delete quotation',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
