part of '../../main.dart';

class NotificationCenter extends StatefulWidget {
  final bool provider;

  const NotificationCenter({
    required this.provider,
    super.key,
  });

  @override
  State<NotificationCenter> createState() => _NotificationCenterState();
}

class _NotificationCenterState extends State<NotificationCenter> {
  late final String userId;

  late Future<List<bool>> preferences;

  late Stream<QuerySnapshot<RowData>> jobsStream;

  late final Stream<DocumentSnapshot<RowData>> profileStream;

  Stream<QuerySnapshot<RowData>>? requestStream;

  String requestCategoriesKey = '';

  final quotationStreams = <String, Stream<QuerySnapshot<RowData>>>{};

  bool get provider => widget.provider;

  @override
  void initState() {
    super.initState();

    userId = uid;

    preferences = loadPreferences();

    jobsStream = createJobsStream();

    profileStream = db
        .collection('providers')
        .doc(userId)
        .snapshots(includeMetadataChanges: true);
  }

  @override
  void didUpdateWidget(covariant NotificationCenter oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.provider != widget.provider) {
      jobsStream = createJobsStream();
      quotationStreams.clear();
      requestStream = null;
      requestCategoriesKey = '';
    }
  }

  Future<List<bool>> loadPreferences() {
    return Future.wait<bool>([
      appPreferences.notificationEnabled(
        userId,
        'quotations',
      ),
      appPreferences.notificationEnabled(
        userId,
        'requests',
      ),
      appPreferences.notificationEnabled(
        userId,
        'jobUpdates',
      ),
    ]);
  }

  Stream<QuerySnapshot<RowData>> createJobsStream() {
    return db
        .collection('jobs')
        .where(
          provider ? 'assigned' : 'owner',
          isEqualTo: userId,
        )
        .snapshots(includeMetadataChanges: true);
  }

  Future<void> openPreferences() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => NotificationSettings(
          provider: provider,
        ),
      ),
    );

    if (!mounted) return;

    setState(() {
      preferences = loadPreferences();
    });
  }

  double timestampValue(dynamic value) {
    if (value is num && value.isFinite) {
      return value.toDouble();
    }

    return 0;
  }

  double jobTimestamp(RowData job) {
    return timestampValue(
      job['reviewedAt'] ??
          job['finished'] ??
          job['startedAt'] ??
          job['bookedAt'] ??
          job['created'],
    );
  }

  String dateLabel(dynamic value) {
    return servoraDateLabel(context, value);
  }

  Color successColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF86EFAC)
        : const Color(0xFF15803D);
  }

  Color warningColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFCD34D)
        : const Color(0xFFB45309);
  }

  Widget sectionTitle(
    String title,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(
        top: 8,
        bottom: 2,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleLarge,
            ),
          ),
        ],
      ),
    );
  }

  Widget activityHeader() {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF008779),
            Color(0xFF005D53),
            Color(0xFF003F38),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SERVORA ACTIVITY',
                      style: TextStyle(
                        color: Color(0xFFD9F5EC),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Activity centre',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            provider
                ? 'Keep track of new opportunities, bookings and reviews.'
                : 'Keep track of quotations, bookings and service updates.',
            style: const TextStyle(
              color: Color(0xFFD9F5EC),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(
                color: Colors.white.withAlpha(130),
              ),
            ),
            onPressed: openPreferences,
            icon: const Icon(
              Icons.settings_outlined,
              size: 20,
            ),
            label: const Text('Notification preferences'),
          ),
        ],
      ),
    );
  }

  Widget messageCard(
    String title,
    String description,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: colors.onPrimaryContainer,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget cachedNotice() {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 18,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing saved activity. Updates may be delayed.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget activityCard({
    required String title,
    required String description,
    required IconData icon,
    required String jobId,
    String date = '',
    Color? color,
    String? serviceCategory,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final accent = color ?? colors.primary;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => go(
          context,
          Job(id: jobId),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (serviceCategory != null)
                ServiceCategoryIcon(
                  category: serviceCategory,
                  size: 48,
                )
              else
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: accent,
                    size: 24,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (date.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.schedule_outlined,
                            size: 14,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              date,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget quotationActivity(
    String jobId,
    RowData job,
  ) {
    final stream = quotationStreams.putIfAbsent(
      jobId,
      () => db
          .collection('jobs')
          .doc(jobId)
          .collection('quotes')
          .snapshots(includeMetadataChanges: true),
    );

    return StreamBuilder<QuerySnapshot<RowData>>(
      key: ValueKey('notification-quotes-$jobId'),
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(10),
            child: Text('Unable to load quotation updates.'),
          );
        }

        if (!snapshot.hasData) {
          return const LinearProgressIndicator();
        }

        final quotations = snapshot.data!.docs.toList();

        quotations.sort((a, b) {
          final aTime = timestampValue(
            a.data()['updatedAt'] ?? a.data()['created'],
          );

          final bTime = timestampValue(
            b.data()['updatedAt'] ?? b.data()['created'],
          );

          final order = bTime.compareTo(aTime);

          return order == 0 ? a.id.compareTo(b.id) : order;
        });

        if (quotations.isEmpty) {
          return Card(
            child: ListTile(
              leading: Icon(
                Icons.hourglass_empty_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                job['title']?.toString() ?? 'Service request',
              ),
              subtitle: Text(
                snapshot.data!.metadata.isFromCache
                    ? 'No saved quotations.'
                    : 'Waiting for quotations.',
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
              ),
              onTap: () => go(
                context,
                Job(id: jobId),
              ),
            ),
          );
        }

        return Column(
          children: [
            if (snapshot.data!.metadata.isFromCache) cachedNotice(),
            for (final quotation in quotations)
              activityCard(
                title: quotation.data()['updatedAt'] != null
                    ? 'Quotation updated'
                    : 'Quotation received',
                description: '${quotation.data()['name']} submitted '
                    'a quotation of '
                    '${servoraMoney(quotation.data()['amount'])} '
                    'for ${job['title']}.',
                icon: Icons.request_quote_outlined,
                jobId: jobId,
                date: dateLabel(
                  quotation.data()['updatedAt'] ?? quotation.data()['created'],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget jobActivity(
    String jobId,
    RowData job,
  ) {
    final status = job['status'];

    final title = job['title']?.toString() ?? 'Service request';

    switch (status) {
      case 'open':
        return provider
            ? const SizedBox.shrink()
            : quotationActivity(jobId, job);

      case 'booked':
        return activityCard(
          title: provider ? 'Quotation accepted' : 'Booking confirmed',
          description: provider
              ? 'Your quotation for $title was accepted.'
              : '$title has been booked with '
                  '${job['providerName']}.',
          icon: Icons.check_circle_outline,
          jobId: jobId,
          date: dateLabel(job['bookedAt']),
          color: successColor(context),
        );

      case 'in progress':
        return activityCard(
          title: 'Job in progress',
          description: '$title is currently in progress.',
          icon: Icons.build_outlined,
          jobId: jobId,
          date: dateLabel(job['startedAt']),
        );

      case 'awaiting review':
        return activityCard(
          title:
              provider ? 'Awaiting customer review' : 'Work ready for review',
          description: provider
              ? '$title has been submitted for review.'
              : 'Review the completed work for $title.',
          icon: Icons.rate_review_outlined,
          jobId: jobId,
          date: dateLabel(job['finished']),
          color: warningColor(context),
        );

      case 'completed':
        return activityCard(
          title: provider ? 'Customer review received' : 'Job completed',
          description: provider
              ? '$title received ${job['stars']}/5 stars.'
              : '$title has been successfully completed.',
          icon: Icons.task_alt,
          jobId: jobId,
          date: dateLabel(job['reviewedAt']),
          color: successColor(context),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget availableRequestActivity() {
    return StreamBuilder<DocumentSnapshot<RowData>>(
      stream: profileStream,
      builder: (context, profileSnapshot) {
        if (profileSnapshot.hasError) {
          return messageCard(
            'Service profile unavailable',
            'Unable to load your service profile.',
            Icons.cloud_off_outlined,
          );
        }

        if (!profileSnapshot.hasData) {
          return const LinearProgressIndicator();
        }

        final profile = profileSnapshot.data!.data();

        if (profile == null) {
          return messageCard(
            'No service profile',
            'Register a service to discover matching requests.',
            Icons.home_repair_service_outlined,
          );
        }

        final activeCategories = activeServiceCategories(profile)..sort();

        if (activeCategories.isEmpty) {
          requestStream = null;
          requestCategoriesKey = '';

          return messageCard(
            'Services paused',
            'Enable availability to receive matching service requests.',
            Icons.pause_circle_outline,
          );
        }

        final categoriesKey = activeCategories.join('|');

        if (requestStream == null || requestCategoriesKey != categoriesKey) {
          requestCategoriesKey = categoriesKey;

          requestStream = db
              .collection('jobs')
              .where('status', isEqualTo: 'open')
              .where('category', whereIn: activeCategories)
              .snapshots(includeMetadataChanges: true);
        }

        return StreamBuilder<QuerySnapshot<RowData>>(
          key: ValueKey(categoriesKey),
          stream: requestStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return messageCard(
                'Requests unavailable',
                'Unable to load matching service requests.',
                Icons.cloud_off_outlined,
              );
            }

            if (!snapshot.hasData) {
              return const LinearProgressIndicator();
            }

            final requests = snapshot.data!.docs.toList();

            requests.sort((a, b) {
              final order = timestampValue(
                b.data()['created'],
              ).compareTo(
                timestampValue(a.data()['created']),
              );

              return order == 0 ? a.id.compareTo(b.id) : order;
            });

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (snapshot.data!.metadata.isFromCache ||
                    profileSnapshot.data!.metadata.isFromCache)
                  cachedNotice(),
                if (requests.isEmpty)
                  messageCard(
                    'No matching requests',
                    'Available requests for your services will appear here.',
                    Icons.work_outline,
                  ),
                if (requests.length > 10)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Showing latest 10 of ${requests.length} requests.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                for (final request in requests.take(10))
                  activityCard(
                    title: 'Available service request',
                    description: '${request.data()['title']}\n'
                        'Budget ${servoraMoney(request.data()['budget'])}',
                    icon: Icons.work_outline,
                    jobId: request.id,
                    serviceCategory: request.data()['category']?.toString(),
                    date: dateLabel(
                      request.data()['created'],
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget jobUpdates({
    required bool showQuotations,
    required bool showJobUpdates,
  }) {
    return StreamBuilder<QuerySnapshot<RowData>>(
      key: ValueKey(provider),
      stream: jobsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return messageCard(
            'Activity unavailable',
            'Unable to load your job updates.',
            Icons.cloud_off_outlined,
          );
        }

        if (!snapshot.hasData) {
          return const LinearProgressIndicator();
        }

        final jobs = snapshot.data!.docs.where((doc) {
          final status = doc.data()['status'];

          if (status == 'open') {
            return !provider && showQuotations;
          }

          return showJobUpdates &&
              const [
                'booked',
                'in progress',
                'awaiting review',
                'completed',
              ].contains(status);
        }).toList();

        jobs.sort((a, b) {
          final order =
              jobTimestamp(b.data()).compareTo(jobTimestamp(a.data()));

          return order == 0 ? a.id.compareTo(b.id) : order;
        });

        final visible = jobs.take(30).toList();

        final openJobIds = visible
            .where((doc) => doc.data()['status'] == 'open')
            .map((doc) => doc.id)
            .toSet();

        quotationStreams.removeWhere(
          (id, _) => !openJobIds.contains(id),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (snapshot.data!.metadata.isFromCache) cachedNotice(),
            if (jobs.isEmpty)
              messageCard(
                'No recent activity',
                'Your enabled quotation and job updates will appear here.',
                Icons.notifications_none_rounded,
              ),
            if (jobs.length > 30)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Showing updates for the latest 30 of '
                  '${jobs.length} matching jobs.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            for (final job in visible)
              KeyedSubtree(
                key: ValueKey(job.id),
                child: jobActivity(
                  job.id,
                  job.data(),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser?.uid != userId) {
      return page('Notifications', [
        const Text('Sign in to view your activity.'),
      ]);
    }

    return FutureBuilder<List<bool>>(
      future: preferences,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return page('Notifications', [
            activityHeader(),
            messageCard(
              'Preferences unavailable',
              'Unable to load notification preferences.',
              Icons.settings_outlined,
            ),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  preferences = loadPreferences();
                });
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ]);
        }

        if (snapshot.connectionState != ConnectionState.done ||
            !snapshot.hasData) {
          return page('Notifications', [
            const LinearProgressIndicator(),
          ]);
        }

        final values = snapshot.data!;

        final showQuotations = !provider && values[0];

        final showRequests = provider && values[1];

        final showJobUpdates = values[2];

        final anyEnabled = showQuotations || showRequests || showJobUpdates;

        if (!showQuotations) {
          quotationStreams.clear();
        }

        if (!showRequests) {
          requestStream = null;
          requestCategoriesKey = '';
        }

        return page('Notifications', [
          activityHeader(),
          if (!anyEnabled)
            messageCard(
              'Notifications paused',
              'Enable your preferred activity categories '
                  'in Notification preferences.',
              Icons.notifications_off_outlined,
            ),
          if (showRequests) ...[
            sectionTitle(
              'Available requests',
              Icons.work_outline,
            ),
            availableRequestActivity(),
          ],
          if (showQuotations || showJobUpdates) ...[
            sectionTitle(
              showQuotations && showJobUpdates
                  ? 'Quotations and job updates'
                  : showQuotations
                      ? 'Quotation updates'
                      : 'Job updates',
              Icons.history_rounded,
            ),
            jobUpdates(
              showQuotations: showQuotations,
              showJobUpdates: showJobUpdates,
            ),
          ],
          if (anyEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 12,
              ),
              child: Text(
                'Activity reflects the latest recorded job status '
                'and quotations. These are in-app updates, '
                'not background push notifications.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ]);
      },
    );
  }
}
