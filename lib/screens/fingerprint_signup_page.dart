import 'package:flutter/material.dart';
import 'dart:async';
import '../config/theme.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import 'main_navigation.dart';

class FingerprintSignupPage extends StatefulWidget {
  const FingerprintSignupPage({super.key});

  @override
  State<FingerprintSignupPage> createState() => _FingerprintSignupPageState();
}

class _FingerprintSignupPageState extends State<FingerprintSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _fingerprintIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nomineeController = TextEditingController();
  final _databaseService = DatabaseService();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isFetching = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _statusMessage = 'Waiting for new fingerprint...';

  @override
  void initState() {
    super.initState();
    _fetchFingerprintId();
  }

  @override
  void dispose() {
    _fingerprintIdController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nomineeController.dispose();
    super.dispose();
  }

  Future<void> _fetchFingerprintId() async {
    setState(() {
      _isFetching = true;
      _statusMessage = 'Checking for new fingerprint...';
    });

    try {
      final scan = await _databaseService.getLatestFingerprintScan();
      if (scan != null && scan['type'] == 'signup') {
        setState(() {
          _fingerprintIdController.text = scan['fingerprintId'].toString();
          _statusMessage = 'New fingerprint ID received!';
          _isFetching = false;
        });
        await _databaseService.clearLatestFingerprintScan();
      } else {
        setState(() {
          _statusMessage = 'No new fingerprint. Place NEW finger on sensor.';
          _isFetching = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error fetching scan. Try refresh.';
        _isFetching = false;
      });
    }
  }

  Future<void> _handleFingerprintSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final fingerprintId = int.parse(_fingerprintIdController.text.trim());
        
        final userId = await _databaseService.signupWithFingerprint(
          fingerprintId: fingerprintId,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          password: _passwordController.text,
          nomineeNumber: _nomineeController.text.trim(),
        );

        setState(() => _isLoading = false);

        if (userId != null && mounted) {
          final user = await _databaseService.loginWithFingerprint(fingerprintId);
          if (user != null) {
            await _authService.saveUser(user);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainNavigation()),
            );
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sign up failed. Fingerprint may already be registered.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up with Fingerprint'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Icon(
                  Icons.fingerprint,
                  size: 80,
                  color: AppTheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Create Account with Fingerprint',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Steps:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textBlack,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. Place NEW finger on ESP32 sensor\n'
                        '2. Wait for enrollment (remove & place again)\n'
                        '3. Check Serial Monitor for "New fingerprint ID: X"\n'
                        '4. Enter that ID below with your details',
                        style: TextStyle(color: AppTheme.textDark, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _fingerprintIdController,
                        keyboardType: TextInputType.number,
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'Fingerprint ID',
                          prefixIcon: Icon(Icons.fingerprint, color: AppTheme.primary),
                          helperText: _statusMessage,
                          suffixIcon: _fingerprintIdController.text.isNotEmpty
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : null,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'No fingerprint detected';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _isFetching ? null : _fetchFingerprintId,
                      icon: _isFetching
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh, size: 32),
                      color: AppTheme.primary,
                      tooltip: 'Fetch Fingerprint ID',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person, color: AppTheme.primary),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email, color: AppTheme.primary),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone, color: AppTheme.primary),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (value.length < 10) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock, color: AppTheme.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: AppTheme.textDark,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock, color: AppTheme.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        color: AppTheme.textDark,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nomineeController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Nominee Number',
                    prefixIcon: Icon(Icons.contact_phone, color: AppTheme.primary),
                    helperText: 'Emergency contact',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter nominee number';
                    }
                    if (value.length < 10) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_isLoading || _fingerprintIdController.text.isEmpty) 
                        ? null 
                        : _handleFingerprintSignup,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Sign Up',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
