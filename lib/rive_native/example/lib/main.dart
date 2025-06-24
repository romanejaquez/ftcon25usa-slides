import 'package:example/firebase_options.dart';
import 'package:example/providers.dart';
import 'package:example/rive_player.dart';
import 'package:example/slides/presentation_notes.dart';
import 'package:example/slides/slides_wrapper.dart';
import 'package:example/utils.dart';
import 'package:example/widgets/clicker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive_native/rive_native.dart' as rive;

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await rive.RiveNative.init();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      builder: (context, child) {
        
        ref.read(pageSliderControllerProvider).initialize();
        return child!;
      },
      initialRoute: '/',
      routes: {
        '/': (context) => SlidesWrapper(),
        '/clicker': (context) => Clicker(),
        '/notes': (context) => PresentationNotes(),
      }
    );
  }
}
