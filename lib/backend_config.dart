class BackendConfig {
  static const _defaultUrl = 'https://kvafuduzyxtboxzpprdc.supabase.co';
  static const _defaultPublishableKey =
      'sb_publishable_SfpY9OqhYiKOcZ1-uVPLVA_4YzWw453';

  static const _definedUrl = String.fromEnvironment('SUPABASE_URL');
  static const _definedPublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static const url = _definedUrl == '' ? _defaultUrl : _definedUrl;
  static const publishableKey = _definedPublishableKey == ''
      ? _defaultPublishableKey
      : _definedPublishableKey;
  static const passwordResetRedirectUrl = 'healthconnectapp://reset-password';

  static bool get enabled => url.isNotEmpty && publishableKey.isNotEmpty;
}
