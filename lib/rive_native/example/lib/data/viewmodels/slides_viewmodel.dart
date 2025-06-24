import 'package:example/data/models/slide_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SlidesViewmodel extends StateNotifier<List<SlideModel>>{

  final Ref ref;
  SlidesViewmodel(super.state, this.ref);

  void initialize(List<SlideModel> slides) {
    state = slides;
  }

  SlideModel getSlideAtIndex(int index){
    return state[index];
  }
}