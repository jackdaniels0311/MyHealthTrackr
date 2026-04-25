import 'package:flutter/material.dart';
import 'package:myhealthtrackr/themes/app_icons.dart';
import 'package:myhealthtrackr/themes/app_colours.dart';

class BarcodeScannerSymbolIcon extends StatelessWidget {
  const BarcodeScannerSymbolIcon({super.key, this.size = 38, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      AppIcons.barcodeScanner,
      size: size,
      color: color ?? AppColours.onDark,
      fill: 0,
      weight: 400,
      grade: 0,
      opticalSize: 40,
    );
  }
}
