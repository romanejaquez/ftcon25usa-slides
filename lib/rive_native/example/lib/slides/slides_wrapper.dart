
import 'dart:math';

import 'package:example/providers.dart';
import 'package:example/rive_player.dart';
import 'package:example/slides/rive_slide.dart';
import 'package:example/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive_native/rive_native.dart';
import 'package:rive_native/rive_native.dart' as rive;


class SlidesWrapper extends ConsumerStatefulWidget {
  const SlidesWrapper({super.key});

  @override
  ConsumerState<SlidesWrapper> createState() => _MainRiveSlidesState();
}

class _MainRiveSlidesState extends ConsumerState<SlidesWrapper> {

  late PageController pageController;
  @override  
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      pageController = ref.read(pageControllerProvider);
      ServicesBinding.instance.keyboard.addHandler((KeyEvent ev) {
        if (ev is KeyDownEvent) {
          if (ev.logicalKey == LogicalKeyboardKey.arrowRight) {
            pageController.nextPage(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
          if (ev.logicalKey == LogicalKeyboardKey.arrowLeft) {
            pageController.previousPage(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        }

        return false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    
    final slides = ref.watch(slidesVMProvider);
    final loadedAssets = ref.watch(loadAssetsProvider);

    return Scaffold(
      body: Stack(
        children: [
          
          loadedAssets.when(
            data: (data) {

              return PageView.builder(
                controller: pageController,
                itemCount: slides.length,
                onPageChanged: (value) {
                  ref.read(pageSliderControllerProvider).updatePage(value);
                },
                itemBuilder:(context, index) {
              
                  final slide = slides[index];
                  return RiveSlide(
                    slideModel: slide,
                  );
                },
              );
            },
            error: (e, s) => Center(child: Text(e.toString())),
            loading: () => CircularProgressIndicator()),
          Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    pageController.previousPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: Icon(Icons.arrow_back),
                  label: Text(''),
                ),
    
                TextButton.icon(
                  onPressed: () {
                    pageController.nextPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: Icon(Icons.arrow_forward),
                  label: Text(''),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

