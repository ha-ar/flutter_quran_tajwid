import 'package:flutter/widgets.dart';
import '../auth/forgot_password_screen.dart';
import '../kyc/personal_info_screen.dart';

final Map<String, WidgetBuilder> onboardingRoutes = {
  ForgotPasswordScreen.route: (_) => const ForgotPasswordScreen(),
  OtpVerifyScreen.route: (_) => const OtpVerifyScreen(),
  ChangePasswordScreen.route: (_) => const ChangePasswordScreen(),
  PasswordUpdatedScreen.route: (_) => const PasswordUpdatedScreen(),
  PersonalInfoScreen.route: (_) => const PersonalInfoScreen(),
  UploadIdScreen.route: (_) => const UploadIdScreen(),
  SelfieScreen.route: (_) => const SelfieScreen(),
  ProfessionalVerificationScreen.route: (_) =>
      const ProfessionalVerificationScreen(),
  ComplianceQuestionsScreen.route: (_) => const ComplianceQuestionsScreen(),
  SubmissionSuccessScreen.route: (_) => const SubmissionSuccessScreen(),
};
