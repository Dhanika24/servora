part of '../../main.dart';

class NotificationSettings extends StatefulWidget {
  final bool provider;

  const NotificationSettings({
    required this.provider,
    super.key,
  });

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  late final String userId;

  bool loading = true;
  bool saving = false;
  String? loadError;

  bool quotations = true;
  bool requests = true;
  bool jobUpdates = true;

  @override
  void initState() {
    super.initState();
    userId = uid;
    loadPreferences();
  }

  Future<void> loadPreferences() async {
    try {
      final values = await Future.wait<bool>([
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

      if (!mounted) return;

      setState(() {
        quotations = values[0];
        requests = values[1];
        jobUpdates = values[2];
        loading = false;
        loadError = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
        loadError = 'Unable to load notification preferences.';
      });
    }
  }

  Future<void> changePreference(
    String key,
    bool value,
  ) async {
    if (saving) return;

    setState(() => saving = true);

    await handle(context, () async {
      await appPreferences.setNotification(
        userId,
        key,
        value,
      );

      if (!mounted) return;

      setState(() {
        switch (key) {
          case 'quotations':
            quotations = value;
            break;

          case 'requests':
            requests = value;
            break;

          case 'jobUpdates':
            jobUpdates = value;
            break;
        }
      });
    });

    if (mounted) {
      setState(() => saving = false);
    }
  }

  Widget preferenceTile({
    required String title,
    required String description,
    required IconData icon,
    required String preference,
    required bool enabled,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 6,
      ),
      secondary: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: colors.onPrimaryContainer,
          size: 21,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        description,
        style: theme.textTheme.bodySmall,
      ),
      value: enabled,
      onChanged: saving
          ? null
          : (value) => changePreference(
                preference,
                value,
              ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return page('Notification settings', [
      _settingsPageIntro(
        context,
        label: 'SERVORA PREFERENCES',
        title: 'Stay informed',
        description: 'Choose which service updates appear '
            'in your activity centre.',
        icon: Icons.notifications_active_outlined,
      ),
      if (loading)
        const LinearProgressIndicator()
      else if (loadError != null) ...[
        Text(loadError!),
        FilledButton.icon(
          onPressed: () {
            setState(() => loading = true);
            loadPreferences();
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Try again'),
        ),
      ] else ...[
        Text(
          'Activity preferences',
          style: theme.textTheme.titleLarge,
        ),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              if (!widget.provider)
                preferenceTile(
                  title: 'Quotation updates',
                  description: 'New quotations and quotation modifications',
                  icon: Icons.request_quote_outlined,
                  preference: 'quotations',
                  enabled: quotations,
                ),
              if (widget.provider)
                preferenceTile(
                  title: 'Available service requests',
                  description: 'Requests matching your available services',
                  icon: Icons.work_outline,
                  preference: 'requests',
                  enabled: requests,
                ),
              const Divider(
                height: 1,
                indent: 66,
                endIndent: 14,
              ),
              preferenceTile(
                title: 'Job updates',
                description: 'Bookings, progress, completion and reviews',
                icon: Icons.assignment_outlined,
                preference: 'jobUpdates',
                enabled: jobUpdates,
              ),
            ],
          ),
        ),
        if (saving) const LinearProgressIndicator(),
        if (!jobUpdates && !(widget.provider ? requests : quotations))
          _settingsInformationCard(
            context,
            'Activity updates paused',
            'All notification categories for your account '
                'are currently disabled.',
          ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: colors.onPrimaryContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'These preferences control in-app activity '
                  'updates, not background push notifications. '
                  'Your bookings, quotations and job history '
                  'remain unchanged.',
                  style: TextStyle(
                    color: colors.onPrimaryContainer,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
        Text(
          'Preferences are saved for your account on this device.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
      ],
    ]);
  }
}
