import 'package:flutter/material.dart';
import 'package:yappsters/core/theme/app_pallete.dart';
import 'package:yappsters/core/constants/routes.dart';

class PhoneAuthDisabledPage extends StatelessWidget {
  const PhoneAuthDisabledPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppPallete.transparentColor,
        elevation: 0,
        title: const Text('Phone Authentication',
            style: TextStyle(color: AppPallete.whiteColor)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppPallete.whiteColor),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Premium Feature Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppPallete.gradient1.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppPallete.gradient1, width: 2),
              ),
              child: const Icon(
                Icons.workspace_premium,
                size: 60,
                color: AppPallete.gradient1,
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              'Premium Feature',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppPallete.whiteColor,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            const Text(
              'Phone Authentication',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppPallete.gradient1,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppPallete.borderColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppPallete.borderColor),
              ),
              child: Column(
                children: [
                  Row(
                    children: const [
                      Icon(Icons.check_circle,
                          color: AppPallete.gradient1, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'SMS verification with OTP',
                          style: TextStyle(
                              color: AppPallete.whiteColor, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: const [
                      Icon(Icons.check_circle,
                          color: AppPallete.gradient1, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Enhanced account security',
                          style: TextStyle(
                              color: AppPallete.whiteColor, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: const [
                      Icon(Icons.check_circle,
                          color: AppPallete.gradient1, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Two-factor authentication',
                          style: TextStyle(
                              color: AppPallete.whiteColor, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppPallete.gradient1.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppPallete.gradient1.withOpacity(0.3)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: AppPallete.gradient1),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This feature requires a premium subscription and Firebase billing setup.',
                      style: TextStyle(
                        color: AppPallete.gradient1,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, loginRoute),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPallete.gradient2,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue with Email',
                style: TextStyle(
                  color: AppPallete.whiteColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 16),

            OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Premium features coming soon!'),
                    backgroundColor: AppPallete.gradient1,
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppPallete.gradient1),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Learn About Premium',
                style: TextStyle(
                  color: AppPallete.gradient1,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
