part of '../../main.dart';

Widget _servoraJobHeading(
  BuildContext context,
  IconData icon,
  String title,
) {
  final theme = Theme.of(context);
  final colors = theme.colorScheme;

  return Row(
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
          size: 24,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          title,
          style: theme.textTheme.titleLarge,
        ),
      ),
    ],
  );
}

class _ServoraJobHeader extends StatelessWidget {
  final RowData job;

  const _ServoraJobHeader({
    required this.job,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    final category = job['category']?.toString() ?? 'Service';

    final status = job['status']?.toString() ?? '';

    final label = switch (status) {
      'open' => 'Awaiting quotations',
      'booked' => 'Booking confirmed',
      'in progress' => 'Work in progress',
      'awaiting review' => 'Awaiting review',
      'completed' => 'Completed',
      _ => 'Status unavailable',
    };

    final statusColor = switch (status) {
      'completed' => dark ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
      'awaiting review' =>
        dark ? const Color(0xFFFCD34D) : const Color(0xFFB45309),
      'in progress' => dark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
      _ => colors.primary,
    };

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ServiceCategoryIcon(
                  category: category,
                  size: 68,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        job['title']?.toString() ?? 'Service request',
                        style: theme.textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    status == 'completed'
                        ? Icons.check_circle_outline
                        : Icons.schedule_rounded,
                    color: statusColor,
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: colors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    job['area']?.toString() ?? 'Location unavailable',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job['amount'] != null ? 'Agreed price' : 'Customer budget',
                    style: TextStyle(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    servoraMoney(job['amount'] ?? job['budget']),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (job['amount'] != null) ...[
              const SizedBox(height: 10),
              Text(
                "Original budget: ${servoraMoney(job['budget'])}",
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 22),
            Text(
              'About this request',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Text(
              job['description']?.toString() ?? 'No description provided.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Job extends StatelessWidget {
  final String id;

  const Job({
    required this.id,
    super.key,
  });

  Widget quotationSection(
    BuildContext context,
    DocumentReference<RowData> ref,
    RowData job,
  ) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const SizedBox.shrink();
    }

    return _ServoraQueryListener(
      query: ref.collection('quotes'),
      userId: userId,
      includeMetadataChanges: true,
      builder: (context, snapshot) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;

        final count = snapshot.data?.docs.length;
        final cached = snapshot.data?.metadata.isFromCache ?? false;

        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _servoraJobHeading(
                  context,
                  Icons.request_quote_outlined,
                  'Provider quotations',
                ),
                const SizedBox(height: 20),
                if (snapshot.hasError)
                  const Text(
                    'Unable to load quotations.',
                  )
                else if (count == null)
                  const LinearProgressIndicator()
                else ...[
                  if (cached) ...[
                    const Text(
                      'Showing saved quotation data.',
                    ),
                    const SizedBox(height: 10),
                  ],
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          count == 0
                              ? Icons.hourglass_empty_rounded
                              : Icons.receipt_long_outlined,
                          size: 40,
                          color: colors.onPrimaryContainer,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$count',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          count == 1
                              ? 'Quotation received'
                              : 'Quotations received',
                          style: TextStyle(
                            color: colors.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    count == 0
                        ? cached
                            ? 'No quotations in saved data.'
                            : 'Available professionals can submit quotations for your request.'
                        : count == 1
                            ? 'Review the quotation and provider details.'
                            : 'Compare providers based on your budget, quality and preferences.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (count > 0) ...[
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () => go(
                        context,
                        Discover(
                          job: job,
                          jobId: id,
                        ),
                      ),
                      icon: Icon(
                        count == 1
                            ? Icons.receipt_long_outlined
                            : Icons.compare_arrows_rounded,
                      ),
                      label: Text(
                        count == 1
                            ? 'View quotation'
                            : 'View and compare quotations',
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return page('Job details', [
        const Text('Please sign in to view this service request.'),
      ]);
    }

    final ref = db.collection('jobs').doc(id);

    return _ServoraDocumentListener(
      key: ValueKey('job/$userId/$id'),
      path: ref.path,
      userId: userId,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return page('Service request', [
            const Text('This request is unavailable.'),
          ]);
        }

        if (!snapshot.hasData) {
          return page('Service request', [
            const LinearProgressIndicator(),
          ]);
        }

        final job = snapshot.data!.data();

        if (job == null) {
          return page('Service request', [
            const Text('Service request not found.'),
          ]);
        }

        final owner = job['owner'] == uid;
        final assigned = job['assigned'] == uid;
        final status = job['status'].toString();

        return page('Job details', [
          _ServoraJobHeader(job: job),
          photoView(
            job['photo'],
            accessRevision: (
              status,
              job['owner'],
              job['assigned'],
            ),
          ),
          JobTimeline(job: job),
          if (owner ||
              (assigned &&
                  const [
                    'booked',
                    'in progress',
                    'awaiting review',
                  ].contains(status)))
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _servoraJobHeading(context, Icons.location_on_outlined,
                        'Service location'),
                    const SizedBox(height: 8),
                    Text(job['area'].toString()),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => handle(context, () async {
                        final location =
                            await ref.collection('locations').doc('exact').get(
                                  const GetOptions(source: Source.server),
                                );

                        final data = location.data();

                        if (data == null) {
                          throw Exception(
                            'Precise location is not recorded for this job.',
                          );
                        }

                        final lat = data['lat'];
                        final lng = data['lng'];

                        if (lat is! num ||
                            lng is! num ||
                            !lat.isFinite ||
                            !lng.isFinite ||
                            lat < -90 ||
                            lat > 90 ||
                            lng < -180 ||
                            lng > 180) {
                          throw Exception(
                            'The saved location is invalid.',
                          );
                        }

                        if (!context.mounted) return;

                        final opened = await launchUrl(
                          Uri.https(
                            'www.google.com',
                            '/maps/search/',
                            {
                              'api': '1',
                              'query': '$lat,$lng',
                            },
                          ),
                          mode: LaunchMode.externalApplication,
                        );

                        if (!opened) {
                          throw Exception('Unable to open Maps.');
                        }
                      }),
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Open location in Maps'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      owner
                          ? 'Your precise service location.'
                          : 'Location shared for your active booking.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lock_outline,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Precise location is protected',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Service area: ${job['area']}',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      status == 'completed'
                          ? 'Precise location access ends when the job is completed.'
                          : 'Precise location becomes available only after your quotation is accepted.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          if (owner && status == 'open') JobContactShare(jobId: id),
          if (!owner && status == 'open')
            OpenQuotationContact(
              jobId: id,
              customerId: job['owner'].toString(),
            ),
          if ((owner || assigned) &&
              const [
                'booked',
                'in progress',
                'awaiting review',
              ].contains(status)) ...[
            JobContactShare(jobId: id),
            JobContactPanel(
              jobId: id,
              contactUid:
                  owner ? job['assigned'].toString() : job['owner'].toString(),
              label: owner ? 'Contact your provider' : 'Contact your customer',
            ),
          ],
          if (owner && status == 'open') quotationSection(context, ref, job),
          if (!owner && status == 'open')
            _ServoraDocumentListener(
              key: ValueKey('quotation/$id/$userId'),
              path: 'jobs/$id/quotes/$userId',
              userId: userId,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text(
                    'Unable to load quotation information.',
                  );
                }

                if (!snapshot.hasData) {
                  return const LinearProgressIndicator();
                }

                final quote = snapshot.data!.data();

                return ProviderQuotationGate(
                  category: job['category'],
                  child: FilledButton.icon(
                    onPressed: () => go(
                      context,
                      Editor(
                        mode: 'quote',
                        jobId: id,
                        initial: quote,
                      ),
                    ),
                    icon: Icon(
                      quote == null ? Icons.receipt_long : Icons.edit_outlined,
                    ),
                    label: Text(
                      quote == null ? 'Send quotation' : 'Edit quotation',
                    ),
                  ),
                );
              },
            ),
          if (job['amount'] != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _servoraJobHeading(
                        context, Icons.handshake_outlined, 'Booking details'),
                    const SizedBox(height: 10),
                    Text(
                      'Provider: ${job['providerName']}',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Agreed price: ${servoraMoney(job['amount'])}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (assigned && status == 'booked')
            action(
              'Start job',
              () => handle(
                context,
                () => send('start', {
                  'jobId': id,
                }),
              ),
            ),
          if (assigned && status == 'in progress')
            action(
              'Submit work result',
              () => go(
                context,
                Editor(
                  mode: 'finish',
                  jobId: id,
                ),
              ),
            ),
          if (job['summary'] != null) ...[
            card(
              'Completed work summary',
              job['summary'].toString(),
            ),
            photoView(
              job['result'],
              accessRevision: (
                status,
                job['owner'],
                job['assigned'],
              ),
            ),
          ],
          if (owner && status == 'awaiting review')
            action(
              'Confirm and review',
              () => go(
                context,
                Editor(
                  mode: 'review',
                  jobId: id,
                ),
              ),
            ),
          if (status == 'completed')
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _servoraJobHeading(
                        context, Icons.star_outline_rounded, 'Customer review'),
                    const SizedBox(height: 10),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      runSpacing: 8,
                      children: [
                        for (int i = 0; i < 5; i++)
                          Icon(
                            i < (job['stars'] as num).toInt()
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                          ),
                        const SizedBox(width: 8),
                        Text('${job['stars']}/5'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(job['feedback'].toString()),
                    const Divider(height: 24),
                    Text(
                      'Service charge: ${servoraMoney(job['serviceCharge'])} '
                      '(${job['feePercent']}%)',
                    ),
                  ],
                ),
              ),
            ),
        ]);
      },
    );
  }
}
