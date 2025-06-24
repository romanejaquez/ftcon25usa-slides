import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:example/data/repositories/slides_data_repository.dart';
import 'package:example/data/viewmodels/slides_viewmodel.dart';
import 'package:example/enums.dart';
import 'package:example/data/models/slide_model.dart';
import 'package:example/page_slider_controller.dart';
import 'package:example/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pageControllerProvider = Provider((ref) => PageController(initialPage: 0, keepPage: false));
final fbInstanceProvider = Provider((ref) => FirebaseFirestore.instance);
final pageSliderControllerProvider = Provider((ref) => PageSliderController(ref));
final clickerActionProvider = StateProvider<ClickerActions>((ref) => ClickerActions.none);

final currentSlideProvider = StateProvider<SlideModel>((ref) => SlideModel.empty());

final slideRepositoryProvider = Provider((ref) => SlidesDataRepository());
final slidesVMProvider = StateNotifierProvider<SlidesViewmodel, List<SlideModel>>((ref) {
  return SlidesViewmodel([], ref);
});

final loadAssetsProvider = FutureProvider<bool>((ref) async {
  await Utils.loadFile();
  return true;
});