part of '../../main.dart';

Map<String, RowData> providerServices(RowData provider) {
  final result = <String, RowData>{};
  final stored = provider['services'];

  if (stored is Map) {
    for (final category in categories) {
      final service = stored[category];

      if (service is Map) {
        result[category] = RowData.from(service);
      }
    }

    return result;
  }

  final category = provider['category'];

  if (category is String && categories.contains(category)) {
    result[category] = {
      'price': provider['price'],
      'years': provider['years'],
      'available': provider['available'] == true,
    };
  }

  return result;
}

RowData? providerService(
  RowData provider,
  dynamic category,
) {
  return providerServices(provider)[category];
}

List<String> activeServiceCategories(RowData provider) {
  return providerServices(provider)
      .entries
      .where((entry) => entry.value['available'] == true)
      .map((entry) => entry.key)
      .toList();
}

bool offersService(
  RowData provider,
  dynamic category,
) {
  return providerService(provider, category) != null;
}

bool availableForService(
  RowData provider,
  dynamic category,
) {
  return providerService(provider, category)?['available'] == true;
}

RowData providerForService(
  RowData provider,
  dynamic category,
) {
  final service = providerService(provider, category);

  return {
    ...provider,
    'category': category,
    'price': service?['price'] ?? 0,
    'years': service?['years'] ?? 0,
    'available': service?['available'] == true,
  };
}

Future<void> saveProviderService({
  required String category,
  required RowData? service,
  required bool creating,
  bool availabilityOnly = false,
}) async {
  if (!categories.contains(category)) {
    throw Exception('Select a valid service category.');
  }

  if (availabilityOnly && (creating || service == null)) {
    throw ArgumentError('Availability updates require an existing service.');
  }

  final userId = uid;

  final memberRef = db.collection('members').doc(userId);
  final providerRef = db.collection('providers').doc(userId);

  await db.runTransaction((transaction) async {
    final memberSnapshot = await transaction.get(memberRef);
    final providerSnapshot = await transaction.get(providerRef);

    final member = memberSnapshot.data();
    final provider = providerSnapshot.data();

    if (member == null || member['role'] != 'provider') {
      throw Exception('A provider account is required.');
    }

    if (provider == null) {
      throw Exception('Create your service profile first.');
    }

    final services = providerServices(provider);

    if (service == null) {
      if (!services.containsKey(category)) {
        throw Exception('Service not found.');
      }

      if (services.length <= 1) {
        throw Exception(
          'Keep at least one registered service. '
          'You can disable its availability instead.',
        );
      }

      services.remove(category);
    } else {
      if (creating && services.containsKey(category)) {
        throw Exception('You already offer this service.');
      }

      if (!creating && !services.containsKey(category)) {
        throw Exception('Service no longer exists.');
      }

      final values = availabilityOnly ? services[category]! : service;
      final price = validatedNumber(
        values['price'],
        1,
        100000000,
        'Enter a valid starting rate.',
      );

      final years = validatedNumber(
        values['years'],
        0,
        80,
        'Enter valid years of experience.',
      );

      services[category] = {
        'price': price,
        'years': years,
        'available': service['available'] == true,
      };
    }

    final previousCategory = provider['category'];

    final primaryCategory =
        previousCategory is String && services.containsKey(previousCategory)
            ? previousCategory
            : categories.firstWhere(services.containsKey);

    final primary = services[primaryCategory]!;

    transaction.update(providerRef, {
      'services': services,
      'category': primaryCategory,
      'price': primary['price'],
      'years': primary['years'],
      'available': primary['available'],
    });
  });
}

class MyServices extends StatefulWidget {
  const MyServices({super.key});

  @override
  State<MyServices> createState() => _MyServicesState();
}

class _MyServicesState extends State<MyServices> {
  late final Stream<DocumentSnapshot<RowData>> profileStream;
  final Set<String> pending = {};

  @override
  void initState() {
    super.initState();
    profileStream = db.collection('providers').doc(uid).snapshots(
          includeMetadataChanges: true,
        );
  }

  Future<void> performChange(
      String category, Future<void> Function() change) async {
    if (!mounted || pending.isNotEmpty) return;
    setState(() => pending.add(category));
    try {
      await handle(context, change);
    } finally {
      if (mounted) setState(() => pending.remove(category));
    }
  }

  Future<void> removeService(
    BuildContext context,
    String category,
  ) async {
    if (pending.isNotEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove service?'),
        content: Text(
          'Remove $category from your service profile?\n\n'
          'Your existing job history, ratings and reward '
          'points will remain unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted || pending.isNotEmpty) return;

    await performChange(category, () async {
      await saveProviderService(
        category: category,
        service: null,
        creating: false,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service removed successfully.'),
          ),
        );
      }
    });
  }

