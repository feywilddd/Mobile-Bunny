import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io' show Platform;

class LoginWidgets {
  // Logo widget that can be reused across pages
  static Widget buildLogo() {
    return Center(
      child: Column(
        children: [
          CachedNetworkImage(
            imageUrl: 'http://4.172.227.199/image_hosting/uploads/BunnyCOLogo.png',
            placeholder: (context, url) => Platform.isIOS
                ? const CupertinoActivityIndicator()
                : const CircularProgressIndicator(),
            errorWidget: (context, url, error) => const Icon(Icons.error),
            width: 100,
            height: 100,
          ),
          const SizedBox(height: 8),
          const Text(
            'Bunny & co.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  // Cupertino email field
  static Widget buildCupertinoEmailField(TextEditingController controller) {
    return CupertinoTextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      placeholder: 'aaaa@exemple.com',
      placeholderStyle: TextStyle(color: Colors.grey[500]),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
      ),
    );
  }

  // Cupertino password field with toggle visibility
  static Widget buildCupertinoPasswordField(
    TextEditingController controller,
    bool isPasswordVisible,
    Function() toggleVisibility,
  ) {
    return CupertinoTextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      placeholder: 'Mot de passe',
      placeholderStyle: TextStyle(color: Colors.grey[500]),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      obscureText: !isPasswordVisible,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
      ),
      prefix: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Icon(
          CupertinoIcons.lock,
          color: Colors.grey[500],
          size: 20,
        ),
      ),
      suffix: CupertinoButton(
        padding: const EdgeInsets.only(right: 8),
        onPressed: toggleVisibility,
        child: Icon(
          isPasswordVisible ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
          color: Colors.grey[500],
          size: 20,
        ),
      ),
    );
  }

  // Material email field with validation
  static Widget buildMaterialEmailField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'aaaa@exemple.com',
        hintStyle: TextStyle(color: Colors.grey[500]),
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[800]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[800]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez entrer une adresse email';
        }
        if (!value.contains('@')) {
          return 'Veuillez entrer une adresse email valide';
        }
        return null;
      },
    );
  }

  // Material password field with validation and toggle visibility
  static Widget buildMaterialPasswordField(
    TextEditingController controller,
    bool isPasswordVisible,
    Function() toggleVisibility,
  ) {
    return TextFormField(
      controller: controller,
      obscureText: !isPasswordVisible,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Mot de passe',
        hintStyle: TextStyle(color: Colors.grey[500]),
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[800]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[800]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        prefixIcon: Icon(
          Icons.lock_outline,
          color: Colors.grey[500],
          size: 20,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordVisible ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey[500],
            size: 20,
          ),
          onPressed: toggleVisibility,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez entrer un mot de passe';
        }
        if (value.length < 6) {
          return 'Le mot de passe doit contenir au moins 6 caractères';
        }
        return null;
      },
    );
  }

  // Sign up prompt for both platforms
  static Widget buildSignupPrompt(bool isCupertino, Function() onTap) {
    if (isCupertino) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Vous n\'avez pas de compte ?',
            style: TextStyle(
              color: Colors.grey[400], 
              fontSize: 13,
              decoration: TextDecoration.none,
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.only(left: 4),
            minSize: 0,
            onPressed: onTap,
            child: const Text(
              'S\'inscrire',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Vous n\'avez pas de compte ?',
            style: TextStyle(
              color: Colors.grey[400], 
              fontSize: 13,
              decoration: TextDecoration.none,
            ),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.only(left: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'S\'inscrire',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      );
    }
  }

  // "OR" divider 
  static Widget buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey[800],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OU',
            style: TextStyle(
              color: Colors.grey[400], 
              fontSize: 12,
              decoration: TextDecoration.none,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  // Google sign-in button for both platforms
  static Widget buildGoogleButton(bool isCupertino, Function() onPressed) {
    if (isCupertino) {
      return CupertinoButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[800]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CachedNetworkImage(
                imageUrl: 'http://4.172.227.199/image_hosting/uploads/google.png',
                height: 20,
                placeholder: (context, url) => Platform.isIOS
                    ? const CupertinoActivityIndicator(radius: 8)
                    : const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                errorWidget: (context, url, error) => Icon(
                  Platform.isIOS ? CupertinoIcons.exclamationmark_circle : Icons.error,
                  size: 20,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Continuer avec Google',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: Colors.grey[800]!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CachedNetworkImage(
              imageUrl: 'http://4.172.227.199/image_hosting/uploads/google.png',
              height: 20,
              placeholder: (context, url) => SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.grey[400],
                ),
              ),
              errorWidget: (context, url, error) => Icon(
                Icons.error,
                size: 20,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Continuer avec Google',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      );
    }
  }

  // Show error message dialog/snackbar
  static void showErrorMessage(BuildContext context, String message) {
    if (Platform.isIOS) {
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

  // Show success message dialog/snackbar
  static void showSuccessMessage(BuildContext context, String message) {
    if (Platform.isIOS) {
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
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}