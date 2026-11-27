
part of '../../main.dart';

class PasswordRecovery extends StatefulWidget {
  const PasswordRecovery({super.key});

  @override
  State<PasswordRecovery> createState() => _PasswordRecoveryState();
}

class _PasswordRecoveryState extends State<PasswordRecovery> {
  final emailController = TextEditingController();

  bool busy = false;
  bool sent = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> resetPassword() async {
    if (busy || sent) return;

    final email = emailController.text.trim();

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      showMessage('Enter a valid email address.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => busy = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      if (mounted) {
        setState(() => sent = true);
      }
    } on FirebaseAuthException catch (error) {
      switch (error.code) {
        case 'user-not-found':
          if (mounted) {
            setState(() => sent = true);
          }
          break;

        case 'invalid-email':
          showMessage('Enter a valid email address.');
          break;

        case 'too-many-requests':
          showMessage(
            'Too many requests. Please try again later.',
          );
          break;

        case 'network-request-failed':
          showMessage('Check your internet connection.');
          break;

        default:
          showMessage(
            'Unable to process your request. Try again.',
          );
      }
    } catch (_) {
      showMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  void useDifferentEmail() {
    if (busy || !sent) return;

    emailController.clear();

    setState(() => sent = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _servoraAuthPage(
      context,
      back: true,
      title: sent ? 'Check your email.' : 'Forgot your password?',
      description: sent
          ? 'If an account exists with this email address, '
              'you will receive a password reset link. '
              'Please check your inbox and spam folder.'
          : 'Enter the email address associated with your Servora '
              'account to request a password reset link.',
      children: [
        Center(
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              sent ? Icons.mark_email_read_outlined : Icons.lock_reset_rounded,
              color: colors.onPrimaryContainer,
              size: 56,
            ),
          ),
        ),
        const SizedBox(height: 28),
        if (!sent)
          _servoraAuthCard([
            TextField(
              controller: emailController,
              enabled: !busy,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.none,
              enableSuggestions: false,
              autocorrect: false,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              onSubmitted: (_) => resetPassword(),
            ),
            FilledButton.icon(
              onPressed: busy ? null : resetPassword,
              icon: const Icon(Icons.send_outlined),
              label: Text(
                busy ? 'Sending...' : 'Send reset link',
              ),
            ),
            if (busy) const LinearProgressIndicator(),
          ]),
        if (sent && !busy)
          OutlinedButton.icon(
            onPressed: useDifferentEmail,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Use a different email address'),
          ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: busy ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Back to sign in'),
        ),
      ],
    );
  }
}