  Widget serviceCard(
    BuildContext context,
    String category,
    RowData service,
    bool canRemove,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final available = service['available'] == true;
    final changing = pending.contains(category);
    final locked = pending.isNotEmpty;
    final statusColor = available ? colors.primary : colors.tertiary;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ServiceCategoryIcon(category: category, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        "${service['years']} years of experience",
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Starting rate',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onPrimaryContainer,
                      )),
                  const SizedBox(height: 4),
                  Text(servoraMoney(service['price']),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colors.onPrimaryContainer,
                      )),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                available ? 'Accepting requests' : 'Paused',
                style:
                    TextStyle(color: statusColor, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(changing
                  ? 'Updating service...'
                  : available
                      ? 'New quotations enabled'
                      : 'New quotations disabled'),
              value: available,
              onChanged: locked
                  ? null
                  : (value) => performChange(
                        category,
                        () => saveProviderService(
                          category: category,
                          service: {'available': value},
                          creating: false,
                          availabilityOnly: true,
                        ),
                      ),
            ),
            if (changing) const LinearProgressIndicator(),
            const Divider(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                OutlinedButton.icon(
                  onPressed: locked
                      ? null
                      : () => go(
                            context,
                            ServiceSettingsEditor(
                                choices: [category], initial: service),
                          ),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit service'),
                ),
                if (canRemove)
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: colors.error),
                    onPressed:
                        locked ? null : () => removeService(context, category),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget overview(int registered, int active) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF007D70), Color(0xFF003F38)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Manage your services',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: Colors.white)),
          const SizedBox(height: 6),
          const Text('Control your rates and work availability.',
              style: TextStyle(color: Color(0xFFD9F5EC))),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              for (final item in [
                (registered, 'Registered'),
                (active, 'Active'),
                (registered - active, 'Paused')
              ])
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${item.$1}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800)),
                    Text(item.$2,
                        style: const TextStyle(
                            color: Color(0xFFD9F5EC), fontSize: 12)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return StreamBuilder<DocumentSnapshot<RowData>>(
      stream: profileStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return page('My services', [
            Icon(Icons.cloud_off_outlined, color: colors.primary, size: 48),
            const Text('Unable to load your services.',
                textAlign: TextAlign.center),
          ]);
        }
        if (!snapshot.hasData) {
          return page('My services', [const LinearProgressIndicator()]);
        }
        final provider = snapshot.data!.data();
        final cached = snapshot.data!.metadata.isFromCache;
        if (provider == null) {
          return page('My services', [
            Icon(Icons.home_repair_service_outlined,
                size: 64, color: colors.primary),
            Text(
              cached
                  ? 'Service profile unavailable in saved data. Connect to refresh.'
                  : 'Create your first service profile to start receiving service requests.',
              textAlign: TextAlign.center,
            ),
            if (!cached)
              FilledButton.icon(
                onPressed: () => go(context, const Editor(mode: 'profile')),
                icon: const Icon(Icons.add),
                label: const Text('Create service profile'),
              ),
          ]);
        }
        final services = providerServices(provider);
        final remaining = categories
            .where((category) => !services.containsKey(category))
            .toList();
        final active = activeServiceCategories(provider).length;
        return page('My services', [
          if (cached) const Text('Showing saved service data.'),
          overview(services.length, active),
          if (remaining.isNotEmpty)
            FilledButton.icon(
              onPressed: pending.isNotEmpty
                  ? null
                  : () =>
                      go(context, ServiceSettingsEditor(choices: remaining)),
              icon: const Icon(Icons.add),
              label: const Text('Add a service'),
            )
          else
            const Text('All available service categories have been added.'),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.location_on_outlined,
                            color: colors.onPrimaryContainer),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Shared service location',
                              style: theme.textTheme.titleMedium),
                          Text(
                              provider['area']?.toString() ??
                                  'Location not configured',
                              style: theme.textTheme.bodySmall),
                        ],
                      )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Used for approximate distance recommendations.'),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: pending.isNotEmpty
                        ? null
                        : () => go(context,
                            Editor(mode: 'location', initial: provider)),
                    icon: const Icon(Icons.edit_location_alt_outlined),
                    label: const Text('Manage location'),
                  ),
                ],
              ),
            ),
          ),
          Text('Your registered services', style: theme.textTheme.titleLarge),
          if (services.isEmpty) const Text('No registered services.'),
          for (final entry in services.entries)
            serviceCard(context, entry.key, entry.value, services.length > 1),
          if (services.length == 1)
            const Text(
                'Keep at least one registered service. You can pause it instead.'),
        ]);
      },
    );
  }
}

