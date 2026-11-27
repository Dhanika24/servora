part of '../main.dart';

class ServoraLoadingScreen extends StatelessWidget {
  const ServoraLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ServoraMark(size: 100),
                const SizedBox(height: 24),
                Text(
                  'Servora',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Trusted services, simplified.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: 110,
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Getting things ready...',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ServoraWelcomeGate extends StatefulWidget {
  const ServoraWelcomeGate({super.key});

  @override
  State<ServoraWelcomeGate> createState() => _ServoraWelcomeGateState();
}

class _ServoraWelcomeGateState extends State<ServoraWelcomeGate> {
  bool showLogin = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: showLogin
          ? const Login()
          : ServoraWelcomeScreen(
              onContinue: () {
                setState(() => showLogin = true);
              },
            ),
    );
  }
}

class ServoraWelcomeScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const ServoraWelcomeScreen({
    required this.onContinue,
    super.key,
  });

  Widget benefit(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: colors.onPrimaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.4,
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 560,
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                24,
                28,
                24,
                24,
              ),
              children: [
                const Center(
                  child: ServoraBrand(
                    markSize: 52,
                    showTagline: true,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Everyday services.\nMade simpler.',
                  style: theme.textTheme.headlineLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  'Find local professionals, compare quotations '
                  'and manage your services in one place.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                ServoraHeroBanner(
                  title: 'The right help starts here.',
                  description: 'Discover services or grow your own '
                      'service business.',
                  buttonLabel: 'Get started',
                  onPressed: onContinue,
                ),
                const SizedBox(height: 28),
                Text(
                  'Why Servora?',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                benefit(
                  context,
                  icon: Icons.home_repair_service_outlined,
                  title: 'Services for everyday needs',
                  description: 'Explore eight local service categories.',
                ),
                benefit(
                  context,
                  icon: Icons.auto_awesome_outlined,
                  title: 'Intelligent recommendations',
                  description: 'Compare providers based on your priorities.',
                ),
                benefit(
                  context,
                  icon: Icons.assignment_turned_in_outlined,
                  title: 'Simple service management',
                  description: 'Manage quotations, bookings and job updates.',
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onContinue,
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                  ),
                  label: const Text(
                    'Continue to Servora',
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onContinue,
                  child: const Text(
                    'Already have an account? Sign in',
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'SERVORA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
