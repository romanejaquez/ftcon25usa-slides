import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive_slides/enums.dart';
import 'package:rive_slides/providers.dart';

class PageSliderController {

  final Ref ref;


  PageSliderController(this.ref);

  void initialize() {
    var fbInstance = ref.read(fbInstanceProvider);

    fbInstance.collection('rive-slides').doc('clicker').snapshots().listen((event) {
      var data = event.data()!;
      final clickerActionAsString = data['action'];
      final clickerAction = ClickerActions.values.where((c) => c.name == clickerActionAsString).first;

      final pgCtrl = ref.read(pageControllerProvider);
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