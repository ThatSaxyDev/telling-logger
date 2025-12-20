/// Result of a version check call.
///
/// Used to determine if the app needs to be updated and whether
/// the update is required (blocking) or optional (skippable).
class VersionCheckResult {
  /// Whether the current app version is below the minimum required version.
  final bool requiresUpdate;

  /// Whether the update is mandatory (blocking) or optional (can skip).
  /// Only relevant when [requiresUpdate] is true.
  final bool isRequired;

  /// URL to the app store for updating.
  /// Only present when [requiresUpdate] is true.
  final String? storeUrl;

  /// Message to display to the user.
  /// Only present when [requiresUpdate] is true.
  final String? message;

  const VersionCheckResult({
    required this.requiresUpdate,
    this.isRequired = true,
    this.storeUrl,
    this.message,
  });

  /// Default result indicating no update is needed.
  static const noUpdateRequired = VersionCheckResult(requiresUpdate: false);

  @override
  String toString() {
    return 'VersionCheckResult(requiresUpdate: $requiresUpdate, isRequired: $isRequired, storeUrl: $storeUrl, message: $message)';
  }
}
