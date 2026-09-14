import 'package:flutter/material.dart';

import '../widgets/landing_contact_section.dart';
import '../widgets/landing_features_section.dart';
import '../widgets/landing_final_cta_section.dart';
import '../widgets/landing_footer.dart';
import '../widgets/landing_hero.dart';
import '../widgets/landing_how_it_works_section.dart';
import '../widgets/landing_nav_bar.dart';
import '../widgets/landing_platforms_section.dart';
import '../widgets/landing_registration_process_section.dart';

/// Public marketing landing page — registered for Flutter Web only.
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: const Column(
        children: [
          LandingNavBar(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LandingHero(),
                  LandingFeaturesSection(),
                  LandingRegistrationProcessSection(),
                  LandingHowItWorksSection(),
                  LandingPlatformsSection(),
                  LandingContactSection(),
                  LandingFinalCtaSection(),
                  LandingFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
