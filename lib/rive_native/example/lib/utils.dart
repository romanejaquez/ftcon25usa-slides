import 'package:flutter/services.dart';
import 'package:rive_native/rive_native.dart' as rive;

class Utils {

  static rive.File? riveFile;
  static rive.File? duuprTransportFile;

  static Future<void> loadFile() async {
    final bytes = await rootBundle.load("assets/rive_slides.riv");
    riveFile = await rive.File.decode(
      bytes.buffer.asUint8List(),
      riveFactory: rive.Factory.rive,
    );

    final dtbytes = await rootBundle.load("assets/duuprtransport.riv");
    duuprTransportFile = await rive.File.decode(
      dtbytes.buffer.asUint8List(),
      riveFactory: rive.Factory.rive,
    );
  }
}