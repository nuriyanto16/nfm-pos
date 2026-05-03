import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/dio_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../settings/presentation/providers/settings_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaController = TextEditingController();
  bool _isLoading = false;
  String? _captchaId;
  String? _captchaImage;

  @override
  void initState() {
    super.initState();
    _fetchCaptcha();
  }

  Future<void> _fetchCaptcha() async {
    try {
      final response = await ref.read(dioProvider).get('captcha');
      if (response.statusCode == 200) {
        setState(() {
          _captchaId = response.data['captcha_id'];
          _captchaImage = response.data['captcha_image'];
          _captchaController.clear();
        });
      }
    } catch (e) {
      debugPrint('Error fetching captcha: $e');
    }
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final response = await ref.read(dioProvider).post('login', data: {
        'username': _usernameController.text,
        'password': _passwordController.text,
        'captcha_id': _captchaId,
        'captcha_value': _captchaController.text,
      });

      if (response.statusCode == 200) {
        final token = response.data['token'];
        final user = response.data['user'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('username', user['username'] ?? '');
        await prefs.setString('role', user['role'] ?? '');
        await prefs.setInt('userId', user['id'] ?? 0);
        
        if (mounted) {
          context.go('/pos');
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Login gagal. Periksa kembali username/password.';
        if (e is DioException && e.response?.data?['error'] != null) {
          errorMessage = e.response?.data?['error'];
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
        _fetchCaptcha();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settingsAsync = ref.watch(settingsProvider);
    final isMobile = MediaQuery.of(context).size.width < 700;
    
    final appName = settingsAsync.when(
      data: (s) => s['app_name']?.toString() ?? 'NFM POS',
      loading: () => 'NFM POS',
      error: (_, __) => 'NFM POS',
    );
    
    final companyName = settingsAsync.when(
      data: (s) => s['company_name']?.toString() ?? 'Smart Restaurant Solution',
      loading: () => 'Smart Restaurant Solution',
      error: (_, __) => 'Smart Restaurant Solution',
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer.withOpacity(0.4),
              colorScheme.surface,
              colorScheme.surface,
              colorScheme.secondaryContainer.withOpacity(0.2),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo & Brand
                  Hero(
                    tag: 'app_logo',
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.restaurant_rounded, size: 64, color: colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    appName,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    companyName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.outline,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Login Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
                    ),
                    color: colorScheme.surface.withOpacity(0.7),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selamat Datang',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Silakan masuk untuk melanjutkan',
                            style: TextStyle(fontSize: 13, color: colorScheme.outline),
                          ),
                          const SizedBox(height: 32),
                          
                          _buildTextField(
                            label: 'Username',
                            controller: _usernameController,
                            hint: 'Masukkan username',
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 20),
                          
                          _buildTextField(
                            label: 'Password',
                            controller: _passwordController,
                            hint: '••••••••',
                            icon: Icons.lock_outline_rounded,
                            obscure: true,
                          ),
                          
                          if (_captchaImage != null) ...[
                            const SizedBox(height: 20),
                            const Text(
                              'Verifikasi Keamanan',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: colorScheme.outlineVariant),
                                      color: Colors.white,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: InkWell(
                                        onTap: _fetchCaptcha,
                                        child: Image.memory(
                                          base64Decode(_captchaImage!.split(',').last),
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filledTonal(
                                  onPressed: _fetchCaptcha,
                                  icon: const Icon(Icons.refresh_rounded, size: 20),
                                  style: IconButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              label: '',
                              controller: _captchaController,
                              hint: 'Kode Captcha',
                              icon: Icons.verified_user_outlined,
                            ),
                          ],
                          
                          const SizedBox(height: 32),
                          
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton(
                              onPressed: _isLoading ? null : _login,
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: _isLoading 
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('MASUK KE SISTEM', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  Text(
                    'NFM POS SYSTEM v2.1',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.outline.withOpacity(0.5),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colorScheme.outline.withOpacity(0.4), fontSize: 14),
            prefixIcon: Icon(icon, size: 20, color: colorScheme.primary),
            filled: true,
            fillColor: colorScheme.surfaceVariant.withOpacity(0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
