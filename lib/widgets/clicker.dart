import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive_slides/providers.dart';

class Clicker extends ConsumerStatefulWidget {
  const Clicker({super.key});

  @override
  ConsumerState<Clicker> createState() => _ClickerState();
}

class _ClickerState extends ConsumerState<Clicker> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              ref.read(pageSliderControllerProvider).moveToPrevious();
            }, 
            icon: Icon(Icons.arrow_left),
          ),
          Text('Clicker'),
          IconButton(
            onPressed: () {
              ref.read(pageSliderControllerProvider).moveToNext();
            }, 
            icon: Icon(Icons.arrow_right),
          ),
        ],
      )
    );
  }
}