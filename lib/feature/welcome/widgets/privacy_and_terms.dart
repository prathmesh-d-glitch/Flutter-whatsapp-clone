import 'package:flutter/material.dart';
import 'package:whatsapp_messenger/common/extension/custom_theme_extension.dart';
class PrivacyAndTerms extends StatelessWidget {
  const PrivacyAndTerms({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 30,
                  ),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: 'Read out ',
                      style: TextStyle(
                        color: context.theme.greyColor,
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(
                          text: 'Privacy Policy. ',
                          style: TextStyle(
                            color: context.theme.blueColor,
                          ),
                        ),
                        const TextSpan(
                          text: 'Tap "Agree and continue" to accept the ',
                        ),
                        TextSpan(
                          text: 'Terms of services. ',
                          style: TextStyle(
                            color: context.theme.blueColor,
                          ),
                        )
                      ],
                    ),
                  ),
                );
  }
  
}