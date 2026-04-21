import 'package:flutter/material.dart';

class CustomLocationPin extends StatelessWidget {
  final double size;
  final Color color;

  const CustomLocationPin({super.key, this.size = 40, this.color = Colors.red});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/car_marker.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.navigation, color: Colors.blue, size: size);
      },
    );
  }
}
