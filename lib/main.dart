import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'backend_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (BackendConfig.enabled) {
    await Supabase.initialize(
      url: BackendConfig.url,
      publishableKey: BackendConfig.publishableKey,
    );
  }
  runApp(const HealthConnectApp());
}
