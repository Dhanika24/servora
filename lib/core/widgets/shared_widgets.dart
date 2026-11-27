part of '../../main.dart';

Widget page(String title, List<Widget> children) {
  return Scaffold(
    appBar: AppBar(
      title:
          title == 'Servora' ? const ServoraBrand(markSize: 36) : Text(title),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 680,
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              for (final widget in children)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: widget,
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget action(String text, VoidCallback fn) {
  return FilledButton(
    onPressed: fn,
    child: Text(text),
  );
}

Widget card(
  String title,
  String detail, [
  VoidCallback? fn,
]) {
  return Card(
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(detail),
      ),
      onTap: fn,
      trailing: fn == null
          ? null
          : const Icon(
              Icons.chevron_right_rounded,
            ),
    ),
  );
}

void go(BuildContext c, Widget w) {
  Navigator.push(
    c,
    MaterialPageRoute(
      builder: (_) => w,
    ),
  );
}

String _servoraFirebaseError(FirebaseException error) {
  return switch (error.code) {
    'permission-denied' => 'You do not have permission to perform this action.',
    'unauthenticated' => 'Please sign in again to continue.',
    'unavailable' ||
    'network-request-failed' =>
      'Connection unavailable. Check your internet and try again.',
    'deadline-exceeded' => 'The operation took too long. Please try again.',
    'not-found' => 'The requested information is no longer available.',
    'already-exists' => 'This record already exists.',
    'aborted' =>
      'The information changed during the operation. Please try again.',
    'resource-exhausted' =>
      'The service is temporarily unavailable. Try again later.',
    'failed-precondition' =>
      'This operation cannot be completed in its current state.',
    'invalid-argument' => 'Check the information you entered and try again.',
    'email-already-in-use' =>
      'This email address is already associated with an account.',
    'invalid-email' => 'Enter a valid email address.',
    'weak-password' => 'Choose a stronger password.',
    'wrong-password' ||
    'invalid-credential' =>
      'The supplied credentials are incorrect.',
    'requires-recent-login' =>
      'Sign in again before changing sensitive account information.',
    'too-many-requests' => 'Too many attempts. Please try again later.',
    _ => 'Unable to complete the operation. Please try again.',
  };
}

void _servoraErrorMessage(
  BuildContext context,
  String message,
) {
  if (!context.mounted) return;

  final colors = Theme.of(context).colorScheme;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: colors.errorContainer,
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: colors.onErrorContainer,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: colors.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}

Future<void> handle(
  BuildContext c,
  Future<void> Function() fn,
) async {
  try {
    await fn();
  } on FirebaseException catch (error) {
    debugPrint(
      'Servora Firebase operation failed: ${error.code}',
    );

    if (c.mounted) {
      _servoraErrorMessage(
        c,
        _servoraFirebaseError(error),
      );
    }
  } on Exception catch (error) {
    if (c.mounted) {
      _servoraErrorMessage(
        c,
        error.toString().replaceFirst('Exception: ', ''),
      );
    }
  } catch (error) {
    debugPrint(
      'Servora unexpected operation failure: ${error.runtimeType}',
    );

    if (c.mounted) {
      _servoraErrorMessage(
        c,
        'Something went wrong. Please try again.',
      );
    }
  }
}

Widget _servoraInlineState(
  BuildContext context, {
  required String title,
  required String description,
  required IconData icon,
  bool error = false,
}) {
  final theme = Theme.of(context);
  final colors = theme.colorScheme;

  final background = error ? colors.errorContainer : colors.primaryContainer;

  final foreground =
      error ? colors.onErrorContainer : colors.onPrimaryContainer;

  return Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: foreground,
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
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
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

Widget rows(
  Query<RowData> q,
  Widget Function(String, RowData) item,
) {
  final userId = FirebaseAuth.instance.currentUser?.uid;

  if (userId == null) {
    return const SizedBox.shrink();
  }

  return _ServoraQueryListener(
    query: q,
    userId: userId,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _servoraInlineState(
          context,
          title: 'Information unavailable',
          description: 'Unable to load these records. Check your connection '
              'or reopen this page.',
          icon: Icons.cloud_off_outlined,
          error: true,
        );
      }

      if (!snapshot.hasData) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: LinearProgressIndicator(
            semanticsLabel: 'Loading service records',
          ),
        );
      }

      final documents = snapshot.data!.docs;

      if (documents.isEmpty) {
        return _servoraInlineState(
          context,
          title: 'Nothing here yet',
          description: 'Available records will appear here.',
          icon: Icons.inbox_outlined,
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final document in documents) item(document.id, document.data()),
        ],
      );
    },
  );
}

