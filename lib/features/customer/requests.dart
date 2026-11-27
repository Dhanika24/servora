part of '../../main.dart';

class Editor extends StatefulWidget {
  final String mode;
  final RowData? initial;
  final String? jobId;
  const Editor({required this.mode, this.initial, this.jobId, super.key});
  @override
  State<Editor> createState() => _Editor();
}

class _Editor extends State<Editor> {
  late RowData d;
  late final String id;
  bool busy = false;
  final ctrls = <String, TextEditingController>{};
  @override
  void initState() {
    super.initState();
    d = {
      'category': widget.mode == 'emergency' ? 'Mechanic' : 'Plumbing',
      'available': true,
      'stars': 5,
      'consent': false,
      ...?widget.initial
    };
    id = widget.jobId ?? db.collection('jobs').doc().id;
  }

  @override
  void dispose() {
    for (final c in ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget field(
    String key,
    String label, {
    bool number = false,
    int lines = 1,
    IconData? icon,
    String? hint,
  }) {
    final ctrl = ctrls.putIfAbsent(
      key,
      () => TextEditingController(
        text: d[key]?.toString() ?? '',
      ),
    );

    return TextField(
      controller: ctrl,
      enabled: !busy,
      minLines: lines,
      maxLines: lines == 1 ? 1 : lines + 2,
      keyboardType: number
          ? const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            )
          : lines > 1
              ? TextInputType.multiline
              : TextInputType.text,
      textCapitalization:
          number ? TextCapitalization.none : TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: lines > 1,
        prefixIcon: icon == null ? null : Icon(icon),
      ),
      onChanged: (v) {
        final value = number ? num.tryParse(v) : v;

        if (key == 'lat' || key == 'lng') {
          setState(() => d[key] = value);
        } else {
          d[key] = value;
        }
      },
    );
  }

