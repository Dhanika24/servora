part of '../../main.dart';

class AccountSettings extends StatelessWidget {
  const AccountSettings({super.key});

  Widget settingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 4,
          ),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 21,
              color: colors.onPrimaryContainer,
            ),
          ),
          title: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: colors.onSurfaceVariant,
          ),
          onTap: onTap,
        );
      },
    );
  }

  Widget settingsGroup(List<Widget> children) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0)
              const Divider(
                height: 1,
                indent: 68,
                endIndent: 14,
              ),
            children[index],
          ],
        ],
      ),
    );
  }

  Widget sectionTitle(
    BuildContext context,
    String title,
  ) {
    final theme = Theme.of(context);

    final icon = switch (title) {
      'Personal information' => Icons.person_outline,
      'Business settings' => Icons.business_center_outlined,
      'Activity' => Icons.history_rounded,
      'Privacy and security' => Icons.shield_outlined,
      _ => Icons.tune_rounded,
    };

    return Padding(
      padding: const EdgeInsets.only(
        top: 10,
        bottom: 2,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> resetPreferences(BuildContext context) async {
    final userId = uid;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset preferences?'),
        content: const Text(
          'Appearance and notification preferences will '
          'return to their default values. Your account, '
          'service records and personal information '
          'will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    if (FirebaseAuth.instance.currentUser?.uid != userId) {
      return;
    }

    await handle(context, () async {
      await appPreferences.setNotification(
        userId,
        'quotations',
        true,
      );

      await appPreferences.setNotification(
        userId,
        'requests',
        true,
      );

      await appPreferences.setNotification(
        userId,
        'jobUpdates',
        true,
      );

      await appPreferences.setTheme(ThemeMode.system);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Application preferences restored.',
            ),
          ),
        );
      }
    });
  }

  static Future<void> signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Are you sure you want to sign out of Servora?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await handle(context, () async {
      final userId = uid;

      try {
        await db
            .collection('devices')
            .doc(userId)
            .delete()
            .timeout(const Duration(seconds: 3));
      } catch (_) {
        debugPrint('Device registration cleanup unavailable.');
      }

      await FirebaseAuth.instance.signOut();

      if (context.mounted) {
        Navigator.of(context).popUntil(
          (route) => route.isFirst,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return page('My account', [
        const Text('Please sign in first.'),
      ]);
    }

    return _ServoraDocumentListener(
      path: 'members/${user.uid}',
      userId: user.uid,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return page('My account', [
            const Text('Unable to load account information.'),
            OutlinedButton.icon(
              onPressed: () => signOut(context),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
            ),
          ]);
        }

        if (!snapshot.hasData) {
          return page('My account', [
            const LinearProgressIndicator(),
            OutlinedButton.icon(
              onPressed: () => signOut(context),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
            ),
          ]);
        }

        final member = snapshot.data!.data();

        if (member == null) {
          return page('My account', [
            const Text('Account information unavailable.'),
            OutlinedButton.icon(
              onPressed: () => signOut(context),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
            ),
          ]);
        }

        final isProvider = member['role'] == 'provider';

        final name = member['name'].toString();

        final theme = Theme.of(context);
        final colors = theme.colorScheme;

        return page('My account', [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.manage_accounts_outlined,
                        size: 20,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'YOUR ACCOUNT',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AccountProfilePhoto(
                    key: ValueKey(user.uid),
                    userId: user.uid,
                    name: name,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email ?? 'Email unavailable',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      isProvider ? 'Service provider' : 'Customer',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => go(
                      context,
                      EditDisplayName(currentName: name),
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit profile'),
                  ),
                ],
              ),
            ),
          ),
          sectionTitle(context, 'Personal information'),
          settingsGroup([
            settingTile(
              title: 'Display name',
              subtitle: name,
              icon: Icons.person_outline,
              onTap: () => go(
                context,
                EditDisplayName(currentName: name),
              ),
            ),
            _ServoraDocumentListener(
              path: 'privateContacts/${user.uid}',
              userId: user.uid,
              builder: (context, contactSnapshot) {
                final contact = contactSnapshot.data?.data();

                return settingTile(
                  title: 'Mobile number',
                  subtitle: contactSnapshot.hasError
                      ? 'Contact unavailable'
                      : !contactSnapshot.hasData
                          ? 'Loading...'
                          : contact?['phone']?.toString() ??
                              'Add your mobile number',
                  icon: Icons.phone_outlined,
                  onTap: () => go(
                    context,
                    const MobileSettings(),
                  ),
                );
              },
            ),
            settingTile(
              title: 'Email address',
              subtitle: user.email ?? 'Unavailable',
              icon: Icons.email_outlined,
              onTap: () => go(
                context,
                const AccountSecurity(changeEmail: true),
              ),
            ),
            settingTile(
              title: 'Change password',
              subtitle: 'Manage your account password',
              icon: Icons.password_outlined,
              onTap: () => go(
                context,
                const AccountSecurity(changeEmail: false),
              ),
            ),
          ]),
          if (isProvider) ...[
            sectionTitle(context, 'Business settings'),
            settingsGroup([
              settingTile(
                title: 'My services',
                subtitle: 'Manage services, rates and availability',
                icon: Icons.business_center_outlined,
                onTap: () => go(
                  context,
                  const MyServices(),
                ),
              ),
              settingTile(
                title: 'Performance and rewards',
                subtitle: 'Rank, points and completed work',
                icon: Icons.workspace_premium_outlined,
                onTap: () => go(
                  context,
                  Profile(id: user.uid),
                ),
              ),
            ]),
          ],
          sectionTitle(context, 'Activity'),
          settingsGroup([
            settingTile(
              title: 'My jobs',
              subtitle: 'View your service activity',
              icon: Icons.assignment_outlined,
              onTap: () => _openMainTab(
                context,
                _ServoraTab.jobs,
                JobList(provider: isProvider),
              ),
            ),
            settingTile(
              title: 'Notifications',
              subtitle: 'View your latest updates',
              icon: Icons.notifications_outlined,
              onTap: () => _openMainTab(
                context,
                _ServoraTab.alerts,
                NotificationCenter(provider: isProvider),
              ),
            ),
            settingTile(
              title: 'Notification preferences',
              subtitle: 'Customize your service and job updates',
              icon: Icons.notifications_active_outlined,
              onTap: () => go(
                context,
                NotificationSettings(provider: isProvider),
              ),
            ),
          ]),
          sectionTitle(context, 'Privacy and security'),
          settingsGroup([
            settingTile(
              title: 'Privacy centre',
              subtitle: 'Understand how your information is used',
              icon: Icons.privacy_tip_outlined,
              onTap: () => go(
                context,
                const PrivacyCenter(),
              ),
            ),
            settingTile(
              title: 'Location settings',
              subtitle: 'Manage GPS access and location permissions',
              icon: Icons.location_on_outlined,
              onTap: () => go(
                context,
                const ServoraLocationSettings(),
              ),
            ),
            settingTile(
              title: 'Contact privacy',
              subtitle: 'Understand how contact details are shared',
              icon: Icons.lock_outline,
              onTap: () => go(
                context,
                page('Contact privacy', [
                  const Text(
                    'Your mobile number is not displayed '
                    'publicly in your service profile.',
                  ),
                  card(
                    'Quotations',
                    'Contact details are shared with relevant '
                        'participants after quotation submission.',
                  ),
                  card(
                    'Active jobs',
                    'After booking, contact access is restricted '
                        'to the customer and selected provider.',
                  ),
                  card(
                    'Completed jobs',
                    'Cross-account contact access is removed '
                        'after the job is completed.',
                  ),
                  const Text(
                    'Servora cannot remove contact details '
                    'that another participant has already saved.',
                  ),
                ]),
              ),
            ),
          ]),
          sectionTitle(context, 'Application'),
          settingsGroup([
            settingTile(
              title: 'Reset preferences',
              subtitle: 'Restore default application settings',
              icon: Icons.restart_alt,
              onTap: () => resetPreferences(context),
            ),
            settingTile(
              title: 'Help and support',
              subtitle: 'Frequently asked questions and guidance',
              icon: Icons.support_agent,
              onTap: () => go(
                context,
                HelpCenter(provider: isProvider),
              ),
            ),
            settingTile(
              title: 'Appearance',
              subtitle: 'Light, dark and system themes',
              icon: Icons.palette_outlined,
              onTap: () => go(
                context,
                const AppearanceSettings(),
              ),
            ),
            settingTile(
              title: 'About Servora',
              subtitle: 'Learn more about the application',
              icon: Icons.info_outline,
              onTap: () => go(
                context,
                page('About Servora', [
                  _settingsPageIntro(
                    context,
                    label: 'ABOUT THE APPLICATION',
                    title: 'Servora',
                    description:
                        'An AI-assisted service marketplace connecting '
                        'customers with local professionals.',
                    icon: Icons.handshake_outlined,
                  ),
                  card(
                    'Our purpose',
                    'Connect customers with local professionals '
                        'through quotations, intelligent recommendations '
                        'and transparent service management.',
                  ),
                  card(
                    'Developed by',
                    'Group 50 - NSBM Green University',
                  ),
                  card(
                    'Technology',
                    'Flutter, Dart, Firebase Authentication, '
                        'Cloud Firestore and location services.',
                  ),
                  card(
                    'Intelligent recommendations',
                    'Multi-factor provider ranking using quotation prices, '
                        'ratings, experience, performance and approximate distances.',
                  ),
                  card(
                    'Project information',
                    'Mobile Application Development - SE303.3',
                  ),
                  card(
                    'Application version',
                    '0.1.0',
                  ),
                ]),
              ),
            ),
          ]),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.error,
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: () => signOut(context),
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
          const Text(
            'Servora v0.1.0',
            textAlign: TextAlign.center,
          ),
        ]);
      },
    );
  }
}

