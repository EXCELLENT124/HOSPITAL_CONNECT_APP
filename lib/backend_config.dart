class BackendConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const passwordResetRedirectUrl = 'healthconnectapp://reset-password';

  static bool get enabled => url.isNotEmpty && publishableKey.isNotEmpty;
}
