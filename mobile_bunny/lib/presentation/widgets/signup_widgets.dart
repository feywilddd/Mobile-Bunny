import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    super.key,
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
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 48),
        _buildLogo(),
        const SizedBox(height: 48),
        _buildEmailField(context),
        const SizedBox(height: 16),
        _buildPasswordField(context),
        const SizedBox(height: 16),
        _buildConfirmPasswordField(context),
        const SizedBox(height: 24),
        _buildSignupButton(context),
        const SizedBox(height: 24),
        _buildLoginRedirect(context),
      ],
    );
  }

  Widget _buildLogo() {
    return Center(
      child: CachedNetworkImage(
        imageUrl: 'http://4.172.227.199/image_hosting/uploads/BunnyCOLogo.png',
        placeholder: (context, url) => isIOS
            ? const CupertinoActivityIndicator()
            : const CircularProgressIndicator(),
        errorWidget: (context, url, error) => const Icon(Icons.error),
        width: 120,
        height: 120,
      ),
    );
  }

  Widget _buildEmailField(BuildContext context) {
    if (isIOS) {
      return CupertinoTextField(
        controller: emailController,
        placeholder: 'aaaa@exemple.com',
        placeholderStyle: TextStyle(color: Colors.grey[600]),
        style: const TextStyle(color: Colors.white),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
      );
    } else {
      return TextFormField(
        controller: emailController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'aaaa@exemple.com',
          hintStyle: TextStyle(color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.grey[900],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
        validator: _validateEmail,
      );
    }
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
    if (isIOS) {
      return CupertinoTextField(
        controller: passwordController,
        placeholder: 'Mot de passe',
        placeholderStyle: TextStyle(color: Colors.grey[600]),
        style: const TextStyle(color: Colors.white),
        obscureText: !isPasswordVisible,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        suffix: GestureDetector(
          onTap: onTogglePasswordVisibility,
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(
              isPasswordVisible ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    } else {
      return TextFormField(
        controller: passwordController,
        obscureText: !isPasswordVisible,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Mot de passe',
          hintStyle: TextStyle(color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.grey[900],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(16),
          suffixIcon: IconButton(
            icon: Icon(
              isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[600],
            ),
            onPressed: onTogglePasswordVisibility,
          ),
        ),
        validator: _validatePassword,
      );
    }
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
    if (isIOS) {
      return CupertinoTextField(
        controller: confirmPasswordController,
        placeholder: 'Confirmez le mot de passe',
        placeholderStyle: TextStyle(color: Colors.grey[600]),
        style: const TextStyle(color: Colors.white),
        obscureText: !isConfirmPasswordVisible,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        suffix: GestureDetector(
          onTap: onToggleConfirmPasswordVisibility,
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(
              isConfirmPasswordVisible ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    } else {
      return TextFormField(
        controller: confirmPasswordController,
        obscureText: !isConfirmPasswordVisible,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Confirmez le mot de passe',
          hintStyle: TextStyle(color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.grey[900],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(16),
          suffixIcon: IconButton(
            icon: Icon(
              isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[600],
            ),
            onPressed: onToggleConfirmPasswordVisibility,
          ),
        ),
        validator: _validateConfirmPassword,
      );
    }
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
    if (isIOS) {
      return CupertinoButton(
        onPressed: isLoading ? null : onSubmit,
        padding: const EdgeInsets.symmetric(vertical: 16),
        color: const Color(0xFFDB816E),
        borderRadius: BorderRadius.circular(12),
        child: isLoading
            ? const CupertinoActivityIndicator(color: Colors.white)
            : const Text(
                'S\'inscrire',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      );
    } else {
      return ElevatedButton(
        onPressed: isLoading ? null : onSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDB816E),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
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
  }

  Widget _buildLoginRedirect(BuildContext context) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        'Déjà un compte ?',
        style: TextStyle(
          color: Color(0xFFBDBDBD), 
          fontSize: 12,
          decoration: TextDecoration.none, // Remove the const to add this property
        ),
      ),
      isIOS
          ? CupertinoButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              padding: EdgeInsets.zero,
              child: const Text(
                'Se connecter',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            )
          : TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: const Text(
                'Se connecter',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
    ],
  );
}
}