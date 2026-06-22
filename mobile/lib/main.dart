import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/native/native_features_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NativeFeaturesStore.instance.initialize();
  runApp(const HarmoCrewApp());
}
