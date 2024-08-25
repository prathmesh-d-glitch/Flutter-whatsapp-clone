import 'package:flutter/material.dart';

import 'package:whatsapp_messenger/common/routes/routes.dart';

import 'package:whatsapp_messenger/common/widgets/custom_elevated_button.dart';

import 'package:whatsapp_messenger/feature/welcome/widgets/language_button.dart';

import 'package:whatsapp_messenger/feature/welcome/widgets/privacy_and_terms.dart';

import 'package:whatsapp_messenger/common/extension/custom_theme_extension.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  navigateToLoginPage(context) {
    Navigator.of(context).pushNamedAndRemoveUntil(Routes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 10,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                  ),
                  child: Image.asset(
                    'assets/images/circle.png',
                    color: context.theme.circleImageColor,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'Welcome to Whatsapp',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const PrivacyAndTerms(),                
                const SizedBox(
                  height: 5,
                ),
                const LanguageButton(),
                const SizedBox(height: 230,),
                CustomElevatedButton(
                  onPressed: () => navigateToLoginPage(context),
                  buttonWidth: double.maxFinite,
                  text: 'Agree and continue',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

