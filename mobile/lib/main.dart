import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/native/native_features_store.dart';

Future<void> main() async {
  /*
   * Como Hive e notificacoes usam plugins nativos, precisamos garantir que o
   * Flutter inicializou os bindings antes de abrir boxes ou canais Android.
   */
  WidgetsFlutterBinding.ensureInitialized();
  await NativeFeaturesStore.instance.initialize();
  runApp(const HarmoCrewApp());
}
