import 'package:example/providers.dart';
import 'package:example/rive_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive_native/rive_native.dart';

class Clicker extends ConsumerStatefulWidget {
  const Clicker({super.key});

  @override
  ConsumerState<Clicker> createState() => _ClickerState();
}

class _ClickerState extends ConsumerState<Clicker> {

  late StateMachine stateMachine;
  @override
  Widget build(BuildContext context) {

    return Container(
      color: Color(0xFFBA76FC),
      child: RivePlayer(
        asset: "assets/clicker.riv",
        stateMachineName: "clicker",
        withStateMachine: (sm) {
          
          stateMachine = sm;
          stateMachine.addEventListener((e) {
            if (e.name == "next") {
              ref.read(pageSliderControllerProvider).moveToNext();
            }
            else {
              ref.read(pageSliderControllerProvider).moveToPrevious();
            }
          });
        },
      ),
    );
    // return Container(y
    //   child: Row(
    //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //     children: [
    //       IconButton(
    //         onPressed: () {
    //           ref.read(pageSliderControllerProvider).moveToPrevious();
    //         }, 
    //         icon: Icon(Icons.arrow_left),
    //       ),
    //       Text('Clicker'),
    //       IconButton(
    //         onPressed: () {
    //           ref.read(pageSliderControllerProvider).moveToNext();
    //         }, 
    //         icon: Icon(Icons.arrow_right),
    //       ),
    //     ],
    //   )
    // );
  }
}