  Widget formSection({
    required String title,
    required IconData icon,
    String? description,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
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
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            if (description != null) ...[
              const SizedBox(height: 12),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 20),
            for (int i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              children[i],
            ],
          ],
        ),
      ),
    );
  }

  Widget formHeader({
    required String title,
    required String description,
    required IconData icon,
    String? category,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (category != null)
            ServiceCategoryIcon(
              category: category,
              size: 64,
            )
          else
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: colors.surface.withAlpha(180),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                icon,
                size: 30,
                color: colors.onPrimaryContainer,
              ),
            ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: colors.onPrimaryContainer,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget ratingSelector() {
    final rating = (d['stars'] as num).toInt();

    final label = switch (rating) {
      1 => 'Very poor',
      2 => 'Poor',
      3 => 'Satisfactory',
      4 => 'Good',
      _ => 'Excellent',
    };

    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            for (int star = 1; star <= 5; star++)
              IconButton(
                tooltip: 'Rate $star out of 5',
                onPressed: busy
                    ? null
                    : () => setState(() {
                          d['stars'] = star;
                        }),
                iconSize: 34,
                icon: Icon(
                  star <= rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: star <= rating
                      ? const Color(0xFFE9AA26)
                      : Theme.of(context).colorScheme.outline,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '$rating / 5 - $label',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }

  Future<void> locationHelp({
    required String title,
    required String message,
    required bool appSettings,
  }) async {
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Open settings'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final opened = appSettings
        ? await Geolocator.openAppSettings()
        : await Geolocator.openLocationSettings();

    if (!opened) {
      throw Exception('Unable to open device settings.');
    }
  }

  Future<void> gps() async {
    final enabled = await Geolocator.isLocationServiceEnabled();

    if (!enabled) {
      await locationHelp(
        title: 'Location services disabled',
        message: 'Enable location services and try again, '
            'or enter your coordinates manually.',
        appSettings: false,
      );
      return;
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      await locationHelp(
        title: 'Location permission required',
        message: 'Allow location access in the app settings, '
            'or enter your coordinates manually.',
        appSettings: true,
      );
      return;
    }

    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      throw Exception(
        'Location permission was not granted. '
        'You can enter coordinates manually.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 30),
      ),
    );

    if (!mounted) return;

    final latitude = position.latitude;
    final longitude = position.longitude;

    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      throw Exception('Invalid location received.');
    }

    setState(() {
      d['lat'] = latitude;
      d['lng'] = longitude;

      ctrls['lat']?.text = latitude.toString();
      ctrls['lng']?.text = longitude.toString();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Location captured. Estimated accuracy: '
          '${position.accuracy.toStringAsFixed(0)} metres.',
        ),
        backgroundColor: ink,
      ),
    );
  }

  Widget locationSection(bool customerRequest) {
    final lat = d['lat'];
    final lng = d['lng'];

    final hasLocation = lat is num &&
        lng is num &&
        lat.isFinite &&
        lng.isFinite &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: ink,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Service location',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            field('area', 'Town or service area'),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: busy ? null : () => run(gps),
              icon: const Icon(Icons.my_location),
              label: Text(
                hasLocation
                    ? 'Update current location'
                    : 'Use current location',
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasLocation
                    ? Colors.green.withAlpha(20)
                    : Colors.orange.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    hasLocation
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                    color: hasLocation
                        ? Colors.green.shade700
                        : Colors.orange.shade800,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hasLocation
                          ? 'Location selected'
                          : 'Select your service location',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              customerRequest
                  ? 'Your precise location is shared with '
                      'your selected provider only during '
                      'an active booking. Other eligible '
                      'providers can see your approximate area.'
                  : 'Your approximate service location is '
                      'used to calculate distance and '
                      'recommend your services.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text(
                'Advanced location settings',
              ),
              subtitle: const Text(
                'Manual coordinate entry',
              ),
              children: [
                field(
                  'lat',
                  'Latitude',
                  number: true,
                ),
                const SizedBox(height: 10),
                field(
                  'lng',
                  'Longitude',
                  number: true,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> upload(String key) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 55,
      maxWidth: 1000,
      maxHeight: 1000,
      requestFullMetadata: false,
    );

    if (file == null) return;

    final bytes = await file.readAsBytes();

    if (bytes.isEmpty) {
      throw Exception('Unable to read the selected image.');
    }

    if (bytes.length > 300 * 1024) {
      throw Exception(
        'The compressed image exceeds 300 KB. '
        'Please select a smaller image.',
      );
    }

    if (!mounted) return;

    setState(() {
      d[key] = bytes;
    });
  }

  Widget imageAttachment(String key) {
    final bytes = d[key];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              key == 'photo' ? 'Service request photo' : 'Completed work photo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Optional image. Maximum size: 300 KB. '
              'Avoid including personal or sensitive information.',
            ),
            const SizedBox(height: 12),
            if (bytes is Uint8List) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  bytes,
                  height: 220,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Text('Image preview unavailable.');
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Image size: ${(bytes.length / 1024).toStringAsFixed(1)} KB',
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              onPressed: busy ? null : () => run(() => upload(key)),
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(
                bytes is Uint8List ? 'Replace photo' : 'Choose photo',
              ),
            ),
            if (bytes is Uint8List)
              TextButton.icon(
                onPressed: busy
                    ? null
                    : () => setState(() {
                          d.remove(key);
                        }),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove photo'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> run(Future<void> Function() fn) async {
    if (busy) return;
    setState(() => busy = true);
    await handle(context, fn);
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext c) {
    final mode = widget.mode;
    final post = mode == 'post' || mode == 'emergency';
    final profile = mode == 'profile';

    final title = switch (mode) {
      'post' => 'Request a service',
      'emergency' => 'Emergency mechanic',
      'profile' => 'Service profile',
      'location' => 'Service location',
      'quote' => 'Your quotation',
      'finish' => 'Work result',
      'review' => 'Review this job',
      _ => 'Service details',
    };

    final description = switch (mode) {
      'post' =>
        'Describe what you need and receive quotations from local professionals.',
      'emergency' => 'Provide your location and describe your vehicle problem.',
      'profile' =>
        'Set up your service information, experience and availability.',
      'location' =>
        'Manage the location used for your service recommendations.',
      'quote' =>
        'Provide a clear price and estimated completion time for the customer.',
      'finish' =>
        'Describe the work you have completed and attach an optional photo.',
      'review' =>
        'Share your experience and help other customers make informed decisions.',
      _ => 'Complete the required information below.',
    };

    final icon = switch (mode) {
      'quote' => Icons.request_quote_outlined,
      'finish' => Icons.task_alt_rounded,
      'review' => Icons.star_outline_rounded,
      'location' => Icons.location_on_outlined,
      'profile' => Icons.home_repair_service_outlined,
      _ => Icons.assignment_outlined,
    };

    final buttonLabel = switch (mode) {
      'post' => 'Post service request',
      'emergency' => 'Request assistance',
      'quote' => 'Submit quotation',
      'finish' => 'Submit completed work',
      'review' => 'Submit review',
      'profile' => 'Save service profile',
      'location' => 'Save location',
      _ => 'Save',
    };

    return page(title, [
      formHeader(
        title: title,
        description: description,
        icon: icon,
        category: post || profile ? d['category']?.toString() : null,
      ),
      if ((post || profile) && mode != 'emergency')
        formSection(
          title: 'Service category',
          icon: Icons.category_outlined,
          description: 'Choose the appropriate service.',
          children: [
            AbsorbPointer(
              absorbing: busy,
              child: select(
                'Service',
                d['category'],
                categories,
                (v) => setState(() {
                  d['category'] = v;
                }),
              ),
            ),
          ],
        ),
      if (post)
        formSection(
          title: 'Request details',
          icon: Icons.description_outlined,
          description:
              'Provide enough information for professionals to understand your request.',
          children: [
            field(
              'title',
              'Task title',
              icon: Icons.edit_outlined,
              hint: 'Example: Water tank repair',
            ),
            field(
              'description',
              'Describe the problem',
              lines: 4,
              hint: 'Explain what needs to be done...',
            ),
            field(
              'budget',
              'Budget (LKR)',
              number: true,
              icon: Icons.payments_outlined,
            ),
          ],
        ),
      if (profile)
        formSection(
          title: 'Professional information',
          icon: Icons.badge_outlined,
          children: [
            field(
              'price',
              'Starting rate (LKR)',
              number: true,
              icon: Icons.payments_outlined,
            ),
            field(
              'years',
              'Years of experience',
              number: true,
              icon: Icons.work_history_outlined,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Available for work'),
              subtitle: const Text(
                'Receive relevant service requests.',
              ),
              value: d['available'],
              onChanged: busy
                  ? null
                  : (v) => setState(() {
                        d['available'] = v;
                      }),
            ),
          ],
        ),
      if (post || profile || mode == 'location') locationSection(post),
      if (mode == 'quote')
        formSection(
          title: 'Quotation details',
          icon: Icons.receipt_long_outlined,
          children: [
            field(
              'amount',
              'Total quote (LKR)',
              number: true,
              icon: Icons.payments_outlined,
            ),
            field(
              'hours',
              'Hours to finish after booking',
              number: true,
              icon: Icons.schedule_rounded,
            ),
            field(
              'note',
              'What is included?',
              lines: 4,
              hint: 'Describe the services and materials included.',
            ),
          ],
        ),
      if (mode == 'finish')
        formSection(
          title: 'Completed work',
          icon: Icons.check_circle_outline,
          children: [
            field(
              'summary',
              'Describe the completed work',
              lines: 4,
              hint: 'Explain what was completed...',
            ),
          ],
        ),
      if (mode == 'finish' || post) imageAttachment(post ? 'photo' : 'result'),
      if (mode == 'review') ...[
        formSection(
          title: 'Rate your experience',
          icon: Icons.star_outline_rounded,
          children: [
            ratingSelector(),
            field(
              'feedback',
              'Your feedback',
              lines: 4,
              hint: 'Tell us about your experience...',
            ),
          ],
        ),
        Card(
          margin: EdgeInsets.zero,
          child: CheckboxListTile(
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Portfolio permission'),
            subtitle: const Text(
              'Allow the work result photo in the provider portfolio.',
            ),
            value: d['consent'],
            onChanged: busy
                ? null
                : (v) => setState(() {
                      d['consent'] = v ?? false;
                    }),
          ),
        ),
      ],
      const SizedBox(height: 6),
      FilledButton.icon(
        onPressed: busy
            ? null
            : () => run(() async {
                  FocusScope.of(c).unfocus();

                  await send(
                    post ? 'post' : mode,
                    {
                      ...d,
                      'jobId': id,
                      'emergency': mode == 'emergency',
                    },
                  );

                  if (c.mounted) {
                    Navigator.pop(c);
                  }
                }),
        icon: const Icon(Icons.arrow_forward_rounded),
        label: Text(
          busy ? 'Please wait...' : buttonLabel,
        ),
      ),
      if (busy) const LinearProgressIndicator(),
    ]);
  }
}

