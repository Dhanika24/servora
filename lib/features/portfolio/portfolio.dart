part of '../../main.dart';

class Profile extends StatelessWidget {
  final String id;

  const Profile({
    required this.id,
    super.key,
  });

  Color rankColor(
    BuildContext context,
    String rank,
  ) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return switch (rank) {
      'Gold' => dark ? const Color(0xFFFFD66B) : const Color(0xFF956A00),
      'Silver' => dark ? const Color(0xFFC6D5DF) : const Color(0xFF526A7A),
      'Bronze' => dark ? const Color(0xFFF0B78E) : const Color(0xFF96592D),
      _ => Theme.of(context).colorScheme.primary,
    };
  }

  String initials(String name) {
    final result = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .map(
          (word) => word.characters.first.toUpperCase(),
        )
        .join();

    return result.isEmpty ? 'P' : result;
  }

  Widget sectionTitle(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(
        top: 12,
        bottom: 4,
      ),
      child: Row(
        children: [
          Icon(
            icon,
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

  Widget profileHeader(
    BuildContext context,
    RowData provider,
    int jobs,
  ) {
    final theme = Theme.of(context);

    final name = provider['name']?.toString() ?? 'Professional';

    final rank = provider['level']?.toString() ?? 'Unranked';

    final badgeColor = switch (rank) {
      'Gold' => const Color(0xFFFFD66B),
      'Silver' => const Color(0xFFDDE7EF),
      'Bronze' => const Color(0xFFF0B78E),
      _ => const Color(0xFFD9F5EC),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF008B7C),
            Color(0xFF005D53),
            Color(0xFF003F38),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          const Text(
            'SERVORA PROFESSIONAL',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFD9F5EC),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: badgeColor,
                width: 2,
              ),
            ),
            child: _PortfolioProfileAvatar(
              key: ValueKey(id),
              userId: id,
              initials: initials(name),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            name,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: badgeColor.withAlpha(35),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: badgeColor.withAlpha(130),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  color: badgeColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '$rank provider',
                    style: TextStyle(
                      color: badgeColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFFFD66B),
              ),
              Text(
                jobs == 0
                    ? 'Not rated yet'
                    : '${averageRating(provider).toStringAsFixed(1)}/5',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                jobs == 0 ? '' : '($jobs ${jobs == 1 ? 'review' : 'reviews'})',
                style: const TextStyle(
                  color: Color(0xFFD9F5EC),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget metric(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
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

  Widget metricGrid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final largeText = MediaQuery.textScalerOf(context).scale(12) > 18;

        final columns = constraints.maxWidth < 240 || largeText ? 1 : 2;

        const spacing = 12.0;

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

  Widget rewardCard(
    BuildContext context,
    RowData provider,
    int points,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final rank = provider['level'].toString();

    final nextRank = points < 50 ? 'Silver' : 'Gold';

    final nextPoints = points < 50 ? 50 : 120;

    final progress = points >= 120
        ? 1.0
        : points < 50
            ? points / 50
            : (points - 50) / 70;

    final color = rankColor(context, rank);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.emoji_events_outlined,
                    color: color,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$points',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const Text('Reward points'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'Membership progression',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0).toDouble(),
              color: color,
              minHeight: 9,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 12),
            Text(
              points >= 120
                  ? 'Highest membership rank achieved'
                  : '${nextPoints - points} points to reach $nextRank',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final level in [
                  'Bronze',
                  'Silver',
                  'Gold',
                ])
                  Chip(
                    backgroundColor: level == rank
                        ? colors.primaryContainer
                        : colors.surfaceContainerHighest,
                    avatar: Icon(
                      level == rank
                          ? Icons.check_circle_rounded
                          : Icons.workspace_premium_outlined,
                      color: rankColor(context, level),
                      size: 18,
                    ),
                    label: Text(level),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current service charge',
                    style: TextStyle(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${provider['fee']}%",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget serviceCard(
    BuildContext context,
    String category,
    RowData service,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final available = service['available'] == true;

    final statusColor = available
        ? colors.primary
        : theme.brightness == Brightness.dark
            ? const Color(0xFFFCD34D)
            : const Color(0xFFB45309);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ServiceCategoryIcon(
                  category: category,
                  size: 64,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${service['years']} years of experience",
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
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
                    'Starting rate',
                    style: TextStyle(
                      color: colors.onPrimaryContainer,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    servoraMoney(service['price']),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                backgroundColor: statusColor.withAlpha(25),
                avatar: Icon(
                  available
                      ? Icons.check_circle_outline
                      : Icons.pause_circle_outline,
                  color: statusColor,
                  size: 18,
                ),
                label: Text(
                  available ? 'Available' : 'Unavailable',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget workCard(
    BuildContext context,
    RowData work,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final stars = work['stars'];

    final rating =
        stars is num && stars.isFinite ? stars.toInt().clamp(0, 5) : 0;

    final result = work['result'];

    final hasPhoto = result is String && result.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasPhoto)
            photoView(result)
          else
            Container(
              height: 100,
              color: colors.primaryContainer,
              child: Icon(
                Icons.home_repair_service_outlined,
                size: 42,
                color: colors.onPrimaryContainer,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  work['title']?.toString() ?? 'Completed service',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Chip(
                  avatar: Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: colors.primary,
                  ),
                  label: const Text('Completed work'),
                ),
                const SizedBox(height: 12),
                Text(
                  work['summary']?.toString() ?? 'No work summary provided.',
                  style: theme.textTheme.bodyMedium,
                ),
                const Divider(height: 30),
                Text(
                  'Customer review',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 4,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (int i = 1; i <= 5; i++)
                      Icon(
                        i <= rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: const Color(0xFFE9AA26),
                        size: 24,
                      ),
                    const SizedBox(width: 4),
                    Text(
                      stars is num ? '$rating/5' : 'Not rated',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withAlpha(130),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.format_quote_rounded,
                        color: colors.primary,
                        size: 28,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        work['feedback']?.toString() ?? 'No feedback provided.',
                        style:
                            theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
                if (work['created'] != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    servoraDateLabel(
                      context,
                      work['created'],
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return page('Provider profile', [
        const Text('Please sign in to view this provider profile.'),
      ]);
    }

    final ref = db.collection('providers').doc(id);

    return _ServoraDocumentListener(
      key: ValueKey('portfolio/$userId/$id'),
      path: ref.path,
      userId: userId,
      includeMetadataChanges: true,
      builder: (context, snapshot) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;

        if (snapshot.hasError) {
          return page('Provider profile', [
            Icon(
              Icons.cloud_off_outlined,
              size: 64,
              color: colors.primary,
            ),
            const Text(
              'Unable to load provider profile.',
              textAlign: TextAlign.center,
            ),
          ]);
        }

        if (!snapshot.hasData) {
          return page('Provider profile', [
            const LinearProgressIndicator(),
          ]);
        }

        final provider = snapshot.data!.data();

        if (provider == null) {
          return page('Provider profile', [
            Icon(
              Icons.person_outline_rounded,
              size: 72,
              color: colors.primary,
            ),
            const Text(
              'Service profile unavailable.',
              textAlign: TextAlign.center,
            ),
            if (id == uid)
              action(
                'Create service profile',
                () => go(
                  context,
                  const MyServices(),
                ),
              ),
          ]);
        }

        final services = providerServices(provider);

        final points = (provider['points'] as num).toInt();

        final jobs = (provider['jobs'] as num).toInt();

        final onTime = jobs == 0
            ? 'No data'
            : '${((provider['ontime'] as num) / jobs * 100).toStringAsFixed(0)}%';

        return page(
          id == uid ? 'My portfolio' : 'Provider profile',
          [
            if (snapshot.data!.metadata.isFromCache)
              const Text(
                'Showing saved profile data.',
              ),
            profileHeader(
              context,
              provider,
              jobs,
            ),
            sectionTitle(
              context,
              'Professional overview',
              Icons.insights_rounded,
            ),
            metricGrid([
              metric(
                context,
                Icons.task_alt_rounded,
                '$jobs',
                'Completed jobs',
              ),
              metric(
                context,
                Icons.home_repair_service_outlined,
                '${services.length}',
                'Registered services',
              ),
              metric(
                context,
                Icons.schedule_rounded,
                onTime,
                'On-time completion',
              ),
              metric(
                context,
                Icons.bolt_rounded,
                provider['quick'].toString(),
                'Quick responses',
              ),
            ]),
            if (id == uid) ...[
              sectionTitle(
                context,
                'Performance and rewards',
                Icons.emoji_events_outlined,
              ),
              rewardCard(
                context,
                provider,
                points,
              ),
              FilledButton.icon(
                onPressed: () => go(
                  context,
                  const MyServices(),
                ),
                icon: const Icon(
                  Icons.settings_outlined,
                ),
                label: const Text(
                  'Manage my services',
                ),
              ),
            ],
            sectionTitle(
              context,
              'Services offered',
              Icons.home_repair_service_outlined,
            ),
            if (services.isEmpty)
              const Text(
                'No registered services yet.',
              ),
            for (final entry in services.entries)
              serviceCard(
                context,
                entry.key,
                entry.value,
              ),
            sectionTitle(
              context,
              'Work portfolio',
              Icons.photo_library_outlined,
            ),
            Text(
              'Explore completed services and customer feedback.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            rows(
              ref.collection('work'),
              (workId, work) => workCard(
                context,
                work,
              ),
            ),
            Text(
              'Ratings and performance statistics reflect '
              'the provider’s recorded service history.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        );
      },
    );
  }
}

class _PortfolioProfileAvatar extends StatefulWidget {
  final String userId;
  final String initials;

  const _PortfolioProfileAvatar({
    required this.userId,
    required this.initials,
    super.key,
  });

  @override
  State<_PortfolioProfileAvatar> createState() =>
      _PortfolioProfileAvatarState();
}

class _PortfolioProfileAvatarState extends State<_PortfolioProfileAvatar> {
  late final Stream<DocumentSnapshot<RowData>>? photoStream;

  @override
  void initState() {
    super.initState();

    final currentUser = FirebaseAuth.instance.currentUser;

    photoStream = currentUser?.uid == widget.userId
        ? db.collection('profilePhotos').doc(widget.userId).snapshots()
        : null;
  }

  Widget fallbackAvatar() {
    return CircleAvatar(
      radius: 46,
      backgroundColor: const Color(0xFFD9F5EC),
      foregroundColor: const Color(0xFF004D45),
      child: Text(
        widget.initials,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser?.uid != widget.userId ||
        photoStream == null) {
      return fallbackAvatar();
    }

    return StreamBuilder<DocumentSnapshot<RowData>>(
      stream: photoStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return fallbackAvatar();
        }

        if (!snapshot.hasData) {
          return const CircleAvatar(
            radius: 46,
            backgroundColor: Color(0xFFD9F5EC),
            child: SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF006B60),
                semanticsLabel: 'Loading profile photo',
              ),
            ),
          );
        }

        final value = snapshot.data?.data()?['bytes'];

        if (value is! Blob ||
            value.bytes.isEmpty ||
            value.bytes.length > 307200) {
          return fallbackAvatar();
        }

        return ClipOval(
          child: Image.memory(
            value.bytes,
            width: 92,
            height: 92,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => fallbackAvatar(),
          ),
        );
      },
    );
  }
}
