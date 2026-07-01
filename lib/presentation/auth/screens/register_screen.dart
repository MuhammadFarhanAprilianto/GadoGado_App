import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../viewmodels/auth_viewmodel.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authCodeController = TextEditingController();
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _authCodeController.dispose();
    super.dispose();
  }

  void _handleSignUp() async {
    final authVM = context.read<AuthViewModel>();
    authVM.clearError();

    // 1. Validasi Nama Lengkap
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama lengkap tidak boleh kosong.')),
      );
      return;
    }
    if (name.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama lengkap minimal harus 3 karakter.')),
      );
      return;
    }

    // 2. Validasi Email
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email tidak boleh kosong.')),
      );
      return;
    }
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format email tidak valid.')),
      );
      return;
    }

    // 3. Validasi Nomor Telepon
    final phone = _phoneController.text.trim();
    final phoneRegex = RegExp(r'^[0-9]+$');
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor telepon tidak boleh kosong.')),
      );
      return;
    }
    if (!phoneRegex.hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor telepon hanya boleh berisi angka.')),
      );
      return;
    }
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor telepon minimal harus 10 digit.')),
      );
      return;
    }

    // 4. Validasi Password
    final password = _passwordController.text;
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password tidak boleh kosong.')),
      );
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password minimal harus 6 karakter.')),
      );
      return;
    }

    // 5. Validasi Konfirmasi Password
    if (password != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi password tidak cocok.')),
      );
      return;
    }

    // 6. Validasi Kode Otentikasi Staf / Owner secara implisit
    String registeredRole = AppConstants.roleCustomer;
    final code = _authCodeController.text.trim();
    if (code.isNotEmpty) {
      if (code == AppConstants.codeAdminRegister) {
        registeredRole = AppConstants.roleAdmin;
      } else if (code == AppConstants.codeOwnerRegister) {
        registeredRole = AppConstants.roleOwner;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kode otentikasi tidak valid.')),
        );
        return;
      }
    }

    // 7. Persetujuan Syarat & Ketentuan
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap setujui Syarat dan Ketentuan layanan.')),
      );
      return;
    }

    final success = await authVM.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      role: registeredRole,
    );

    if (success && mounted) {
      // 1. Show Success Dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text('Success!'),
            ],
          ),
          content: const Text(
            'Your account has been created successfully. You can now sign in using your email and password.',
            style: TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Return to Login Selection
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to login screen
              },
              child: const Text('SIGN IN NOW', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFBF360C))),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          children: [
            const Text(
              'Join the Family',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create an account to start your fresh\njourney.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF555555), fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 32),
            
            // Registration Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel('FULL NAME'),
                  _buildTextField(
                    controller: _nameController,
                    hint: 'E.g. Warung Artisan',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 20),
                  
                  _buildInputLabel('EMAIL'),
                  _buildTextField(
                    controller: _emailController,
                    hint: 'hello@mpo.com',
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 20),
                  
                  _buildInputLabel('PHONE NUMBER'),
                  _buildTextField(
                    controller: _phoneController,
                    hint: '+62 812...',
                    icon: Icons.phone_outlined,
                  ),
                  const SizedBox(height: 20),
                  
                  _buildInputLabel('PASSWORD'),
                  _buildTextField(
                    controller: _passwordController,
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),
                  const SizedBox(height: 20),
                  
                  _buildInputLabel('CONFIRM PASSWORD'),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    hint: '••••••••',
                    icon: Icons.verified_user_outlined,
                    isPassword: true,
                  ),
                  const SizedBox(height: 20),
                  
                  _buildInputLabel('AUTHENTICATION CODE (OPTIONAL)'),
                  _buildTextField(
                    controller: _authCodeController,
                    hint: 'Kosongkan jika mendaftar sebagai Pelanggan',
                    icon: Icons.security_outlined,
                    isPassword: true,
                  ),
                  const SizedBox(height: 24),
                  
                  // Consumer to show error message from authVM
                  Consumer<AuthViewModel>(
                    builder: (context, authVM, _) {
                      if (authVM.errorMessage != null) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Text(
                            authVM.errorMessage!,
                            style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Agreement
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _agreeToTerms,
                          onChanged: (val) => setState(() => _agreeToTerms = val ?? false),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          activeColor: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: 'I agree to the ',
                            style: TextStyle(fontSize: 12, color: Color(0xFF555555)),
                            children: [
                              TextSpan(
                                text: 'Terms of Service',
                                style: TextStyle(color: Color(0xFFBF360C), decoration: TextDecoration.underline),
                              ),
                              TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(color: Color(0xFFBF360C), decoration: TextDecoration.underline),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Sign Up Button
                  Consumer<AuthViewModel>(
                    builder: (context, authVM, _) => Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFBF360C),
                            AppColors.primary,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        onPressed: authVM.isLoading ? null : _handleSignUp,
                        child: authVM.isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Sign Up', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text.rich(
                        TextSpan(
                          text: 'Already have an account? ',
                          style: const TextStyle(fontSize: 14, color: Color(0xFF555555)),
                          children: [
                            TextSpan(
                              text: 'Sign In',
                              style: TextStyle(color: const Color(0xFFBF360C), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A), letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
