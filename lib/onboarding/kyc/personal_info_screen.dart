import 'package:flutter/material.dart';
import '../theme/onboarding_theme.dart';
import '../widgets/primary_button.dart';

class PersonalInfoScreen extends StatefulWidget {
  static const route = '/onboarding/kyc/personal-info';
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _name = TextEditingController();
  final _dob = TextEditingController();
  final _nationality = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _dob.dispose();
    _nationality.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildOnboardingTheme(),
      child: Scaffold(
        appBar: AppBar(title: const Text('KYC')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Personal Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: 12),
              TextField(
                  controller: _dob,
                  decoration:
                      const InputDecoration(labelText: 'Date of Birth')),
              const SizedBox(height: 12),
              TextField(
                  controller: _nationality,
                  decoration: const InputDecoration(labelText: 'Nationality')),
              const SizedBox(height: 12),
              TextField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              TextField(
                  controller: _phone,
                  decoration: const InputDecoration(labelText: 'Phone')),
              const Spacer(),
              PrimaryButton(
                  label: 'Continue',
                  onPressed: () =>
                      Navigator.pushNamed(context, UploadIdScreen.route)),
            ],
          ),
        ),
      ),
    );
  }
}

class UploadIdScreen extends StatelessWidget {
  static const route = '/onboarding/kyc/upload-id';
  const UploadIdScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildOnboardingTheme(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Upload Your Government ID')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: OnboardingColors.card,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(Icons.credit_card,
                        size: 64, color: OnboardingColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Continue',
                onPressed: () =>
                    Navigator.pushNamed(context, SelfieScreen.route),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SelfieScreen extends StatelessWidget {
  static const route = '/onboarding/kyc/selfie';
  const SelfieScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildOnboardingTheme(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Take a Selfie for Verification')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: OnboardingColors.card,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(Icons.photo_camera,
                        size: 64, color: OnboardingColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Continue',
                onPressed: () => Navigator.pushNamed(
                    context, ProfessionalVerificationScreen.route),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfessionalVerificationScreen extends StatefulWidget {
  static const route = '/onboarding/kyc/professional-verification';
  const ProfessionalVerificationScreen({super.key});

  @override
  State<ProfessionalVerificationScreen> createState() =>
      _ProfessionalVerificationScreenState();
}

class _ProfessionalVerificationScreenState
    extends State<ProfessionalVerificationScreen> {
  final _company = TextEditingController();
  final _position = TextEditingController();
  final _workEmail = TextEditingController();
  final _cvUrl = TextEditingController();
  final _linkedin = TextEditingController();

  @override
  void dispose() {
    _company.dispose();
    _position.dispose();
    _workEmail.dispose();
    _cvUrl.dispose();
    _linkedin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildOnboardingTheme(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Professional Verification')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                    controller: _company,
                    decoration:
                        const InputDecoration(labelText: 'Company/Name')),
                const SizedBox(height: 12),
                TextField(
                    controller: _position,
                    decoration: const InputDecoration(labelText: 'Position')),
                const SizedBox(height: 12),
                TextField(
                    controller: _workEmail,
                    decoration: const InputDecoration(labelText: 'Work Email')),
                const SizedBox(height: 12),
                TextField(
                    controller: _cvUrl,
                    decoration:
                        const InputDecoration(labelText: 'CV (Optional)')),
                const SizedBox(height: 12),
                TextField(
                    controller: _linkedin,
                    decoration: const InputDecoration(
                        labelText: 'LinkedIn (Optional)')),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Continue',
                  onPressed: () => Navigator.pushNamed(
                      context, ComplianceQuestionsScreen.route),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ComplianceQuestionsScreen extends StatefulWidget {
  static const route = '/onboarding/kyc/compliance-questions';
  const ComplianceQuestionsScreen({super.key});

  @override
  State<ComplianceQuestionsScreen> createState() =>
      _ComplianceQuestionsScreenState();
}

class _ComplianceQuestionsScreenState extends State<ComplianceQuestionsScreen> {
  bool _agreeTos = false;
  bool _agreePrivacy = false;
  bool _consentData = false;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildOnboardingTheme(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Compliance Questions')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CheckboxListTile(
                value: _agreeTos,
                onChanged: (v) => setState(() => _agreeTos = v ?? false),
                title: const Text(
                    'I have read and agree to the Terms & Conditions.'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                value: _agreePrivacy,
                onChanged: (v) => setState(() => _agreePrivacy = v ?? false),
                title: const Text('I agree to the Privacy Policy.'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                value: _consentData,
                onChanged: (v) => setState(() => _consentData = v ?? false),
                title: const Text('I consent to data processing.'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Submit & Continue',
                onPressed: (_agreeTos && _agreePrivacy)
                    ? () => Navigator.pushNamed(
                        context, SubmissionSuccessScreen.route)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SubmissionSuccessScreen extends StatelessWidget {
  static const route = '/onboarding/kyc/submission-success';
  const SubmissionSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildOnboardingTheme(),
      child: Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: OnboardingColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle,
                    color: OnboardingColors.primary, size: 56),
                const SizedBox(height: 12),
                const Text('Your submission has been received successfully.'),
                const SizedBox(height: 8),
                const Text(
                  'Our team will review it and update your status shortly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: OnboardingColors.textSecondary),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                    label: 'Get Started',
                    onPressed: () =>
                        Navigator.popUntil(context, (r) => r.isFirst)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
