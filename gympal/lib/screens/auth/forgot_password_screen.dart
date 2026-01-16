import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/user_model.dart'; // Import to check user fields

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Page Controller for wizard flow
  final _pageController = PageController();
  int _currentStep = 0;
  
  // Data State
  String _username = '';
  UserModel? _foundUser;
  String _verificationMethod = 'pin'; // 'pin', 'question', 'age'

  // Controllers
  final _usernameController = TextEditingController();
  final _answerController = TextEditingController();
  final _pinController = TextEditingController();
  final _ageController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _usernameFormKey = GlobalKey<FormState>();
  final _verifyFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _pageController.dispose();
    _usernameController.dispose();
    _answerController.dispose();
    _pinController.dispose();
    _ageController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    setState(() => _currentStep++);
  }

  // Step 1: Find Account
  void _findAccount() async {
    if (!_usernameFormKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.getUserByUsername(_usernameController.text.trim());

    if (user != null) {
      setState(() {
        _foundUser = user;
        _username = user.username;
        // Default to PIN if available, else Question, else Age
        if (user.pin != null) _verificationMethod = 'pin';
        else if (user.securityQuestion != null) _verificationMethod = 'question';
        else _verificationMethod = 'age';
      });
      _nextPage();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User not found")));
    }
  }

  // Step 2: Verify
  void _verifyIdentity() {
    if (!_verifyFormKey.currentState!.validate()) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    bool verified = false;

    if (_verificationMethod == 'pin') {
      verified = auth.verifyPin(_username, _pinController.text);
    } else if (_verificationMethod == 'question') {
      verified = auth.verifySecurityAnswer(_username, _answerController.text);
    } else if (_verificationMethod == 'age') {
      final  age = int.tryParse(_ageController.text);
      if(age != null) verified = auth.verifyAge(_username, age);
    }

    if (verified) {
      _nextPage();
    } else {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Verification Failed. Incorrect details.")));
    }
  }

  // Step 3: Reset
  void _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;
    
    final password = _newPasswordController.text;
    if (password != _confirmPasswordController.text) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
       return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final error = await auth.resetPassword(_username, password);

    if (error == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password reset successfully!")));
      Navigator.pop(context);
    } else if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? "Error resetting password")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text("Reset Password"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        titleTextStyle: const TextStyle(color: Color(0xFF111827), fontSize: 18, fontWeight: FontWeight.bold),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe
        children: [
          _buildFindAccountStep(),
          _buildVerifyStep(),
          _buildResetStep(),
        ],
      ),
    );
  }

  Widget _buildFindAccountStep() {
    return _buildStepContainer(
      title: "Find your account",
      subtitle: "Enter your username to search for your account.",
      child: Form(
        key: _usernameFormKey,
        child: Column(
          children: [
             TextFormField(
              controller: _usernameController,
              decoration: _inputDecoration("Username"),
              validator: (v) => v!.isEmpty ? "Required" : null,
            ),
            const SizedBox(height: 24),
            _primaryButton("Search", _findAccount),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyStep() {
    return _buildStepContainer(
      title: "Verify Identity",
      subtitle: "Choose a method to confirm it's you.",
      child: Form(
        key: _verifyFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             if (_foundUser != null) ...[
               // Method Selector
               DropdownButtonFormField<String>(
                 value: _verificationMethod,
                 decoration: _inputDecoration("Verification Method"),
                 items: [
                   if (_foundUser!.pin != null) 
                     const DropdownMenuItem(value: 'pin', child: Text("PIN Code")),
                   if (_foundUser!.securityQuestion != null) 
                     const DropdownMenuItem(value: 'question', child: Text("Security Question")),
                   const DropdownMenuItem(value: 'age', child: Text("Age (Less Secure)")),
                 ],
                 onChanged: (val) {
                   setState(() {
                     _verificationMethod = val!;
                     // Clear fields on switch
                     _pinController.clear();
                     _answerController.clear();
                     _ageController.clear();
                   });
                 },
               ),
               const SizedBox(height: 20),

               // Dynamic Input Fields
               if (_verificationMethod == 'pin')
                 TextFormField(
                   controller: _pinController,
                   keyboardType: TextInputType.number,
                   maxLength: 4,
                   decoration: _inputDecoration("Enter 4-digit PIN").copyWith(counterText: ""),
                   validator: (v) => v!.length != 4 ? "Enter 4 digits" : null,
                 ),
               
               if (_verificationMethod == 'question') ...[
                 Text("Question: ${_foundUser!.securityQuestion}", style: const TextStyle(fontWeight: FontWeight.w600)),
                 const SizedBox(height: 8),
                 TextFormField(
                   controller: _answerController,
                   decoration: _inputDecoration("Answer"),
                   validator: (v) => v!.isEmpty ? "Answer required" : null,
                 ),
               ],

               if (_verificationMethod == 'age')
                  TextFormField(
                   controller: _ageController,
                   keyboardType: TextInputType.number,
                   decoration: _inputDecoration("Enter your current age"),
                   validator: (v) => v!.isEmpty ? "Age required" : null,
                 ),
               
               const SizedBox(height: 24),
               _primaryButton("Verify", _verifyIdentity),
             ],
          ],
        ),
      ),
    );
  }

  Widget _buildResetStep() {
    return _buildStepContainer(
      title: "Reset Password",
      subtitle: "Create a new strong password.",
      child: Form(
        key: _resetFormKey,
        child: Column(
          children: [
            TextFormField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: _inputDecoration("New Password"),
               validator: (val) {
                  if (val == null || val.isEmpty) return "Password is required";
                  if (val.length < 8) return "Min 8 chars";
                  return null;
                },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: _inputDecoration("Confirm Password"),
              validator: (val) {
                  if (val == null || val.isEmpty) return "Confirm password";
                  return null;
                },
            ),
            const SizedBox(height: 24),
            _primaryButton("Reset Password", _resetPassword),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContainer({required String title, required String subtitle, required Widget child}) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
             boxShadow: const [
                BoxShadow(color: Color.fromRGBO(0,0,0,0.05), blurRadius: 10, offset: Offset(0, 4)),
              ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
               const SizedBox(height: 8),
               Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF6B7280))),
               const SizedBox(height: 32),
               child,
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF6B7280)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _primaryButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A90E2),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      ),
    );
  }
}
