part of '../../main.dart';

Future<void> synchronizeJobContact(String jobId) async {
  final userId = uid;

  final privateRef = db.collection('privateContacts').doc(userId);

  final sharedRef =
      db.collection('jobs').doc(jobId).collection('contacts').doc(userId);

  await db.runTransaction((transaction) async {
    final privateSnapshot = await transaction.get(privateRef);

    final sharedSnapshot = await transaction.get(sharedRef);

    final phone = savedContactPhone(
      privateSnapshot.data(),
    );

    if (sharedSnapshot.data()?['phone'] != phone) {
      transaction.set(sharedRef, {
        'phone': phone,
      });
    }
  });
}

class JobContactShare extends StatefulWidget {
  final String jobId;

  const JobContactShare({
    required this.jobId,
    super.key,
  });

  @override
  State<JobContactShare> createState() => _JobContactShareState();
}

class _JobContactShareState extends State<JobContactShare> {
  late Future<void> synchronization;

  @override
  void initState() {
    super.initState();

    synchronization = synchronizeJobContact(widget.jobId);
  }

  @override
  void didUpdateWidget(JobContactShare oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.jobId != widget.jobId) {
      synchronization = synchronizeJobContact(widget.jobId);
    }
  }

  void refreshContact() {
    setState(() {
      synchronization = synchronizeJobContact(widget.jobId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: synchronization,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _servoraJobHeading(context, Icons.verified_user_outlined,
                    'Your contact information'),
                const SizedBox(height: 8),
                if (loading)
                  const LinearProgressIndicator()
                else if (snapshot.hasError)
                  const Text(
                    'Unable to share your mobile number. '
                    'Check your account settings and try again.',
                  )
                else
                  const Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your contact number is shared securely.',
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: loading ? null : refreshContact,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh contact'),
                    ),
                    TextButton(
                      onPressed: loading
                          ? null
                          : () => go(
                                context,
                                const AccountSettings(),
                              ),
                      child: const Text('My account'),
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

class JobContactPanel extends StatelessWidget {
  final String jobId;
  final String contactUid;
  final String label;

  const JobContactPanel({
    required this.jobId,
    required this.contactUid,
    required this.label,
    super.key,
  });

  DocumentReference<RowData> get contactRef =>
      db.collection('jobs').doc(jobId).collection('contacts').doc(contactUid);

  Future<String> currentPhone() async {
    final snapshot = await contactRef.get(
      const GetOptions(source: Source.server),
    );

    final phone = snapshot.data()?['phone'];

    if (phone is! String || !RegExp(r'^\+947[0-9]{8}$').hasMatch(phone)) {
      throw Exception(
        'Contact information is unavailable.',
      );
    }

    return phone;
  }

  Future<void> callContact() async {
    final phone = await currentPhone();

    final opened = await launchUrl(
      Uri(
        scheme: 'tel',
        path: phone,
      ),
      mode: LaunchMode.externalApplication,
    );

    if (!opened) {
      throw Exception(
        'Unable to open the phone dialer.',
      );
    }
  }

  Future<void> openWhatsApp() async {
    final phone = await currentPhone();

    final number = phone.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    final opened = await launchUrl(
      Uri.https(
        'wa.me',
        '/$number',
      ),
      mode: LaunchMode.externalApplication,
    );

    if (!opened) {
      throw Exception(
        'Unable to open WhatsApp.',
      );
    }
  }

  Future<void> copyPhone(
    BuildContext context,
  ) async {
    final phone = await currentPhone();

    await Clipboard.setData(
      ClipboardData(text: phone),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Phone number copied.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const SizedBox.shrink();
    }

    return _ServoraDocumentListener(
      path: contactRef.path,
      userId: userId,
      includeMetadataChanges: true,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return card(
            label,
            'Contact information is currently unavailable. '
            'The other participant may need to refresh '
            'their contact details.',
          );
        }

        if (!snapshot.hasData) {
          return const LinearProgressIndicator();
        }

        if (snapshot.data!.metadata.isFromCache) {
          return card(
            label,
            'Connecting to verify contact information...',
          );
        }

        final phone = snapshot.data!.data()?['phone'];

        if (phone is! String || !RegExp(r'^\+947[0-9]{8}$').hasMatch(phone)) {
          return card(
            label,
            'No contact number available.',
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _servoraJobHeading(context, Icons.phone_outlined, label),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.phone_outlined,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        phone,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () => handle(
                        context,
                        callContact,
                      ),
                      icon: const Icon(Icons.call),
                      label: const Text('Call'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => handle(
                        context,
                        openWhatsApp,
                      ),
                      icon: const Icon(
                        Icons.chat_outlined,
                        color: Colors.green,
                      ),
                      label: const Text('WhatsApp'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => handle(
                        context,
                        () => copyPhone(context),
                      ),
                      icon: const Icon(
                        Icons.copy_outlined,
                      ),
                      label: const Text('Copy'),
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

class OpenQuotationContact extends StatelessWidget {
  final String jobId;
  final String customerId;

  const OpenQuotationContact({
    required this.jobId,
    required this.customerId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const SizedBox.shrink();
    }

    return _ServoraDocumentListener(
      path: 'jobs/$jobId/quotes/$userId',
      userId: userId,
      includeMetadataChanges: true,
      builder: (context, snapshot) {
        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.metadata.isFromCache ||
            !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            JobContactShare(
              jobId: jobId,
            ),
            JobContactPanel(
              jobId: jobId,
              contactUid: customerId,
              label: 'Contact customer',
            ),
          ],
        );
      },
    );
  }
}