class ServiceSettingsEditor extends StatefulWidget {
  final List<String> choices;
  final RowData? initial;

  const ServiceSettingsEditor({
    required this.choices,
    this.initial,
    super.key,
  });

  @override
  State<ServiceSettingsEditor> createState() => _ServiceSettingsEditorState();
}

class _ServiceSettingsEditorState extends State<ServiceSettingsEditor> {
  late String category;
  late bool available;

  late final TextEditingController priceController;
  late final TextEditingController yearsController;

  bool busy = false;

  bool get creating => widget.initial == null;

  @override
  void initState() {
    super.initState();

    category = widget.choices.first;
    available = widget.initial?['available'] != false;

    priceController = TextEditingController(
      text: widget.initial?['price']?.toString() ?? '',
    );

    yearsController = TextEditingController(
      text: widget.initial?['years']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    priceController.dispose();
    yearsController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (busy) return;

    setState(() => busy = true);

    try {
      await saveProviderService(
        category: category,
        creating: creating,
        service: {
          'price': num.tryParse(
            priceController.text.trim(),
          ),
          'years': num.tryParse(
            yearsController.text.trim(),
          ),
          'available': available,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              creating
                  ? 'Service added successfully.'
                  : 'Service updated successfully.',
            ),
          ),
        );

        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.toString().replaceFirst('Exception: ', ''),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return page(creating ? 'Add service' : 'Edit service', [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            ServiceCategoryIcon(category: category, size: 56),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(creating ? 'Expand your business' : 'Edit $category',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(color: colors.onPrimaryContainer)),
                const SizedBox(height: 4),
                Text('Set your rates and experience.',
                    style: TextStyle(color: colors.onPrimaryContainer)),
              ],
            )),
          ],
        ),
      ),
      Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Service information', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              if (creating)
                AbsorbPointer(
                  absorbing: busy,
                  child: select(
                    'Service category',
                    category,
                    widget.choices,
                    (value) {
                      if (!busy) setState(() => category = value);
                    },
                  ),
                )
              else
                Text('Service category: $category'),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                enabled: !busy,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Starting rate (LKR)',
                    hintText: '1500',
                    prefixIcon: Icon(Icons.payments_outlined)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: yearsController,
                enabled: !busy,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Years of experience',
                    hintText: '3',
                    prefixIcon: Icon(Icons.work_history_outlined)),
              ),
            ],
          ),
        ),
      ),
      Card(
        margin: EdgeInsets.zero,
        child: SwitchListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          title: const Text('Available for work'),
          subtitle: Text(available
              ? 'Discover requests and submit quotations.'
              : 'Pause new quotation submissions.'),
          value: available,
          onChanged: busy ? null : (value) => setState(() => available = value),
        ),
      ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: colors.primary),
          const SizedBox(width: 10),
          const Expanded(
              child: Text(
                  'All services use your existing provider account, contact number and shared service location.')),
        ],
      ),
      FilledButton.icon(
        onPressed: busy
            ? null
            : () {
                FocusScope.of(context).unfocus();
                save();
              },
        icon: const Icon(Icons.check_circle_outline),
        label: Text(busy
            ? 'Saving...'
            : creating
                ? 'Add service'
                : 'Save changes'),
      ),
      if (busy) const LinearProgressIndicator(),
    ]);
  }
}

class ProviderQuotationGate extends StatelessWidget {
  final dynamic category;
  final Widget child;

  const ProviderQuotationGate({
    required this.category,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<RowData>>(
      stream: db.collection('providers').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text(
            'Unable to check service availability.',
          );
        }

        if (!snapshot.hasData) {
          return const LinearProgressIndicator();
        }

        final provider = snapshot.data!.data();

        if (provider == null) {
          return const Text(
            'Create your service profile first.',
          );
        }

        if (!offersService(provider, category)) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'You no longer offer this service. '
                'Existing quotations can still be withdrawn.',
              ),
            ),
          );
        }

        if (!availableForService(provider, category)) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.pause_circle_outline,
                    color: Theme.of(context).colorScheme.tertiary,
                    size: 36,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This service is currently unavailable.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => go(
                      context,
                      const MyServices(),
                    ),
                    child: const Text('Manage my services'),
                  ),
                ],
              ),
            ),
          );
        }

        return child;
      },
    );
  }
}
