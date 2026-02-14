import 'package:flutter/material.dart';
import 'dart:async';
import '../config/theme.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import 'main_navigation.dart';

class FingerprintLoginPage extends StatefulWidget {
  const FingerprintLoginPage({super.key});

  @override
  State<FingerprintLoginPage> createState() => _FingerprintLoginPageState();
}

class _FingerprintLoginPageState extends State<FingerprintLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _fingerprintIdController = TextEditingController();
  final _databaseService = DatabaseService();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isFetching = false;
  String _statusMessage = 'Waiting for fingerprint scan...';

  @override
  void initState() {
    super.initState();
    _fetchFingerprintId();
  }

  @override
  void dispose() {
    _fingerprintIdController.dispose();
    super.dispose();
  }

  Future<void> _fetchFingerprintId() async {
    print('🔍 [DEBUG] Fetching fingerprint ID...');
    setState(() {
      _isFetching = true;
      _statusMessage = 'Checking for fingerprint scan...';
    });

    try {
      final scan = await _databaseService.getLatestFingerprintScan();
      print('🔍 [DEBUG] Scan result: $scan');
      
      if (scan != null && scan['type'] == 'login') {
        print('✅ [DEBUG] Login scan found! ID: ${scan['fingerprintId']}');
        setState(() {
          _fingerprintIdController.text = scan['fingerprintId'].toString();
          _statusMessage = 'Fingerprint ID received!';
          _isFetching = false;
        });
        await _databaseService.clearLatestFingerprintScan();
        print('🔍 [DEBUG] Scan cleared from backend');
      } else {
        print('⚠️ [DEBUG] No login scan found. Scan data: $scan');
        setState(() {
          _statusMessage = 'No scan found. Place finger on sensor.';
          _isFetching = false;
        });
      }
    } catch (e) {
      print('❌ [DEBUG] Error fetching scan: $e');
      setState(() {
        _statusMessage = 'Error fetching scan. Try refresh.';
        _isFetching = false;
      });
    }
  }

  Future<void> _handleFingerprintLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final fingerprintId = int.parse(_fingerprintIdController.text.trim());
        final user = await _databaseService.loginWithFingerprint(fingerprintId);

        setState(() => _isLoading = false);

        if (user != null && mounted) {
          await _authService.saveUser(user);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigation()),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fingerprint not registered. Please sign up first.'),
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
        title: const Text('Fingerprint Login'),
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
                const SizedBox(height: 40),
                Icon(
                  Icons.fingerprint,
                  size: 120,
                  color: AppTheme.primary,
                ),
                const SizedBox(height: 32),
                Text(
                  'Login with Fingerprint',
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Enter the fingerprint ID from your ESP32 device',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
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
                            'How it works:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textBlack,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. Place your registered finger on ESP32 sensor\n'
                        '2. ESP32 sends fingerprint ID to backend\n'
                        '3. Click "Fetch ID" button below\n'
                        '4. ID will appear automatically',
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
                const SizedBox(height: 24),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_isLoading || _fingerprintIdController.text.isEmpty) 
                        ? null 
                        : _handleFingerprintLogin,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Login',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
}
