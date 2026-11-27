part of '../../main.dart';

DateTime? sriLankaDateTime(dynamic value) {
  if (value is! num || !value.isFinite || value <= 0) {
    return null;
  }

  return DateTime.fromMillisecondsSinceEpoch(
    value.toInt(),
    isUtc: true,
  ).add(
    const Duration(hours: 5, minutes: 30),
  );
}

String servoraDateLabel(
  BuildContext context,
  dynamic value,
) {
  final date = sriLankaDateTime(value);

  if (date == null) {
    return 'Date not recorded';
  }

  final locale = MaterialLocalizations.of(context);

  final formattedDate = locale.formatFullDate(date);

  final formattedTime = locale.formatTimeOfDay(
    TimeOfDay.fromDateTime(date),
  );

  return '$formattedDate, $formattedTime';
}

class JobTimeline extends StatelessWidget {
  final RowData job;

  const JobTimeline({
    required this.job,
    super.key,
  });

  int get currentStage => switch (job['status']) {
        'open' => 0,
        'booked' => 1,
        'in progress' => 2,
        'awaiting review' => 3,
        'completed' => 4,
        _ => -1,
      };

  Widget timelineItem(
    BuildContext context, {
    required String title,
    required dynamic timestamp,
    required int index,
    required IconData icon,
    bool last = false,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final reached = index <= currentStage;
    final current = index == currentStage && currentStage < 4;

    final markerColor =
        reached ? colors.primary : colors.surfaceContainerHighest;

    final foreground = reached ? colors.onPrimary : colors.onSurfaceVariant;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 42,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: markerColor,
                    shape: BoxShape.circle,
                    border: current
                        ? Border.all(
                            color: colors.primaryContainer,
                            width: 3,
                          )
                        : null,
                  ),
                  child: Icon(
                    reached && !current ? Icons.check_rounded : icon,
                    size: 20,
                    color: foreground,
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: index < currentStage
                          ? colors.primary
                          : colors.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: 5,
                bottom: last ? 4 : 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color:
                          reached ? colors.onSurface : colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    reached
                        ? servoraDateLabel(
                            context,
                            timestamp,
                          )
                        : 'Pending',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  if (current) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Current stage',
                        style: TextStyle(
                          color: colors.onPrimaryContainer,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget deadlineCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final finished = job['finished'];
    final due = job['due'];

    final validResult = currentStage >= 3 &&
        finished is num &&
        finished.isFinite &&
        finished > 0 &&
        due is num &&
        due.isFinite &&
        due > 0;

    final onTime = validResult && finished <= due;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                color: colors.onPrimaryContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Expected completion',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            servoraDateLabel(context, due),
            style: TextStyle(
              color: colors.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (validResult) ...[
            const SizedBox(height: 10),
            Text(
              onTime ? 'Submitted on time' : 'Submitted after deadline',
              style: TextStyle(
                color: colors.onPrimaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _servoraJobHeading(
              context,
              Icons.timeline_rounded,
              'Job progress',
            ),
            const SizedBox(height: 12),
            Text(
              'Track your service from request to completion.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            LinearProgressIndicator(
              value: currentStage < 0 ? 0.0 : (currentStage + 1) / 5,
              minHeight: 7,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 8),
            Text(
              currentStage < 0
                  ? 'Progress unavailable'
                  : '${currentStage + 1} of 5 milestones reached',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            timelineItem(
              context,
              title: 'Request posted',
              timestamp: job['created'],
              index: 0,
              icon: Icons.assignment_outlined,
            ),
            timelineItem(
              context,
              title: 'Booking confirmed',
              timestamp: job['bookedAt'],
              index: 1,
              icon: Icons.handshake_outlined,
            ),
            timelineItem(
              context,
              title: 'Work started',
              timestamp: job['startedAt'],
              index: 2,
              icon: Icons.build_outlined,
            ),
            timelineItem(
              context,
              title: 'Work submitted',
              timestamp: job['finished'],
              index: 3,
              icon: Icons.assignment_turned_in_outlined,
            ),
            timelineItem(
              context,
              title: 'Completed and reviewed',
              timestamp: job['reviewedAt'],
              index: 4,
              icon: Icons.task_alt_rounded,
              last: true,
            ),
            if (currentStage >= 1 && job['due'] != null) ...[
              const SizedBox(height: 20),
              deadlineCard(context),
            ],
            const SizedBox(height: 16),
            Text(
              'All dates and times are shown in Sri Lanka time.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
