import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../main_layout.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _securityAnswerController = TextEditingController();
  final _pinController = TextEditingController();
  
  String _selectedGender = 'Male';
  String _selectedSecurityQuestion = "What was your first pet's name?";
  
  final List<String> _securityQuestions = [
    "What was your first pet's name?",
    "What is your mother's maiden name?",
    "What is your favorite color?",
    "What city were you born in?",
  ];

  bool _isFormValid = false;

  void _checkFormValidity() {
    final isValid = 
      _validateName(_nameController.text) == null &&
      _validateAge(_ageController.text) == null &&
      _validateUsername(_usernameController.text) == null &&
      _validatePassword(_passwordController.text) == null &&
      _validateAnswer(_securityAnswerController.text) == null &&
      _validatePin(_pinController.text) == null;
    
    if (isValid != _isFormValid) {
      setState(() => _isFormValid = isValid);
    }
  }

  String? _validateName(String? val) {
    if (val == null || val.isEmpty) return "Full name is required";
    if (val.length < 3) return "Full name must be at least 3 characters";
    if (val.length > 50) return "Full name must be at most 50 characters";
    if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(val)) return "Only letters and spaces are allowed";
    if (val.startsWith(' ') || val.endsWith(' ')) return "Cannot start or end with a space";
    return null;
  }

  String? _validateUsername(String? val) {
    if (val == null || val.isEmpty) return "Username is required";
    if (val.length < 4) return "Username must be 4–20 characters";
    if (val.length > 20) return "Username must be 4–20 characters";
    if (!RegExp(r"^[a-z0-9_]+$").hasMatch(val)) return "Only lowercase letters, numbers, and underscore allowed";
    if (val.contains(' ')) return "No spaces allowed";
    return null;
  }

  String? _validateAge(String? val) {
    if (val == null || val.isEmpty) return "Age is required";
    final age = int.tryParse(val);
    if (age == null) return "Age must be a number";
    if (age < 13 || age > 80) return "Age must be between 13 and 80";
    return null;
  }

  String? _validatePassword(String? val) {
    if (val == null || val.isEmpty) return "Password is required";
    if (val.length < 8) return "Password must be at least 8 characters";
    if (!RegExp(r'(?=.*[A-Z])').hasMatch(val)) return "Must include uppercase letter";
    if (!RegExp(r'(?=.*[a-z])').hasMatch(val)) return "Must include lowercase letter";
    if (!RegExp(r'(?=.*[0-9])').hasMatch(val)) return "Must include a number";
    if (val.contains(' ')) return "No spaces allowed";
    return null;
  }

  String? _validateAnswer(String? val) {
    if (val == null || val.isEmpty) return "Answer is required";
    return null;
  }

  String? _validatePin(String? val) {
    if (val == null || val.isEmpty) return "PIN is required";
    if (val.length != 4) return "PIN must be 4 digits";
    if (int.tryParse(val) == null) return "PIN must be numeric";
    return null;
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final newUser = UserModel(
        fullName: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        gender: _selectedGender,
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        securityQuestion: _selectedSecurityQuestion,
        securityAnswer: _securityAnswerController.text.trim(),
        pin: _pinController.text.trim(),
      );

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final error = await authProvider.register(newUser);

      if (error == null && mounted) {
        // Success: Navigate to Home and remove back stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainLayout()),
          (route) => false,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error!)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Create Account",
          style: TextStyle(color: Color(0xFF111827)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
      ),
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
                  TextFormField(
                    controller: _nameController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: "Full Name",
                      labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      helperText: "Min 3 chars, letters only",
                    ),
                    validator: _validateName,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: InputDecoration(
                            labelText: "Age",
                            labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          validator: _validateAge,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedGender,
                          items: ['Male', 'Female', 'Other']
                              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedGender = val!),
                          decoration: InputDecoration(
                            labelText: "Gender",
                            labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _usernameController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: "Username",
                      helperText: "4-20 chars, lowercase, numbers, _",
                      labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: _validateUsername,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: "Password",
                      helperText: "Min 8 chars, 1 uppercase, 1 number",
                      labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 16),
                  
                  // Security Question
                  DropdownButtonFormField<String>(
                    value: _selectedSecurityQuestion,
                    items: _securityQuestions.map((q) => DropdownMenuItem(
                      value: q,
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          q,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedSecurityQuestion = val!),
                    decoration: InputDecoration(
                      labelText: "Security Question",
                      labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    isExpanded: true,
                  ),
                  const SizedBox(height: 16),

                  // Security Answer
                  TextFormField(
                    controller: _securityAnswerController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: "Security Answer",
                      labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: _validateAnswer,
                  ),
                  const SizedBox(height: 16),

                  // PIN
                  TextFormField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: "4-Digit PIN",
                      helperText: "For quick recovery",
                      labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      counterText: "",
                    ),
                    validator: _validatePin,
                  ),
                  const SizedBox(height: 24),
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return auth.isLoading
                          ? const CircularProgressIndicator(color: Color(0xFF4A90E2))
                          : SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isFormValid ? _handleRegister : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4A90E2),
                                  disabledBackgroundColor: Colors.grey[300],
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text("Register", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              ),
                            );
                    },
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
