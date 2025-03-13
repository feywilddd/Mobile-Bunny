import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:mobile_bunny/presentation/pages/login_page.dart';

class SignupForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool isPasswordVisible;
  final bool isConfirmPasswordVisible;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onToggleConfirmPasswordVisibility;
  final bool isIOS;

  const SignupForm({
    Key? key,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.isPasswordVisible,
    required this.isConfirmPasswordVisible,
    required this.isLoading,
    required this.onSubmit,
    required this.onTogglePasswordVisibility,
    required this.onToggleConfirmPasswordVisibility,
    required this.isIOS,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        _buildLogo(),
        const SizedBox(height: 36),
        _buildEmailField(context),
        const SizedBox(height: 16),
        _buildPasswordField(context),
        const SizedBox(height: 16),
        _buildConfirmPasswordField(context),
        const SizedBox(height: 24),
        _buildSignupButton(context),
        _buildDividerWithText(),
        const SizedBox(height: 16),
        _buildGoogleSignIn(context),
        const SizedBox(height: 16),
        _buildLoginRedirect(context),
      ],
    );
  }

  Widget _buildLogo() {
    return const Center(
      child: Column(
        children: [
          Image(
            image: AssetImage('assets/images/bunny_logo.png'),
            width: 80,
            height: 80,
            color: Colors.white,
          ),
          SizedBox(height: 8),
          Text(
            'Bunny & co.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: TextFormField(
        controller: emailController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'aaaa@exemple.com',
          hintStyle: TextStyle(color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          prefixIcon: const SizedBox(width: 10),
          filled: true,
          fillColor: Colors.transparent,
        ),
        validator: _validateEmail,
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer une adresse email';
    }
    if (!value.contains('@')) {
      return 'Veuillez entrer une adresse email valide';
    }
    return null;
  }

  Widget _buildPasswordField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: TextFormField(
        controller: passwordController,
        obscureText: !isPasswordVisible,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'aaaa@exemple.com',
          hintStyle: TextStyle(color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          prefixIcon: const Icon(Icons.lock, color: Colors.grey, size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[600],
              size: 20,
            ),
            onPressed: onTogglePasswordVisibility,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
        validator: _validatePassword,
      ),
    );
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un mot de passe';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    return null;
  }

  Widget _buildConfirmPasswordField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: TextFormField(
        controller: confirmPasswordController,
        obscureText: !isConfirmPasswordVisible,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'aaaa@exemple.com',
          hintStyle: TextStyle(color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          prefixIcon: const Icon(Icons.lock, color: Colors.grey, size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[600],
              size: 20,
            ),
            onPressed: onToggleConfirmPasswordVisibility,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
        validator: _validateConfirmPassword,
      ),
    );
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer le mot de passe';
    }
    if (value != passwordController.text) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  Widget _buildSignupButton(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onSubmit,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFDB816E),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: const Size(double.infinity, 50),
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Text(
              'S\'inscrire',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
    );
  }
  
  Widget _buildDividerWithText() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: Colors.grey.shade800, thickness: 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'ou',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ),
          Expanded(
            child: Divider(color: Colors.grey.shade800, thickness: 1),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGoogleSignIn(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        // Add Google sign-in functionality
      },
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey.shade800),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/google_logo.png',
            height: 24,
            width: 24,
          ),
          const SizedBox(width: 12),
          const Text(
            'Continuer avec Google',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginRedirect(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Déjà un compte?',
          style: TextStyle(color: Colors.grey.shade400),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: const Text(
            'Se connecter',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}