class EditDisplayName extends StatefulWidget {
  final String currentName;

  const EditDisplayName({
    required this.currentName,
    super.key,
  });

  @override
  State<EditDisplayName> createState() => _EditDisplayNameState();
}

class _EditDisplayNameState extends State<EditDisplayName> {
  late final TextEditingController nameController;

  bool busy = false;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(
      text: widget.currentName,
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> saveName() async {
    if (busy) return;

    setState(() => busy = true);

    try {
      final name = validatedText(
        nameController.text,
        80,
        'Enter a valid display name.',
      );

      final userId = uid;

      final memberRef = db.collection('members').doc(userId);

      final providerRef = db.collection('providers').doc(userId);

      await db.runTransaction((transaction) async {
        final memberSnapshot = await transaction.get(memberRef);

        final member = memberSnapshot.data();

        if (member == null) {
          throw Exception('Account information unavailable.');
        }

        final providerSnapshot = member['role'] == 'provider'
            ? await transaction.get(providerRef)
            : null;

        transaction.update(memberRef, {
          'name': name,
        });

        if (providerSnapshot?.exists == true) {
          transaction.update(providerRef, {
            'name': name,
          });
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully.'),
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
    return page('Edit profile', [
      const Icon(
        Icons.manage_accounts_outlined,
        size: 72,
        color: ink,
      ),
      const Text(
        'Personal information',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      TextField(
        controller: nameController,
        enabled: !busy,
        maxLength: 80,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Display name',
          prefixIcon: Icon(Icons.person_outline),
        ),
      ),
      const Text(
        'Your updated name will be used for future '
        'service requests and quotations.',
      ),
      FilledButton.icon(
        onPressed: busy ? null : saveName,
        icon: const Icon(Icons.save_outlined),
        label: Text(
          busy ? 'Saving...' : 'Save changes',
        ),
      ),
    ]);
  }
}
