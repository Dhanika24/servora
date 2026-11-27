part of '../../main.dart';

class AccountSecurity extends StatefulWidget {
  final bool changeEmail;

  const AccountSecurity({
    required this.changeEmail,
    super.key,
  });

  @override
  State<AccountSecurity> createState() => _AccountSecurityState();
}

class _AccountSecurityState extends State<AccountSecurity> {
  final currentPassword = TextEditingController();
  final newEmail = TextEditingController();
  final newPassword = TextEditingController();
  final confirmPassword = TextEditingController();

  bool busy = false;
  bool showCurrent = false;
  bool showNew = false;
  bool showConfirm = false;

  @override
  void dispose() {
    currentPassword.dispose();
    newEmail.dispose();
    newPassword.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String authError(FirebaseAuthException error) {
    switch (error.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Your current password is incorrect.';

      case 'email-already-in-use':
        return 'This email address is already registered.';

      case 'invalid-email':
        return 'Enter a valid email address.';

      case 'weak-password':
        return 'Choose a stronger password.';

      case 'network-request-failed':
        return 'Check your internet connection.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'requires-recent-login':
        return 'Please sign in again before continuing.';

      default:
        return error.message ?? 'Unable to update your account.';
    }
  }

  Future<void> saveChanges() async {
    if (busy) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) {
      showMessage('Please sign in again.');
      return;
    }

    final password = currentPassword.text;
    final email = newEmail.text.trim();
    final updatedPassword = newPassword.text;

    if (password.isEmpty) {
      showMessage('Enter your current password.');
      return;
    }

    if (widget.changeEmail) {
      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
        showMessage('Enter a valid email address.');
        return;
      }

      if (email.toLowerCase() == user.email!.toLowerCase()) {
        showMessage('Enter a different email address.');
        return;
      }
    } else {
      if (updatedPassword.length < 8) {
        showMessage(
          'Use a password with at least 8 characters.',
        );
        return;
      }

      if (updatedPassword != confirmPassword.text) {
        showMessage('The new passwords do not match.');
        return;
      }

      if (updatedPassword == password) {
        showMessage('Choose a different password.');
        return;
      }
    }

    setState(() => busy = true);

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);

      if (widget.changeEmail) {
        await user.verifyBeforeUpdateEmail(email);

        if (!mounted) return;

        currentPassword.clear();
        newEmail.clear();

        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            icon: const Icon(
              Icons.mark_email_read_outlined,
              size: 48,
              color: ink,
            ),
            title: const Text('Verification email sent'),
            content: Text(
              'A verification link has been sent to $email.\n\n'
              'Open the link to confirm your new email '
              'address. After verification, sign in again '
              'using your new email address.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Done'),
              ),
            ],
          ),
        );

        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        await user.updatePassword(updatedPassword);

        if (!mounted) return;

        currentPassword.clear();
        newPassword.clear();
        confirmPassword.clear();

        showMessage('Password changed successfully.');

        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (error) {
      showMessage(authError(error));
    } catch (_) {
      showMessage(
        'Unable to update your account. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Widget passwordField({
    required TextEditingController controller,
    required String label,
    required bool visible,
    required VoidCallback toggle,
  }) {
    return TextField(
      controller: controller,
      enabled: !busy,
      obscureText: !visible,
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          onPressed: toggle,
          icon: Icon(
            visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return page(
      widget.changeEmail ? 'Change email' : 'Change password',
      [
        Icon(
          widget.changeEmail ? Icons.email_outlined : Icons.security_outlined,
          size: 72,
          color: ink,
        ),
        Text(
          widget.changeEmail
              ? 'Update your email address'
              : 'Update your password',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const Text(
          'Confirm your current password to protect '
          'your account.',
        ),
        if (widget.changeEmail)
          card(
            'Current email address',
            user?.email ?? 'Unavailable',
          ),
        passwordField(
          controller: currentPassword,
          label: 'Current password',
          visible: showCurrent,
          toggle: () => setState(
            () => showCurrent = !showCurrent,
          ),
        ),
        if (widget.changeEmail)
          TextField(
            controller: newEmail,
            enabled: !busy,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'New email address',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          )
        else ...[
          passwordField(
            controller: newPassword,
            label: 'New password',
            visible: showNew,
            toggle: () => setState(
              () => showNew = !showNew,
            ),
          ),
          passwordField(
            controller: confirmPassword,
            label: 'Confirm new password',
            visible: showConfirm,
            toggle: () => setState(
              () => showConfirm = !showConfirm,
            ),
          ),
          const Text(
            'Your new password must contain at least '
            '8 characters.',
          ),
        ],
        FilledButton.icon(
          onPressed: busy ? null : saveChanges,
          icon: Icon(
            widget.changeEmail
                ? Icons.mark_email_read_outlined
                : Icons.check_circle_outline,
          ),
          label: Text(
            busy
                ? 'Please wait...'
                : widget.changeEmail
                    ? 'Send verification email'
                    : 'Update password',
          ),
        ),
        if (busy) const LinearProgressIndicator(),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Your authentication credentials are managed '
              'securely by Firebase Authentication. '
              'Passwords are not stored in Servora’s '
              'Firestore documents.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
