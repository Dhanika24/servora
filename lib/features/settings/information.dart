part of '../../main.dart';

class PrivacyCenter extends StatelessWidget {
  const PrivacyCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return page('Privacy centre', [
      _settingsPageIntro(
        context,
        label: 'SERVORA PRIVACY',
        title: 'Your information matters',
        description: 'Understand how your information is used, protected '
            'and shared throughout the service process.',
        icon: Icons.privacy_tip_outlined,
      ),
      Text(
        'Information and protection',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      _settingsInformationCard(
        context,
        'Personal information',
        'Your account information is used to manage '
            'your profile, authentication and service activity.',
      ),
      _settingsInformationCard(
        context,
        'Contact information',
        'Mobile numbers are not publicly displayed. '
            'Relevant participants can access contact information '
            'after quotation submission. After booking, access '
            'is restricted to the customer and selected provider '
            'until job completion.',
      ),
      _settingsInformationCard(
        context,
        'Location information',
        'Approximate locations are used for recommendations '
            'and distance comparisons. Exact request coordinates '
            'are accessible to the customer and selected provider '
            'during an active booking.',
      ),
      _settingsInformationCard(
        context,
        'Profile photographs',
        'Your account profile photograph is private to your '
            'account. You can change or remove it from My account.',
      ),
      _settingsInformationCard(
        context,
        'Service photographs',
        'Request photographs are shared with eligible '
            'service participants. Completed work photographs '
            'may appear in a provider portfolio when the '
            'customer grants consent during the review.',
      ),
      _settingsInformationCard(
        context,
        'Account security',
        'Account authentication is managed using '
            'Firebase Authentication. Database access is '
            'controlled through security rules.',
      ),
      _settingsInformationCard(
        context,
        'Application preferences',
        'Appearance and notification preferences are '
            'stored locally on your device.',
      ),
      _settingsInformationCard(
        context,
        'Data storage',
        'Service information, job activity and account '
            'records are stored using cloud-based services.',
      ),
      _settingsInformationCard(
        context,
        'Your responsibility',
        'Avoid including unnecessary personal information '
            'in service descriptions, photographs and reviews. '
            'Information previously saved by another participant '
            'cannot be remotely removed from their device.',
      ),
      OutlinedButton.icon(
        onPressed: () => go(
          context,
          const ServoraLocationSettings(),
        ),
        icon: const Icon(Icons.location_on_outlined),
        label: const Text('Manage location permissions'),
      ),
    ]);
  }
}

class HelpCenter extends StatelessWidget {
  final bool provider;

  const HelpCenter({
    required this.provider,
    super.key,
  });