Widget photoView(
  String? path, {
  Object? accessRevision,
}) {
  if (path == null || path.isEmpty) {
    return const SizedBox.shrink();
  }

  if (!RegExp(r'^jobs/[^/]+/images/(request|result)$').hasMatch(path)) {
    return const Text('Image unavailable.');
  }

  final userId = FirebaseAuth.instance.currentUser?.uid;

  if (userId == null) {
    return const Text('Sign in to view this photograph.');
  }

  return _ServoraPhotoPreview(
    key: ValueKey((userId, path, accessRevision)),
    path: path,
    userId: userId,
    title: path.endsWith('/request')
        ? 'Request photograph'
        : 'Completed work photograph',
  );
}

class _ServoraPhotoPreview extends StatefulWidget {
  final String path;
  final String userId;
  final String title;

  const _ServoraPhotoPreview({
    required this.path,
    required this.userId,
    required this.title,
    super.key,
  });

  @override
  State<_ServoraPhotoPreview> createState() => _ServoraPhotoPreviewState();
}

class _ServoraPhotoPreviewState extends State<_ServoraPhotoPreview> {
  late Future<MemoryImage?> imageFuture;

  late final Stream<User?> authStream;

  @override
  void initState() {
    super.initState();

    authStream = FirebaseAuth.instance.authStateChanges();

    imageFuture = loadThumbnail();
  }

