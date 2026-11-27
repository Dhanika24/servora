part of '../../main.dart';

String normalizePhone(String input) {
  String phone = input.trim().replaceAll(
        RegExp(r'[\s()-]'),
        '',
      );

  if (phone.startsWith('07')) {
    phone = '+94${phone.substring(1)}';
  } else if (phone.startsWith('947')) {
    phone = '+$phone';
  }

  if (!RegExp(r'^\+947[0-9]{8}$').hasMatch(phone)) {
    throw Exception(
      'Enter a valid Sri Lankan mobile number.',
    );
  }

  return phone;
}

Widget _servoraAuthPage(
  BuildContext context, {
  required String title,
  required String description,
  required List<Widget> children,
  bool back = false,
}) {
  final theme = Theme.of(context);
  final colors = theme.colorScheme;

  return Scaffold(
    appBar: back ? AppBar() : null,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            children: [
              const Center(
                child: ServoraBrand(
                  markSize: 52,
                  showTagline: true,
                ),
              ),
              const SizedBox(height: 36),
              Text(
                title,
                style: theme.textTheme.headlineLarge,
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 26),
              ...children,
              const SizedBox(height: 30),
              Text(
                'SERVORA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 11,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _servoraAuthCard(List<Widget> children) {
  return Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            children[i],
          ],
        ],
      ),
    ),
  );
}

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _Login();
}

class _Login extends State<Login> {
  String email = '';
  String password = '';

  bool signup = false;
  bool busy = false;
  bool hidePassword = true;

  Future<void> submit() async {
    if (busy) return;

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid email address.'),
        ),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your password.'),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => busy = true);

