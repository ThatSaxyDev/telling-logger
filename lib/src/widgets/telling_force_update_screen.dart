import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/version_check_result.dart';

/// A plug-and-play screen to force or prompt users to update the app.
///
/// Usage:
/// ```dart
/// if (result.requiresUpdate) {
///   runApp(MaterialApp(
///     home: TellingForceUpdateScreen(
///       result: result,
///       onSkip: () {
///         // Navigate to main app
///       },
///     ),
///   ));
/// }
/// ```
class TellingForceUpdateScreen extends StatelessWidget {
  final VersionCheckResult result;
  final VoidCallback? onSkip;
  final Color? primaryColor;
  final Color? backgroundColor;
  final Color? textColor;
  final String title;
  final String updateButtonLabel;
  final String skipButtonLabel;

  const TellingForceUpdateScreen({
    super.key,
    required this.result,
    this.onSkip,
    this.primaryColor,
    this.backgroundColor,
    this.textColor,
    this.title = 'Update Required',
    this.updateButtonLabel = 'Update Now',
    this.skipButtonLabel = 'Not Now',
  });

  @override
  Widget build(BuildContext context) {
    // If update is required, ignore back button
    return PopScope(
      canPop: !result.isRequired,
      child: Scaffold(
        backgroundColor: backgroundColor ?? Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: (primaryColor ?? Colors.blue).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.system_update_alt_rounded,
                    size: 64,
                    color: primaryColor ?? Colors.blue,
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor ?? Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // Message
                Text(
                  result.message ??
                      'A new version of the app is available. Please update to continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: (textColor ?? Colors.black87).withOpacity(0.7),
                  ),
                ),
                const Spacer(),

                // Update Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _launchStoreUrl(result.storeUrl),
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor ?? Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      updateButtonLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Skip Button (only if not required)
                if (!result.isRequired) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: onSkip,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        skipButtonLabel,
                        style: TextStyle(
                          color: (textColor ?? Colors.black87).withOpacity(0.6),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchStoreUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
