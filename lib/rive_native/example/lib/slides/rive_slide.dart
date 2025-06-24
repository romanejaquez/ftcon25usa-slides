import 'package:example/data/models/slide_model.dart';
import 'package:example/rive_player.dart';
import 'package:flutter/material.dart';
import 'package:rive_native/rive_native.dart' as rive;

class RiveSlide extends StatefulWidget {

  final SlideModel slideModel;
  const RiveSlide({super.key, required this.slideModel, });

  @override
  State<RiveSlide> createState() => _RiveSlideState();
}

class _RiveSlideState extends State<RiveSlide> with AutomaticKeepAliveClientMixin {

  late rive.StateMachine sm;
  late rive.Artboard ab;

  @override  
  void dispose() {
    sm.dispose();
    ab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: widget.slideModel.color,
      child: Center(
        child: RivePlayer(
          asset: "assets/${widget.slideModel.asset}.riv",
          stateMachineName: widget.slideModel.stateMachineName,
          artboardName: widget.slideModel.artboardName,
          autoBind: true,
          fit: rive.Fit.fitWidth,
          withArtboard: (artboard) {
            ab = artboard;
          },
          withStateMachine: (stateMachine) {
            sm = stateMachine;
          }
        ),
        // child: rive.RiveFileWidget(
        //   file: widget.slideModel.asset == 'duuprtransport' ? Utils.duuprTransportFile! : Utils.riveFile!,
        //   artboardName: widget.slideModel.artboardName,
        //   painter: rive.StateMachinePainter(
        //     stateMachineName: widget.slideModel.stateMachineName,
        //     fit: rive.Fit.fitWidth,
        //     withStateMachine: (p0) {
              
        //     },
        //   ),
        //   //stateMachineName: slide.stateMachineName,
        //   //fit: Fit.fitWidth,
        // )
      ),
    );
  }
  
  @override
  bool get wantKeepAlive => false;
}