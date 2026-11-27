part of '../main.dart';

class Servora extends StatefulWidget {
  final ThemeMode themeMode;

  const Servora({
    this.themeMode = ThemeMode.system,
    super.key,
  });

  @override
  State<Servora> createState() => _ServoraState();
}

class _ServoraState extends State<Servora> {
  late final Stream<User?> authStream;

  @override
  void initState() {
    super.initState();

    authStream = FirebaseAuth.instance.authStateChanges();
  }

  Widget accountUnavailable(
    BuildContext context,
    String description,
  ) {
    return page('Account', [
      _servoraInlineState(
        context,
        title: 'Account unavailable',
        description: description,
        icon: Icons.account_circle_outlined,
        error: true,
      ),
      OutlinedButton.icon(
        onPressed: () => handle(
          context,
          () => FirebaseAuth.instance.signOut(),
        ),
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Sign out'),
      ),
    ]);
  }

  Widget memberScreen(
    BuildContext context,
    User user,
  ) {
    return _ServoraDocumentListener(
      key: ValueKey('membership/${user.uid}'),
      path: 'members/${user.uid}',
      userId: user.uid,
      includeMetadataChanges: true,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return accountUnavailable(
            context,
            'Unable to load your account information. '
            'Check your connection and try signing in again.',
          );
        }

        if (!snapshot.hasData) {
          return const ServoraLoadingScreen();
        }

        final document = snapshot.data!;
        final member = document.data();

        if (member == null) {
          if (document.metadata.isFromCache) {
            return accountUnavailable(
              context,
              'An internet connection is required '
              'to verify your account information.',
            );
          }

          return const Register();
        }

        return Home(member: member);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Servora',
      debugShowCheckedModeBanner: false,
      themeMode: widget.themeMode,
      darkTheme: ServoraTheme.dark,
      theme: ServoraTheme.light,
      home: StreamBuilder<User?>(
        stream: authStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return accountUnavailable(
              context,
              'Unable to verify your authentication session.',
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ServoraLoadingScreen();
          }

          final user = snapshot.data;

          if (user == null) {
            return const ServoraWelcomeGate();
          }

          if (FirebaseAuth.instance.currentUser?.uid != user.uid) {
            return const ServoraLoadingScreen();
          }

          return memberScreen(
            context,
            user,
          );
        },
      ),
    );
  }
}
