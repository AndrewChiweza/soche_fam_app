import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soche_fam/components/app_snack_bar.dart';
import 'package:hive/hive.dart';
import 'package:soche_fam/theme/app_theme.dart';
import '../../providers/admins_provider.dart';
import '../../providers/push_notify_provider.dart';
import 'admin_panel_screen.dart';

/// Maps confusing technical Firebase errors to friendly human-readable alerts
String getHumanReadableAuthError(String rawError) {
  final lowercaseError = rawError.toLowerCase();

  if (lowercaseError.contains('invalid-credential') ||
      lowercaseError.contains('wrong-password') ||
      lowercaseError.contains('user-not-found')) {
    return 'Incorrect password or email. Please check your credentials and try again.';
  } else if (lowercaseError.contains('invalid-email')) {
    return 'Please enter a valid email address structure.';
  } else if (lowercaseError.contains('user-disabled')) {
    return 'This administrator account has been disabled by the Super-Admin.';
  } else if (lowercaseError.contains('network-request-failed')) {
    return 'Network connection error. Please check your internet connection and try again.';
  } else if (lowercaseError.contains('too-many-requests')) {
    return 'Too many failed login attempts. This account has been temporarily locked.';
  }

  return rawError;
}

class AdminSignInScreen extends StatefulWidget {
  const AdminSignInScreen({Key? key}) : super(key: key);

  @override
  State<AdminSignInScreen> createState() => _AdminSignInScreenState();
}

class _AdminSignInScreenState extends State<AdminSignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  bool loading = false;
  bool showPassword = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AdminsProvider>();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left),
          onPressed: () => Navigator.of(context).pop(),
        ),
        scrolledUnderElevation: 0,
        elevation: 0,
        title: const Text(""),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                /// LOGO or ICON
                Icon(Icons.admin_panel_settings,
                    size: 90, color: Theme.of(context).secondaryHeaderColor),
                const SizedBox(height: 25),

                /// Title
                const Text(
                  "Welcome Admin",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF00674F),
                  ),
                ),
                const SizedBox(height: 30),

                /// EMAIL FIELD
                _inputField(
                  controller: emailCtrl,
                  label: "Email",
                  prefixIcon: Icons.email_outlined,
                  validatorMsg: "Enter your email",
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),

                /// PASSWORD FIELD
                _inputField(
                  controller: passwordCtrl,
                  label: "Password",
                  prefixIcon: Icons.lock_outline,
                  validatorMsg: "Enter your password",
                  obscureText: !showPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      showPassword
                          ? CupertinoIcons.eye_slash
                          : CupertinoIcons.eye,
                    ),
                    onPressed: () {
                      setState(() => showPassword = !showPassword);
                    },
                  ),
                ),

                /// FORGOT PASSWORD TRIGGER LINK
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextButton(
                      onPressed: () async {
                        if (emailCtrl.text.trim().isEmpty) {
                          AppSnackBar.showError(context,
                              "Please input your email address above to receive a recovery link.");
                          return;
                        }
                        setState(() => loading = true);
                        final resetError = await provider
                            .sendForgotPasswordEmail(emailCtrl.text.trim());
                        setState(() => loading = false);

                        if (resetError != null) {
                          AppSnackBar.showError(
                              context, getHumanReadableAuthError(resetError));
                        } else {
                          AppSnackBar.showSuccess(context,
                              "Password recovery link sent successfully! Check your inbox.");
                        }
                      },
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: Color(0xFF00674F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                /// SIGN IN BUTTON
                loading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            padding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) return;

                            setState(() => loading = true);

                            final error = await provider.signIn(
                              emailCtrl.text.trim(),
                              passwordCtrl.text.trim(),
                            );
                            setState(() => loading = false);

                            if (error != null) {
                              AppSnackBar.showError(
                                  context, getHumanReadableAuthError(error));
                              return;
                            }

                            // Save admin login state
                            final box = Hive.box("AppPrefs");
                            await box.put("admin_logged_in", true);

                            // Subscribe in background without blocking navigation
                            if (!mounted) return;
                            context
                                .read<PushNotificationProvider>()
                                .subscribeAdminToPaymentAlerts();

                            // Show success snackbar
                            AppSnackBar.showSuccess(
                                context, "Logged in successfully!");

                            // Navigate to admin panel
                            Future.delayed(const Duration(milliseconds: 500),
                                () {
                              if (!mounted) return;
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AdminPanelScreen()),
                              );
                            });
                          },
                          child: const Text(
                            "Sign In",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    required String validatorMsg,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: (v) => v == null || v.trim().isEmpty ? validatorMsg : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