  Future<MemoryImage?> loadThumbnail() async {
    if (FirebaseAuth.instance.currentUser?.uid != widget.userId) {
      return null;
    }

    final snapshot = await db.doc(widget.path).get(
          const GetOptions(source: Source.server),
        );

    if (FirebaseAuth.instance.currentUser?.uid != widget.userId) {
      return null;
    }

    final image = snapshot.data()?['bytes'];

    if (image is! Blob || image.bytes.isEmpty || image.bytes.length > 307200) {
      return null;
    }

    return MemoryImage(image.bytes);
  }

  void retry() {
    if (FirebaseAuth.instance.currentUser?.uid != widget.userId) {
      return;
    }

    setState(() {
      imageFuture = loadThumbnail();
    });
  }

  void openViewer() {
    if (FirebaseAuth.instance.currentUser?.uid != widget.userId) {
      return;
    }

    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _ServoraFullscreenImage(
          path: widget.path,
          title: widget.title,
          userId: widget.userId,
        ),
      ),
    );
  }

  Widget unavailable(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _servoraPhotoUnavailable(context),
        TextButton.icon(
          onPressed: retry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Reload photograph'),
        ),
      ],
    );
  }

  Widget thumbnail(MemoryImage image) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: 'Open ${widget.title} in fullscreen',
            button: true,
            child: InkWell(
              onTap: openViewer,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: double.infinity,
                    height: 230,
                    color: colors.surfaceContainerHighest,
                    padding: const EdgeInsets.all(6),
                    child: Image(
                      image: ResizeImage.resizeIfNeeded(
                        640,
                        null,
                        image,
                      ),
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      excludeFromSemantics: true,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 44,
                            color: colors.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(170),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.fullscreen_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              14,
              10,
              14,
              12,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.photo_outlined,
                  color: colors.primary,
                  size: 20,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Tap to view fullscreen',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'View fullscreen',
                  onPressed: openViewer,
                  icon: Icon(
                    Icons.open_in_full_rounded,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authStream,
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, authSnapshot) {
        if (authSnapshot.data?.uid != widget.userId ||
            FirebaseAuth.instance.currentUser?.uid != widget.userId) {
          return const SizedBox.shrink();
        }

        return FutureBuilder<MemoryImage?>(
          key: ObjectKey(imageFuture),
          future: imageFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: LinearProgressIndicator(
                  semanticsLabel: 'Loading photograph',
                ),
              );
            }

            if (snapshot.hasError || snapshot.data == null) {
              return unavailable(context);
            }

            return thumbnail(snapshot.data!);
          },
        );
      },
    );
  }
}

