import 'package:flutter/cupertino.dart';
import 'package:nudge_me/main.dart';

void main() {
  isProduction = true;

  WidgetsFlutterBinding.ensureInitialized();
  appInit();

  runApp(MyApp());
}