  Widget question(
    String title,
    String answer,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: PageStorageKey<String>('faq-$title'),
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 4,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16,
        ),
        leading: const Icon(Icons.help_outline_rounded),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Builder(
            builder: (context) {
              final theme = Theme.of(context);

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  answer,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return page('Help and support', [
      _settingsPageIntro(
        context,
        label: 'SERVORA HELP CENTRE',
        title: 'How can we help you?',
        description: 'Explore common questions about your account, '
            'service activity and application features.',
        icon: Icons.support_agent,
      ),
      Text(
        provider ? 'Provider guidance' : 'Customer guidance',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const Text('Select a question to view its answer.'),
      question(
        'What is Servora?',
        'Servora is a local service marketplace that '
            'connects customers with service professionals '
            'through quotations, recommendations and '
            'service management.',
      ),
      if (!provider) ...[
        question(
          'How do I request a service?',
          'Open your dashboard, select Request a service, '
              'choose a category, describe your requirements, '
              'enter your budget and location, and submit '
              'the request.',
        ),
        question(
          'How do I select a provider?',
          'Review the quotations received for your request. '
              'You can compare available providers and select '
              'the quotation that best suits your requirements.',
        ),
        question(
          'How do recommendations work?',
          'Servora uses factors such as quotation amount, '
              'estimated completion time, distance, ratings, '
              'experience and provider performance to rank '
              'available quotations. The final decision '
              'always belongs to you.',
        ),
        question(
          'How do I review completed work?',
          'Open your job after the provider submits '
              'the completed work. Review the results, '
              'provide a rating and feedback, and confirm '
              'completion.',
        ),
      ],
      if (provider) ...[
        question(
          'How do I add my services?',
          'Open My services and configure your service '
              'categories, rates, experience, availability '
              'and approximate service location.',
        ),
        question(
          'How do I submit a quotation?',
          'Open Available requests, select a suitable '
              'request and submit your price, estimated '
              'completion time and quotation details.',
        ),
        question(
          'How do performance rewards work?',
          'Points are earned through completed jobs, '
              'positive customer ratings, timely completion '
              'and quick responses. Accumulated points '
              'determine your provider rank.',
        ),
        question(
          'What are the provider ranks?',
          'Bronze is the starting rank. Silver requires '
              '50 points and Gold requires 120 points.',
        ),
        question(
          'How are service charges calculated?',
          'The service charge is calculated using the '
              'applicable provider rank and agreed job amount. '
              'Bronze has a 10% rate, Silver 8% and Gold 5%. '
              'The earnings dashboard shows calculated '
              'amounts, not verified payment transactions.',
        ),
        question(
          'Where can I view my earnings?',
          'Open My earnings to view completed job '
              'amounts, calculated service charges, '
              'net earnings and service breakdowns.',
        ),
      ],
      Text(
        'Account and troubleshooting',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      question(
        'Why is my location unavailable?',
        'Check whether device location services are enabled '
            'and Servora has location permission. You can '
            'manage these settings from My account.',
      ),
      question(
        'Why are notifications missing?',
        'Check your notification preferences and internet '
            'connection. Servora currently provides updates '
            'through its in-app activity centre.',
      ),
      question(
        'What if I forget my password?',
        'Use the password recovery option on the sign-in '
            'page and follow the instructions sent to your '
            'registered email address.',
      ),
      question(
        'Why is my information not loading?',
        'Check your internet connection and try reopening '
            'the affected page. Some operations require '
            'access to the online database.',
      ),
      question(
        'Does Servora process payments?',
        'The current version calculates job amounts, '
            'service charges and estimated net earnings. '
            'It does not process or verify actual payments.',
      ),
      OutlinedButton.icon(
        onPressed: () => go(
          context,
          const PrivacyCenter(),
        ),
        icon: const Icon(Icons.privacy_tip_outlined),
        label: const Text('Visit privacy centre'),
      ),
    ]);
  }
}

Widget _settingsPageIntro(
  BuildContext context, {
  required String title,
  required String description,
  required IconData icon,
  required String label,
}) {
  final theme = Theme.of(context);

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF007D70),
          Color(0xFF005D53),
          Color(0xFF003F38),
        ],
      ),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFFD9F5EC),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: const TextStyle(
            color: Color(0xFFD9F5EC),
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}

Widget _settingsInformationCard(
  BuildContext context,
  String title,
  String description,
) {
  final theme = Theme.of(context);
  final colors = theme.colorScheme;

  final icon = switch (title) {
    'Personal information' => Icons.person_outline,
    'Contact information' => Icons.phone_outlined,
    'Location information' => Icons.location_on_outlined,
    'Profile photographs' => Icons.account_circle_outlined,
    'Service photographs' => Icons.photo_library_outlined,
    'Account security' => Icons.shield_outlined,
    'Application preferences' => Icons.tune_rounded,
    'Data storage' => Icons.cloud_outlined,
    'Your responsibility' => Icons.info_outline,
    'Approximate locations' => Icons.map_outlined,
    'Protected request locations' => Icons.lock_outline,
    'Location access' => Icons.my_location,
    _ => Icons.info_outline,
  };

  return Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: colors.onPrimaryContainer,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.45,
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
