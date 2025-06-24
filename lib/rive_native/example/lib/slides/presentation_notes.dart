import 'package:example/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PresentationNotes extends ConsumerWidget {
  const PresentationNotes({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final currentSlide = ref.watch(currentSlideProvider);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(currentSlide.content, style: TextStyle(color: Colors.black, fontSize: 24)),
        ),
      ),
    );
  }
}