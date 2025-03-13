import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_bunny/presentation/widgets/signup_widgets.dart';
import 'package:mobile_bunny/presentation/pages/home_menu_page.dart';
import 'package:mobile_bunny/presentation/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _getAuthErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'L\'adresse e-mail n\'est pas valide';
        case 'email-already-in-use':
          return 'Cette adresse e-mail est déjà utilisée par un autre compte';
        case 'weak-password':
          return 'Le mot de passe doit contenir au moins 6 caractères';
        case 'network-request-failed':
          return 'Erreur de connexion réseau';
        case 'too-many-requests':
          return 'Trop de tentatives. Veuillez réessayer plus tard';
        default:
          return 'Une erreur s\'est produite lors de l\'inscription';
      }
    }
    return 'Une erreur inattendue s\'est produite';
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        _showErrorMessage('Les mots de passe ne correspondent pas');
        return;
      }

      setState(() => _isLoading = true);

      try {
        await ref.read(authProvider.notifier).signUp(
              _emailController.text,
              _passwordController.text,
            );
            
        _showSuccessMessage('Inscription réussie !');

        // Navigate to HomePage after successful signup
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MenuPage(),
          ),
        );
      } catch (e) {
        _showErrorMessage(_getAuthErrorMessage(e));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorMessage(String message) {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Erreur'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessMessage(String message) {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Succès'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    
    return isIOS
        ? CupertinoPageScaffold(
            backgroundColor: const Color(0xFF1C1C1C),
            child: _buildBody(isIOS),
          )
        : Scaffold(
            backgroundColor: const Color(0xFF1C1C1C),
            body: _buildBody(isIOS),
          );
  }

  Widget _buildBody(bool isIOS) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SignupForm(
            emailController: _emailController,
            passwordController: _passwordController,
            confirmPasswordController: _confirmPasswordController,
            isPasswordVisible: _isPasswordVisible,
            isConfirmPasswordVisible: _isConfirmPasswordVisible,
            isLoading: _isLoading,
            onSubmit: _submitForm,
            onTogglePasswordVisibility: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
            onToggleConfirmPasswordVisibility: () {
              setState(() {
                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
              });
            },
            isIOS: isIOS,
          ),
        ),
      ),
    );
  }
}