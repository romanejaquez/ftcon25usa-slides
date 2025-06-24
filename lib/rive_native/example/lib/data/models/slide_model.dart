import 'package:flutter/material.dart';

class SlideModel {
  final String content;
  final String asset;
  final String artboardName;
  final String stateMachineName;
  final Color color;

  const SlideModel({ 
    required this.artboardName,
    required this.asset,
    required this.stateMachineName,
    required this.color,
    required this.content,
  });

  static SlideModel empty() {
    return SlideModel(
      artboardName: '',
      asset: '',
      stateMachineName: '',
      color: Colors.white,
      content: '');
  }
}