import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive_slides/providers.dart';
import 'package:rive_slides/widgets/clicker.dart';
import 'firebase_options.dart';
import 'package:rive_slides/rive_native/lib/rive_native.dart' as rive;
import 'package:rive_slides/rive_native/example/lib/rive_player.dart';

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
        '/': (context) => MainRiveSlides(),
        '/clicker': (context) => Clicker(),
      }
    );
  }
}

class MainRiveSlides extends ConsumerStatefulWidget {
  const MainRiveSlides({super.key});

  @override
  ConsumerState<MainRiveSlides> createState() => _MainRiveSlidesState();
}

class _MainRiveSlidesState extends ConsumerState<MainRiveSlides> {

  List<Color> colors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.orange,
  ];
  

  @override
  Widget build(BuildContext context) {
    final pageController = ref.watch(pageControllerProvider);
    return Scaffold(
      body: PageView.builder(
        controller: pageController,
        itemCount: colors.length,
        itemBuilder:(context, index) {
          return Container(
            color: colors[index],
            child: Center(
              child: RivePlayer(
                asset: "assets/rating.riv",
                stateMachineName: "State Machine 1",
                withStateMachine: (sm) {
                  // Find the number rating and set it to 3
                  var ratingInput = sm.number("rating")!;
                  ratingInput.value = 3;
                },
              ),
            ),
          );
        },),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            pageController.nextPage(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          });
        },
        child: const Icon(Icons.arrow_forward),
        
      ),
    );
  }
}