Widget _servoraPhotoUnavailable(BuildContext context) {
  final theme = Theme.of(context);
  final colors = theme.colorScheme;

  return Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 38,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: 10),
          Text(
            'Photograph unavailable',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            'The image may be unavailable, restricted '
            'or require an internet connection.',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _ServoraFullscreenImage extends StatefulWidget {
  final String path;
  final String title;
  final String userId;

  const _ServoraFullscreenImage({
    required this.path,
    required this.title,
    required this.userId,
  });

  @override
  State<_ServoraFullscreenImage> createState() =>
      _ServoraFullscreenImageState();
}

class _ServoraFullscreenImageState extends State<_ServoraFullscreenImage> {
  final TransformationController zoomController = TransformationController();

  late final Stream<User?> authStream;

  late Future<DocumentSnapshot<RowData>> imageFuture;

  TapDownDetails? doubleTapDetails;

  @override
  void initState() {
    super.initState();

    authStream = FirebaseAuth.instance.authStateChanges();

    imageFuture = loadImage();
  }

  Future<DocumentSnapshot<RowData>> loadImage() {
    return db.doc(widget.path).get(
          const GetOptions(source: Source.server),
        );
  }

  @override
  void dispose() {
    zoomController.dispose();
    super.dispose();
  }

  void resetZoom() {
    zoomController.value = Matrix4.identity();
  }

  void doubleTapZoom() {
    final scale = zoomController.value.getMaxScaleOnAxis();

    if (scale > 1.05) {
      resetZoom();
      return;
    }

    final position = doubleTapDetails?.localPosition;

    if (position == null) return;

    const targetScale = 2.5;

    zoomController.value = Matrix4.identity()
      ..setEntry(0, 0, targetScale)
      ..setEntry(1, 1, targetScale)
      ..setEntry(2, 2, targetScale)
      ..setEntry(0, 3, -position.dx * (targetScale - 1))
      ..setEntry(1, 3, -position.dy * (targetScale - 1));
  }

  Widget unavailable({
    bool retry = true,
    String message = 'Unable to display this photograph.',
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.image_not_supported_outlined,
              color: Colors.white70,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            if (retry) ...[
              const SizedBox(height: 10),
              const Text(
                'Check your connection or image access.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(
                    color: Colors.white54,
                  ),
                ),
                onPressed: () {
                  resetZoom();

                  setState(() {
                    imageFuture = loadImage();
                  });
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget imageContent(Blob image) {
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTapDown: (details) {
              doubleTapDetails = details;
            },
            onDoubleTap: doubleTapZoom,
            child: InteractiveViewer(
              transformationController: zoomController,
              minScale: 1,
              maxScale: 5,
              panEnabled: true,
              scaleEnabled: true,
              clipBehavior: Clip.hardEdge,
              child: SizedBox.expand(
                child: Image.memory(
                  image.bytes,
                  fit: BoxFit.contain,
                  semanticLabel: widget.title,
                  errorBuilder: (context, error, stackTrace) {
                    return unavailable(
                      retry: false,
                      message: 'This image could not be decoded.',
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            width: double.infinity,
            color: const Color(0xFF111111),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.zoom_in_rounded,
                  color: Colors.white70,
                  size: 22,
                ),
                SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'Pinch to zoom or double-tap to enlarge',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Close photograph',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Reset zoom',
            onPressed: resetZoom,
            icon: const Icon(
              Icons.fit_screen_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<User?>(
          stream: authStream,
          initialData: FirebaseAuth.instance.currentUser,
          builder: (context, authSnapshot) {
            if (authSnapshot.data?.uid != widget.userId ||
                FirebaseAuth.instance.currentUser?.uid != widget.userId) {
              return unavailable(
                retry: false,
                message: 'Your session has changed. Close this viewer.',
              );
            }

            return FutureBuilder<DocumentSnapshot<RowData>>(
              future: imageFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return unavailable();
                }

                if (snapshot.connectionState != ConnectionState.done ||
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      semanticsLabel: 'Loading fullscreen photograph',
                    ),
                  );
                }

                final image = snapshot.data!.data()?['bytes'];

                if (image is! Blob ||
                    image.bytes.isEmpty ||
                    image.bytes.length > 307200) {
                  return unavailable();
                }

                return imageContent(image);
              },
            );
          },
        ),
      ),
    );
  }
}
