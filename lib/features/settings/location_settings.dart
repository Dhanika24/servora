part of '../../main.dart';

class ServoraLocationSettings extends StatefulWidget {
  const ServoraLocationSettings({super.key});

  @override
  State<ServoraLocationSettings> createState() =>
      _ServoraLocationSettingsState();
}

class _ServoraLocationSettingsState extends State<ServoraLocationSettings>
    with WidgetsBindingObserver {
  bool loading = true;
  bool busy = false;
  bool serviceEnabled = false;

  LocationPermission? permission;
  String? loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed && !busy) {
      refreshStatus();
    }
  }

  Future<void> refreshStatus() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      loadError = null;
    });

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();

      final currentPermission = await Geolocator.checkPermission();

      if (!mounted) return;

      setState(() {
        serviceEnabled = enabled;
        permission = currentPermission;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
        loadError = 'Unable to check location settings.';
      });
    }
  }

  bool get permissionGranted =>
      permission == LocationPermission.always ||
      permission == LocationPermission.whileInUse;

  String get permissionLabel {
    if (permission == LocationPermission.always) {
      return 'Always allowed';
    }

    if (permission == LocationPermission.whileInUse) {
      return 'Allowed while using the app';
    }

    if (permission == LocationPermission.deniedForever) {
      return 'Disabled in application permissions';
    }

    if (permission == LocationPermission.denied) {
      return 'Not granted';
    }

    return 'Unavailable';
  }

  Future<void> requestAccess() async {
    if (busy) return;

    setState(() => busy = true);

    try {
      if (permission == LocationPermission.deniedForever) {
        final opened = await Geolocator.openAppSettings();

        if (!opened) {
          throw Exception(
            'Unable to open application settings.',
          );
        }
      } else if (!permissionGranted) {
        await Geolocator.requestPermission();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to update location permissions.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
        await refreshStatus();
      }
    }
  }

  Future<void> openSystemSettings({
    required bool application,
  }) async {
    if (busy) return;

    setState(() => busy = true);

    try {
      final opened = application
          ? await Geolocator.openAppSettings()
          : await Geolocator.openLocationSettings();

      if (!opened) {
        throw Exception('Unable to open settings.');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Open the device settings manually.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
        await refreshStatus();
      }
    }
  }

  Widget statusCard({
    required String title,
    required String description,
    required IconData icon,
    required bool enabled,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor:
              enabled ? colors.primaryContainer : colors.errorContainer,
          foregroundColor:
              enabled ? colors.onPrimaryContainer : colors.onErrorContainer,
          child: Icon(icon),
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: Icon(
          enabled ? Icons.check_circle_outline : Icons.info_outline,
          color: enabled ? colors.primary : colors.error,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return page('Location settings', [
      _settingsPageIntro(
        context,
        label: 'SERVORA LOCATION',
        title: 'Manage location access',
        description: 'Location helps find relevant services and estimate '
            'distances between customers and providers.',
        icon: Icons.location_on_outlined,
      ),
      Text(
        'Device permissions',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      if (busy && !loading) const LinearProgressIndicator(),
      if (loading)
        const LinearProgressIndicator()
      else if (loadError != null)
        Text(loadError!)
      else ...[
        statusCard(
          title: 'Device location',
          description: serviceEnabled
              ? 'Location services enabled'
              : 'Location services disabled',
          icon: Icons.gps_fixed,
          enabled: serviceEnabled,
        ),
        statusCard(
          title: 'Location permission',
          description: permissionLabel,
          icon: Icons.security_outlined,
          enabled: permissionGranted,
        ),
      ],
      if (!loading && loadError == null && !permissionGranted)
        FilledButton.icon(
          onPressed: busy ? null : requestAccess,
          icon: const Icon(Icons.my_location),
          label: const Text('Allow location access'),
        ),
      OutlinedButton.icon(
        onPressed: busy || loading
            ? null
            : () => openSystemSettings(
                  application: false,
                ),
        icon: const Icon(Icons.location_searching),
        label: const Text('Device location settings'),
      ),
      OutlinedButton.icon(
        onPressed: busy || loading
            ? null
            : () => openSystemSettings(
                  application: true,
                ),
        icon: const Icon(Icons.settings_outlined),
        label: const Text('Application permissions'),
      ),
      TextButton.icon(
        onPressed: loading || busy ? null : refreshStatus,
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh status'),
      ),
      const Divider(),
      Text(
        'Your location privacy',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      _settingsInformationCard(
        context,
        'Approximate locations',
        'Service matching and distance comparisons '
            'use approximate locations.',
      ),
      _settingsInformationCard(
        context,
        'Protected request locations',
        'The exact saved request location is available '
            'to the customer and the selected provider '
            'during an active booking.',
      ),
      _settingsInformationCard(
        context,
        'Location access',
        'Servora requests your current location '
            'when you choose to use the GPS feature. '
            'Continuous background tracking is not used.',
      ),
      const Text(
        'Disabling device permissions does not delete '
        'locations previously saved with service requests.',
      ),
    ]);
  }
}
