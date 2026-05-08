import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Generate App Icon', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;

    final widget = Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        width: 1024,
        height: 1024,
        color: Colors.white, // White background
        child: Center(
          child: Icon(
            Icons.local_fire_department_rounded,
            size: 800,
            color: const Color(0xFFFF5722), // AppColors.coral
          ),
        ),
      ),
    );

    await tester.pumpWidget(RepaintBoundary(
      key: const ValueKey('icon'),
      child: widget,
    ));

    final finder = find.byKey(const ValueKey('icon'));
    final element = finder.evaluate().single;
    final boundary = element.renderObject as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    File('assets/app_icon.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(pngBytes);
  });
}
