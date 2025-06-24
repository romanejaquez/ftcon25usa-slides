import 'package:example/enums.dart';
import 'package:example/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class PageSliderController {

  final Ref ref;


  PageSliderController(this.ref);

  void initialize() {
    var fbInstance = ref.read(fbInstanceProvider);
    final pgCtrl = ref.read(pageControllerProvider);

    Future.delayed(const Duration(seconds: 0), () {
      ref.read(slidesVMProvider.notifier).initialize(ref.read(slideRepositoryProvider).getSlides());
      ref.read(currentSlideProvider.notifier).state = ref.read(slidesVMProvider.notifier).getSlideAtIndex(0);
    });

    fbInstance.collection('rive-slides').doc('clicker').snapshots().listen((event) {
      var data = event.data()!;
      final clickerActionAsString = data['action'];
      final clickerAction = ClickerActions.values.where((c) => c.name == clickerActionAsString).first;

      
      switch(clickerAction) {
        case ClickerActions.next:
          pgCtrl.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
        case ClickerActions.previous:
          pgCtrl.previousPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
          break;
        case ClickerActions.none:
          break;
      }
    });

    fbInstance.collection('rive-slides').doc('notes').snapshots().listen((event) {
      var data = event.data()!;
      final slide = ref.read(slidesVMProvider.notifier).getSlideAtIndex(int.parse(data['slideIndex'].toString()));
      ref.read(currentSlideProvider.notifier).state = slide;
    });
  }

  void updatePage(int index) {
    // var fbInstance = ref.read(fbInstanceProvider);
    // fbInstance.collection('rive-slides').doc('notes').update({
    //   'slideIndex': index,
    //   'timestamp': DateTime.now().millisecondsSinceEpoch
    // });
  }

  void moveToPrevious() {
    var fbInstance = ref.read(fbInstanceProvider);
    fbInstance.collection('rive-slides').doc('clicker').update({
      'action': 'previous',
      'timestamp': DateTime.now().millisecondsSinceEpoch
    });
  }

  void moveToNext() {
    var fbInstance = ref.read(fbInstanceProvider);
    fbInstance.collection('rive-slides').doc('clicker').update({
      'action': 'next',
      'timestamp': DateTime.now().millisecondsSinceEpoch
    });
  }
}