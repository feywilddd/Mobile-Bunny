import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_bunny/presentation/pages/home_menu_page.dart';
import 'package:mobile_bunny/presentation/pages/inscription_page.dart';
import 'package:mobile_bunny/presentation/providers/auth_provider.dart';
import 'package:mobile_bunny/presentation/widgets/login_widgets.dart'; // Import the new widgets file
import 'dart:io' show Platform;

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _getAuthErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'L\'adresse e-mail n\'est pas valide';
        case 'user-disabled':
          return 'Ce compte utilisateur a été désactivé';
        case 'user-not-found':
          return 'Aucun utilisateur trouvé avec cette adresse e-mail';
        case 'wrong-password':
          return 'Mot de passe incorrect';
        case 'email-already-in-use':
          return 'Cette adresse e-mail est déjà utilisée par un autre compte';
        case 'operation-not-allowed':
          return 'Cette opération n\'est pas autorisée';
        case 'weak-password':
          return 'Le mot de passe doit être plus fort';
        case 'network-request-failed':
          return 'Erreur de connexion réseau';
        case 'too-many-requests':
          return 'Trop de tentatives de connexion. Veuillez réessayer plus tard';
        default:
          return 'Une erreur s\'est produite lors de l\'authentification';
      }
    }
    return 'Une erreur inattendue s\'est produite';
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await ref.read(authProvider.notifier).signInWithEmail(
              _emailController.text,
              _passwordController.text,
            );
        // If sign-in is successful, navigate to the HomePage
        Navigator.pushReplacement(
          context,
          Platform.isIOS
              ? CupertinoPageRoute(builder: (context) => const MenuPage())
              : MaterialPageRoute(builder: (context) => const MenuPage()),
        );
      } catch (e) {
        LoginWidgets.showErrorMessage(context, _getAuthErrorMessage(e));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final user = await ref.read(authProvider.notifier).signInWithGoogle();
      if (user != null) {
        LoginWidgets.showSuccessMessage(context, 'Connexion réussie avec Google !');
        // Navigate to MenuPage after successful sign-in
        Navigator.pushReplacement(
          context,
          Platform.isIOS
              ? CupertinoPageRoute(builder: (context) => const MenuPage())
              : MaterialPageRoute(builder: (context) => const MenuPage()),
        );
      }
    } catch (e) {
      LoginWidgets.showErrorMessage(context, _getAuthErrorMessage(e));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToSignup() {
    Navigator.push(
      context,
      Platform.isIOS
          ? CupertinoPageRoute(builder: (context) => const SignupPage())
          : MaterialPageRoute(builder: (context) => const SignupPage()),
    );
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS ? _buildIOSLayout() : _buildAndroidLayout();
  }

  // Cupertino (iOS) Layout
  Widget _buildIOSLayout() {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LoginWidgets.buildLogo(),
                    const SizedBox(height: 24),
                    LoginWidgets.buildCupertinoEmailField(_emailController),
                    const SizedBox(height: 16),
                    LoginWidgets.buildCupertinoPasswordField(
                      _passwordController, 
                      _isPasswordVisible, 
                      _togglePasswordVisibility
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {},
                        child: Text(
                          'Mot de passe oublié ?',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _isLoading
                        ? const Center(child: CupertinoActivityIndicator())
                        : CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            onPressed: _submitForm,
                            color: const Color(0xFFDB816E),
                            borderRadius: BorderRadius.circular(8),
                            child: const Text(
                              'Se connecter',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                    const SizedBox(height: 12),
                    LoginWidgets.buildSignupPrompt(true, _navigateToSignup),
                    const SizedBox(height: 16),
                    LoginWidgets.buildDivider(),
                    const SizedBox(height: 16),
                    LoginWidgets.buildGoogleButton(true, _signInWithGoogle),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Material (Android) Layout
  Widget _buildAndroidLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LoginWidgets.buildLogo(),
                    const SizedBox(height: 24),
                    LoginWidgets.buildMaterialEmailField(_emailController),
                    const SizedBox(height: 16),
                    LoginWidgets.buildMaterialPasswordField(
                      _passwordController, 
                      _isPasswordVisible, 
                      _togglePasswordVisibility
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Mot de passe oublié ?',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDB816E),
                        disabledBackgroundColor: const Color(0xFFDB816E).withOpacity(0.6),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Se connecter',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                decoration: TextDecoration.none,
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    LoginWidgets.buildSignupPrompt(false, _navigateToSignup),
                    const SizedBox(height: 16),
                    LoginWidgets.buildDivider(),
                    const SizedBox(height: 16),
                    LoginWidgets.buildGoogleButton(false, _signInWithGoogle),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}