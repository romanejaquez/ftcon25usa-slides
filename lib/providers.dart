import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive_slides/enums.dart';
import 'package:rive_slides/page_slider_controller.dart';

final pageControllerProvider = Provider((ref) => PageController(initialPage: 0));
final fbInstanceProvider = Provider((ref) => FirebaseFirestore.instance);
final pageSliderControllerProvider = Provider((ref) => PageSliderController(ref));
final clickerActionProvider = StateProvider<ClickerActions>((ref) => ClickerActions.none);