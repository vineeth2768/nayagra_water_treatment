import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';
import '../../widgets/custom_text_field.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.loginSuccess),
          backgroundColor: AppColors.success,
        ),
      );
      context.go(RouteNames.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0C243B),
      body: Stack(
        children: [
          // Background ambient radial gradients
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Center Login Card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container(
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo & Brand
                        Center(
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.5), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondary.withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.asset(
                              'assets/images/logo_icon.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'NAYAGRA WATER TREATMENT PLANTS',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: AppColors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Introducing customized water treatment plants using latest technologies at an affordable price',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Error Banner (if any)
                        if (auth.errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.dangerLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    auth.errorMessage!,
                                    style: const TextStyle(
                                      color: AppColors.danger,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],

                        // Email Field
                        CustomTextField(
                          controller: _emailController,
                          label: AppStrings.email,
                          hint: 'Enter your email address',
                          isRequired: true,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email_outlined, size: 18, color: AppColors.textSecondary),
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        CustomTextField(
                          controller: _passwordController,
                          label: AppStrings.password,
                          hint: 'Enter password',
                          isRequired: true,
                          obscureText: _obscurePassword,
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textSecondary),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                          validator: Validators.password,
                        ),
                        const SizedBox(height: 14),

                        // Remember Me Checkbox
                        Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: auth.rememberMe,
                                onChanged: auth.toggleRememberMe,
                                activeColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              AppStrings.rememberMe,
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Main Sign In Button
                        ElevatedButton(
                          onPressed: auth.isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppColors.primary,
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.login_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Sign In to CRM Portal',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 20),

                        // Company Address Footer
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on_outlined, size: 15, color: AppColors.secondary),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Nayagra Water Treatment Plants. Udayanapuram Vaikom , Kottayam ,kerala',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                  height: 1.3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
