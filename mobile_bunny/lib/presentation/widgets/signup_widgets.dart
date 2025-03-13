import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:mobile_bunny/presentation/pages/login_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io' show Platform;

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
        const SizedBox(height: 32),
        _buildLogo(),
        const SizedBox(height: 42),
        _buildEmailField(context),
        const SizedBox(height: 16),
        _buildPasswordField(context),
        const SizedBox(height: 16),
        _buildConfirmPasswordField(context),
        const SizedBox(height: 28),
        _buildSignupButton(context),
        _buildDividerWithText(),
        _buildLoginRedirect(context),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Column(
        children: [
          CachedNetworkImage(
            imageUrl: 'http://4.172.227.199/image_hosting/uploads/BunnyCOLogo.png',
            placeholder: (context, url) => isIOS
                ? const CupertinoActivityIndicator()
                : const CircularProgressIndicator(),
            errorWidget: (context, url, error) => const Icon(Icons.error),
            width: 80,
            height: 80,
          ),
          const SizedBox(height: 12),
          const Text(
            'Bunny & co.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade800.withOpacity(0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: TextFormField(
          controller: emailController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Email',
            hintStyle: TextStyle(color: Colors.grey[500]),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[500], size: 20),
            filled: true,
            fillColor: Colors.transparent,
          ),
          keyboardType: TextInputType.emailAddress,
          validator: _validateEmail,
        ),
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
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade800.withOpacity(0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: TextFormField(
          controller: passwordController,
          obscureText: !isPasswordVisible,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Mot de passe',
            hintStyle: TextStyle(color: Colors.grey[500]),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[500], size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[400],
                size: 20,
              ),
              onPressed: onTogglePasswordVisibility,
              splashRadius: 20,
            ),
            filled: true,
            fillColor: Colors.transparent,
          ),
          validator: _validatePassword,
        ),
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
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade800.withOpacity(0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: TextFormField(
          controller: confirmPasswordController,
          obscureText: !isConfirmPasswordVisible,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Confirmer le mot de passe',
            hintStyle: TextStyle(color: Colors.grey[500]),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[500], size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[400],
                size: 20,
              ),
              onPressed: onToggleConfirmPasswordVisibility,
              splashRadius: 20,
            ),
            filled: true,
            fillColor: Colors.transparent,
          ),
          validator: _validateConfirmPassword,
        ),
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
        backgroundColor: const Color(0xFFDB816E).withOpacity(0.95),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        minimumSize: const Size(double.infinity, 52),
        elevation: 0.5,
      ),
      child: isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
          : const Text(
              'S\'inscrire',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.3,
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
            child: Divider(color: Colors.grey.shade800.withOpacity(0.6), thickness: 0.8),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'ou',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Divider(color: Colors.grey.shade800.withOpacity(0.6), thickness: 0.8),
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
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 13,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: const Size(0, 32),
          ),
          child: const Text(
            'Se connecter',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}