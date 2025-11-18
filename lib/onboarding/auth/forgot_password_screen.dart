import 'package:flutter/material.dart';
import '../theme/onboarding_theme.dart';
import '../widgets/primary_button.dart';
import '../widgets/otp_fields.dart';

class ForgotPasswordScreen extends StatefulWidget {
  static const route = '/onboarding/forgot-password';
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildOnboardingTheme(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Forget Password'),
          backgroundColor: Colors.transparent,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Enter your registered phone to reset your password.',
                style: TextStyle(color: OnboardingColors.textSecondary),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  hintText: '+965 345 6789',
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Send OTP',
                onPressed: () {
                  Navigator.pushNamed(context, OtpVerifyScreen.route);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OtpVerifyScreen extends StatelessWidget {
  static const route = '/onboarding/otp-verify';
  const OtpVerifyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildOnboardingTheme(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("It's really You ?"),
          backgroundColor: Colors.transparent,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: OnboardingColors.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'An authentication code has been sent to your phone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: OnboardingColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    OtpFields(onCompleted: (_) {
                      Navigator.pushNamed(context, ChangePasswordScreen.route);
                    }),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Resend Code'),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Continue',
                onPressed: () =>
                    Navigator.pushNamed(context, ChangePasswordScreen.route),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  static const route = '/onboarding/change-password';
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _pass1 = TextEditingController();
  final _pass2 = TextEditingController();

  @override
  void dispose() {
    _pass1.dispose();
    _pass2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildOnboardingTheme(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Change Password'),
          backgroundColor: Colors.transparent,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _pass1,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pass2,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Confirm new password'),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Save',
                onPressed: () =>
                    Navigator.pushNamed(context, PasswordUpdatedScreen.route),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PasswordUpdatedScreen extends StatelessWidget {
  static const route = '/onboarding/password-updated';
  const PasswordUpdatedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildOnboardingTheme(),
      child: Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: OnboardingColors.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle,
                      color: OnboardingColors.primary, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'Password updated successfully.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Sign In',
                    onPressed: () =>
                        Navigator.popUntil(context, (r) => r.isFirst),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
