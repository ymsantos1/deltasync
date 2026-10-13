import 'package:flutter/material.dart';

import 'demo_page.dart';

export 'demo_page.dart' show MobileConsumerApp;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MobileConsumerApp());
}
