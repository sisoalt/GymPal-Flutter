import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../main_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isFormValid = false;

  void _checkFormValidity() {
    final isValid = 
      _validateUsername(_usernameController.text) == null &&
      _validatePassword(_passwordController.text) == null;
    
    if (isValid != _isFormValid) {
      setState(() => _isFormValid = isValid);
    }
  }

  String? _validateUsername(String? val) {
    if (val == null || val.trim().isEmpty) return "Username is required";
    final trimmed = val.trim();
    if (trimmed.length < 4) return "Username must be 4–20 characters";
    if (trimmed.length > 20) return "Username must be 4–20 characters";
    if (trimmed.contains(' ')) return "Username cannot contain spaces";
    // security best practice: validation regex can be strict here if desired, 
    // but the requirement mainly asked for length and no spaces.
    return null;
  }

  String? _validatePassword(String? val) {
    if (val == null || val.isEmpty) return "Password is required";
    if (val.length < 8) return "Password must be at least 8 characters";
    return null;
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final error = await authProvider.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (error == null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainLayout()),
        );
      } else if (mounted) {
        _passwordController.clear(); // Clear password on failure
        _checkFormValidity(); // Re-check validity after clearing
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? "Invalid username or password"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0,0,0,0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              onChanged: _checkFormValidity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.fitness_center, size: 64, color: Color(0xFF4A90E2)),
                  const SizedBox(height: 16),
                  const Text(
                    'Gym Pal',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF222222)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Progress In Your Pocket',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _usernameController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: "Username",
                      helperText: "4-20 chars",
                      labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: _validateUsername,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: "Password",
                      labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: const Color(0xFF6B7280),
                        ),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                      ),
                      child: const Text("Forgot Password?", style: TextStyle(color: Color(0xFF4A90E2))),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) => auth.isLoading
                        ? const CircularProgressIndicator(color: Color(0xFF4A90E2))
                        : SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isFormValid ? _handleLogin : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4A90E2),
                                disabledBackgroundColor: Colors.grey[300],
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text("Login", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
                    child: const Text(
                      "Don't have an account? Register",
                      style: TextStyle(color: Color(0xFF6B7280)),
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
}