    try {
      await handle(context, () async {
        if (signup) {
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
        } else {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        }
      });
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

    return _servoraAuthPage(
      context,
      title: signup ? 'Create your account.' : 'Welcome back.',
      description: signup
          ? 'Join Servora and discover a smarter way to manage services.'
          : 'Sign in to manage your services and stay connected.',
      children: [
        AutofillGroup(
          child: _servoraAuthCard([
            Text(
              signup ? 'Get started' : 'Sign in',
              style: theme.textTheme.titleLarge,
            ),
            TextField(
              enabled: !busy,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email address',
                hintText: 'name@example.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              onChanged: (value) => email = value.trim(),
            ),
            TextField(
              enabled: !busy,
              obscureText: hidePassword,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              autofillHints: [
                signup ? AutofillHints.newPassword : AutofillHints.password,
              ],
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: hidePassword ? 'Show password' : 'Hide password',
                  onPressed: busy
                      ? null
                      : () => setState(
                            () => hidePassword = !hidePassword,
                          ),
                  icon: Icon(
                    hidePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              onChanged: (value) => password = value,
              onSubmitted: (_) => submit(),
            ),
            if (!signup)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: busy
                      ? null
                      : () => go(
                            context,
                            const PasswordRecovery(),
                          ),
                  child: const Text('Forgot password?'),
                ),
              ),
            FilledButton(
              onPressed: busy ? null : submit,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      busy
                          ? 'Please wait...'
                          : signup
                              ? 'Create account'
                              : 'Sign in',
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_rounded),
                ],
              ),
            ),
            if (busy) const LinearProgressIndicator(),
          ]),
        ),
        const SizedBox(height: 20),
        Text(
          signup ? 'Already have a Servora account?' : 'New to Servora?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: busy
              ? null
              : () => setState(() {
                    signup = !signup;
                    hidePassword = true;
                  }),
          child: Text(
            signup ? 'Sign in instead' : 'Create an account',
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 16,
              color: colors.primary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Secure account authentication',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _Register();
}

class _Register extends State<Register> {
  String name = '';
  String phone = '';
  String role = 'customer';

  bool busy = false;
  bool consent = false;

  Future<void> completeRegistration() async {
    if (busy) return;

    setState(() => busy = true);

    try {
      final displayName = name.trim();

      if (displayName.isEmpty || displayName.length > 80) {
        throw Exception(
          'Enter a valid display name.',
        );
      }

      final validPhone = normalizePhone(phone);

      if (!consent) {
        throw Exception(
          'Please agree to the contact sharing policy.',
        );
      }

      final memberRef = db.collection('members').doc(uid);

      final contactRef = db.collection('privateContacts').doc(uid);

      await db.runTransaction((transaction) async {
        final existing = await transaction.get(memberRef);

        if (existing.exists) return;

        transaction.set(contactRef, {
          'phone': validPhone,
        });

        transaction.set(memberRef, {
          'name': displayName,
          'role': role,
        });
      });
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

  Widget roleCard(
    String value,
    String title,
    String description,
    IconData icon,
  ) {
    final colors = Theme.of(context).colorScheme;
    final selected = role == value;

    return Semantics(
      selected: selected,
      child: Material(
        color: selected ? colors.primaryContainer : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: busy ? null : () => setState(() => role = value),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: colors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? colors.onPrimaryContainer
                              : colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: selected
                              ? colors.onPrimaryContainer
                              : colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? colors.primary : colors.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return _servoraAuthPage(
      context,
      title: 'Complete your profile.',
      description:
          'Tell us a little about yourself to personalize your Servora experience.',
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 5,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 5,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'STEP 2 OF 2 - YOUR PROFILE',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            color: colors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 24),
        _servoraAuthCard([
          Text(
            'Personal information',
            style: theme.textTheme.titleLarge,
          ),
          TextField(
            enabled: !busy,
            maxLength: 80,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Display name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            onChanged: (value) => name = value,
          ),
          TextField(
            enabled: !busy,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Mobile number',
              hintText: '07XXXXXXXX',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            onChanged: (value) => phone = value,
          ),
        ]),
        const SizedBox(height: 26),
        Text(
          'How will you use Servora?',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Choose your account type.',
          style: TextStyle(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        roleCard(
          'customer',
          'Customer',
          'Find professionals and request services.',
          Icons.home_outlined,
        ),
        const SizedBox(height: 12),
        roleCard(
          'provider',
          'Service provider',
          'Offer services and manage your jobs.',
          Icons.home_repair_service_outlined,
        ),
        const SizedBox(height: 24),
        Card(
          margin: EdgeInsets.zero,
          child: CheckboxListTile(
            value: consent,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: busy
                ? null
                : (value) => setState(
                      () => consent = value ?? false,
                    ),
            title: const Text('Contact sharing agreement'),
            subtitle: const Text(
              'I agree to share my mobile number with relevant '
              'customers or service providers when participating '
              'in quotations and active jobs.',
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: busy || !consent ? null : completeRegistration,
          child: Text(
            busy ? 'Saving your profile...' : 'Complete registration',
          ),
        ),
        if (busy) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }
}

class MobileSettings extends StatefulWidget {
  const MobileSettings({super.key});

  @override
  State<MobileSettings> createState() => _MobileSettings();
}

class _MobileSettings extends State<MobileSettings> {
  final phoneController = TextEditingController();

  bool busy = false;
  bool consent = false;

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  Future<void> savePhone() async {
    if (busy) return;

    setState(() => busy = true);

    try {
      final phone = normalizePhone(phoneController.text);

      if (!consent) {
        throw Exception(
          'Please agree to the contact sharing policy.',
        );
      }

      await db.collection('privateContacts').doc(uid).set({
        'phone': phone,
      });

      if (mounted) {
        phoneController.clear();

        setState(() => consent = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Mobile number saved successfully.',
            ),
          ),
        );
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
    final user = FirebaseAuth.instance.currentUser;

    return page('Mobile number', [
      const Icon(
        Icons.account_circle_outlined,
        size: 80,
        color: ink,
      ),
      Text(
        'Account information',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      card(
        'Email address',
        user?.email ?? 'Unavailable',
      ),
      StreamBuilder<DocumentSnapshot<RowData>>(
        stream: db.collection('privateContacts').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text(
              'Unable to load contact information.',
            );
          }

          if (!snapshot.hasData) {
            return const LinearProgressIndicator();
          }

          final contact = snapshot.data!.data();

          return card(
            'Current mobile number',
            contact?['phone']?.toString() ?? 'No mobile number added',
          );
        },
      ),
      TextField(
        controller: phoneController,
        enabled: !busy,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(
          labelText: 'New mobile number',
          hintText: '07XXXXXXXX',
          prefixIcon: Icon(Icons.phone_outlined),
        ),
      ),
      CheckboxListTile(
        value: consent,
        onChanged: busy
            ? null
            : (value) => setState(() {
                  consent = value ?? false;
                }),
        title: const Text(
          'Allow contact sharing',
        ),
        subtitle: const Text(
          'Share this number with relevant participants '
          'during quotations and active jobs.',
        ),
      ),
      FilledButton.icon(
        onPressed: busy || !consent ? null : savePhone,
        icon: const Icon(Icons.save_outlined),
        label: Text(
          busy ? 'Saving...' : 'Save mobile number',
        ),
      ),
      const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.lock_outline,
                color: ink,
                size: 32,
              ),
              SizedBox(height: 8),
              Text(
                'Your privacy matters',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Your number is not displayed publicly. '
                'Contact sharing is limited to eligible '
                'participants in service requests.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ]);
  }
}

Widget select(
  String label,
  String value,
  List<String> choices,
  ValueChanged<String> change,
) {
  return DropdownButtonFormField<String>(
    key: ValueKey((label, value)),
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
    ),
    items: [
      for (final choice in choices)
        DropdownMenuItem(
          value: choice,
          child: Text(choice),
        ),
    ],
    onChanged: (selected) {
      if (selected != null) {
        change(selected);
      }
    },
  );
}
