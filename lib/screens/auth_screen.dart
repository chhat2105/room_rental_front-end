import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  final int initialTab; // 0 for Login, 1 for Register

  const AuthScreen({super.key, this.initialTab = 0});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Login
  final _loginUserCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();

  // Register
  final _regFirstCtrl = TextEditingController();
  final _regLastCtrl = TextEditingController();
  final _regUserCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPhoneCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regConfirmPassCtrl = TextEditingController();
  String _selectedRole = 'ROLE_TENANT'; // 'ROLE_TENANT' or 'ROLE_LANDLORD'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginUserCtrl.dispose();
    _loginPassCtrl.dispose();
    _regFirstCtrl.dispose();
    _regLastCtrl.dispose();
    _regUserCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPhoneCtrl.dispose();
    _regPassCtrl.dispose();
    _regConfirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final username = _loginUserCtrl.text.trim();
    final password = _loginPassCtrl.text;
    if (username.isEmpty || password.isEmpty) return;

    final auth = context.read<AuthProvider>();
    try {
      await auth.login(username, password);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.accentEmerald,
            content: Text('Welcome back to RentHub!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.accentRose,
            content: Text(e.toString().replaceAll('Exception: ', '')),
          ),
        );
      }
    }
  }

  Future<void> _handleRegister() async {
    if (_regPassCtrl.text != _regConfirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: AppTheme.accentRose, content: Text('Passwords do not match')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    try {
      await auth.register(
        firstName: _regFirstCtrl.text.trim(),
        lastName: _regLastCtrl.text.trim(),
        username: _regUserCtrl.text.trim(),
        email: _regEmailCtrl.text.trim(),
        phoneNumber: _regPhoneCtrl.text.trim(),
        password: _regPassCtrl.text,
        confirmPassword: _regConfirmPassCtrl.text,
        role: _selectedRole,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.accentEmerald,
            content: Text('Account created! Please sign in.'),
          ),
        );
        _loginUserCtrl.text = _regUserCtrl.text.trim();
        _tabController.animateTo(0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.accentRose,
            content: Text(e.toString().replaceAll('Exception: ', '')),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Access'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: Colors.white,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(text: 'Sign In'),
            Tab(text: 'Create Account'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // SIGN IN FORM
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text('Welcome Back', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 6),
                const Text('Sign in with your RentHub account credentials', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                const SizedBox(height: 30),
                TextField(
                  controller: _loginUserCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Username or Phone',
                    prefixIcon: Icon(Icons.person_outline, color: AppTheme.primaryLight),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _loginPassCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline, color: AppTheme.primaryLight),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleLogin,
                    child: auth.isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Sign In'),
                  ),
                ),
              ],
            ),
          ),

          // REGISTER FORM
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Join RentHub', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 6),
                const Text('Choose your account type and start renting or hosting', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                const SizedBox(height: 20),

                // Role Selector Cards
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedRole = 'ROLE_TENANT'),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _selectedRole == 'ROLE_TENANT'
                                ? AppTheme.primary.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedRole == 'ROLE_TENANT' ? AppTheme.primary : AppTheme.borderDark,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.key, color: _selectedRole == 'ROLE_TENANT' ? AppTheme.primaryLight : AppTheme.textDim),
                              const SizedBox(height: 6),
                              const Text('Tenant', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              const Text('Find & Rent rooms', style: TextStyle(color: AppTheme.textDim, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedRole = 'ROLE_LANDLORD'),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _selectedRole == 'ROLE_LANDLORD'
                                ? AppTheme.accentEmerald.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedRole == 'ROLE_LANDLORD' ? AppTheme.accentEmerald : AppTheme.borderDark,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.business_outlined, color: _selectedRole == 'ROLE_LANDLORD' ? AppTheme.accentEmerald : AppTheme.textDim),
                              const SizedBox(height: 6),
                              const Text('Landlord', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              const Text('List your properties', style: TextStyle(color: AppTheme.textDim, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(child: TextField(controller: _regFirstCtrl, decoration: const InputDecoration(labelText: 'First Name'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: _regLastCtrl, decoration: const InputDecoration(labelText: 'Last Name'))),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: _regUserCtrl, decoration: const InputDecoration(labelText: 'Username')),
                const SizedBox(height: 12),
                TextField(controller: _regEmailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 12),
                TextField(controller: _regPhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number')),
                const SizedBox(height: 12),
                TextField(controller: _regPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                const SizedBox(height: 12),
                TextField(controller: _regConfirmPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm Password')),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleRegister,
                    child: auth.isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Complete Registration'),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