String servoraMoney(Object? value) {
  if (value is! num || !value.isFinite) {
    return 'LKR -';
  }

  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');

  if (parts.length != 2) {
    return 'LKR $fixed';
  }

  final whole = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );

  return 'LKR $whole.${parts.last}';
}

class _ServoraDocumentListener extends StatefulWidget {
  final String path;
  final String userId;
  final bool includeMetadataChanges;
  final AsyncWidgetBuilder<DocumentSnapshot<RowData>> builder;

  const _ServoraDocumentListener({
    required this.path,
    required this.userId,
    required this.builder,
    this.includeMetadataChanges = false,
    super.key,
  });

  @override
  State<_ServoraDocumentListener> createState() =>
      _ServoraDocumentListenerState();
}

class _ServoraDocumentListenerState extends State<_ServoraDocumentListener> {
  Stream<DocumentSnapshot<RowData>>? documentStream;

  @override
  void initState() {
    super.initState();
    initializeStream();
  }

  void initializeStream() {
    documentStream = FirebaseAuth.instance.currentUser?.uid == widget.userId
        ? db.doc(widget.path).snapshots(
              includeMetadataChanges: widget.includeMetadataChanges,
            )
        : null;
  }

  @override
  void didUpdateWidget(
    covariant _ServoraDocumentListener oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.path != widget.path ||
        oldWidget.userId != widget.userId ||
        oldWidget.includeMetadataChanges != widget.includeMetadataChanges) {
      initializeStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser?.uid != widget.userId) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<DocumentSnapshot<RowData>>(
      key: ValueKey(
        '${widget.userId}/${widget.path}/'
        '${widget.includeMetadataChanges}',
      ),
      stream: documentStream,
      builder: (context, snapshot) {
        if (FirebaseAuth.instance.currentUser?.uid != widget.userId) {
          return const SizedBox.shrink();
        }

        return widget.builder(context, snapshot);
      },
    );
  }
}

class _ServoraQueryListener extends StatefulWidget {
  final Query<RowData> query;
  final String userId;
  final bool includeMetadataChanges;
  final AsyncWidgetBuilder<QuerySnapshot<RowData>> builder;

  const _ServoraQueryListener({
    required this.query,
    required this.userId,
    required this.builder,
    this.includeMetadataChanges = false,
  });

  @override
  State<_ServoraQueryListener> createState() => _ServoraQueryListenerState();
}

class _ServoraQueryListenerState extends State<_ServoraQueryListener> {
  late Stream<QuerySnapshot<RowData>> queryStream;

  @override
  void initState() {
    super.initState();

    initializeStream();
  }

  void initializeStream() {
    queryStream = widget.query.snapshots(
      includeMetadataChanges: widget.includeMetadataChanges,
    );
  }

  @override
  void didUpdateWidget(
    covariant _ServoraQueryListener oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.query != widget.query ||
        oldWidget.userId != widget.userId ||
        oldWidget.includeMetadataChanges != widget.includeMetadataChanges) {
      initializeStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser?.uid != widget.userId) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot<RowData>>(
      key: ObjectKey(queryStream),
      stream: queryStream,
      builder: (context, snapshot) {
        if (FirebaseAuth.instance.currentUser?.uid != widget.userId) {
          return const SizedBox.shrink();
        }

        return widget.builder(
          context,
          snapshot,
        );
      },
    );
  }
}
