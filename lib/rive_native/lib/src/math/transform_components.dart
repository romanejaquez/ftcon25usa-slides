import 'dart:math';
import 'dart:typed_data';

import 'package:rive_native/src/math/vec2d.dart';

class TransformComponents {
  final Float32List _buffer;

  Float32List get values {
    return _buffer;
  }

  double operator [](int index) {
    return _buffer[index];
  }

  void operator []=(int index, double value) {
    _buffer[index] = value;
  }

  TransformComponents()
      : _buffer = Float32List.fromList([1.0, 0.0, 0.0, 1.0, 0.0, 0.0]);

  TransformComponents.clone(TransformComponents copy)
      : _buffer = Float32List.fromList(copy.values);

  double get x {
    return _buffer[0];
  }

  set x(double value) {
    _buffer[0] = value;
  }

  double get y {
    return _buffer[1];
  }

  set y(double value) {
    _buffer[1] = value;
  }

  double get scaleX {
    return _buffer[2];
  }

  set scaleX(double value) {
    _buffer[2] = value;
  }

  double get scaleY {
    return _buffer[3];
  }

  set scaleY(double value) {
    _buffer[3] = value;
  }

  double get rotation {
    return _buffer[4];
  }

  set rotation(double value) {
    _buffer[4] = value;
  }

  double get skew {
    return _buffer[5];
  }

  set skew(double value) {
    _buffer[5] = value;
  }

  Vec2D get translation {
    return Vec2D.fromValues(_buffer[0], _buffer[1]);
  }

  Vec2D get scale {
    return Vec2D.fromValues(_buffer[2], _buffer[3]);
  }

  static void copy(TransformComponents source, TransformComponents other) {
    source._buffer[0] = other._buffer[0];
    source._buffer[1] = other._buffer[1];
    source._buffer[2] = other._buffer[2];
    source._buffer[3] = other._buffer[3];
    source._buffer[4] = other._buffer[4];
    source._buffer[5] = other._buffer[5];
  }

  static TransformComponents identity() {
    TransformComponents tc = TransformComponents();
    tc.x = 0.0;
    tc.y = 0.0;
    tc.scaleX = 1.0;
    tc.scaleY = 1.0;
    tc.skew = 0.0;
    tc.rotation = 0.0;
    return tc;
  }

  @override
  String toString() {
    return 'TransformComponents(x: $x y: $y sx: $scaleX '
        'sy: $scaleY r: ${rotation / pi * 180} s: $skew)';
  }
}
