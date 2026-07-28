import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/providers.dart';
import '../../../shared/widgets/glass_card.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      await auth.sendForgotPasswordEmail(_emailController.text.trim());
      setState(() {
        _isSent = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Premium Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF0F1026), const Color(0xFF070814)]
                    : [const Color(0xFFE0E5EC), const Color(0xFFF6F8FB)],
              ),
            ),
          ),

          // Custom Floating Back Button
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.07)
                      : Colors.black.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Icon / Recovery Header Icon
                    Center(
                      child: Container(
                        height: 76,
                        width: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFFF43F5E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF43F5E).withOpacity(0.25),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Reset Password',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    GlassCard(
                      child: _isSent
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 12),
                                Center(
                                  child: Container(
                                    height: 72,
                                    width: 72,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(
                                        0xFF10B981,
                                      ).withOpacity(0.1),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF10B981,
                                        ).withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.mark_email_read_rounded,
                                      color: Color(0xFF10B981),
                                      size: 36,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Instructions Sent!',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'A password recovery link has been dispatched to:',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black54,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _emailController.text,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Please check your spam folder if you do not receive it in a few minutes.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.black38,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                ElevatedButton(
                                  onPressed: () => context.pop(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6366F1),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Back to Login',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            )
                          : Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(height: 8),

                                  Text(
                                    'Enter your registration email. We will send you instructions to change your password.',

                                    style: TextStyle(
                                      color: isDark
                                          ? const Color.fromARGB(
                                              190,
                                              255,
                                              255,
                                              255,
                                            )
                                          : Colors.black54,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  if (_errorMessage != null) ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent.withOpacity(
                                          0.08,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.redAccent.withOpacity(
                                            0.2,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 13,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Email Address',
                                      labelStyle: TextStyle(
                                        color: isDark
                                            ? Colors.white60
                                            : Colors.black54,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.email_outlined,
                                        color: isDark
                                            ? Colors.white60
                                            : Colors.black54,
                                      ),
                                      filled: true,
                                      fillColor: isDark
                                          ? Colors.white.withOpacity(0.02)
                                          : Colors.black.withOpacity(0.01),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: isDark
                                              ? Colors.white24
                                              : Colors.black12,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: isDark
                                              ? Colors.white10
                                              : Colors.black12,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF6366F1),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    validator: (val) {
                                      if (val == null ||
                                          val.isEmpty ||
                                          !val.contains('@')) {
                                        return 'Enter a valid email address';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton(
                                    onPressed: _isLoading ? null : _handleReset,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6366F1),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            'Send Reset Instructions',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
