import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';

/// Placeholder — Family (add self / members) screen is the next step.
class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('My Family – coming next', style: AppTextStyles.title)),
    );
  }
}
