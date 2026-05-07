import 'package:flutter/material.dart';
import '../models/car_model.dart';

/// Araç görselini gösterir.
/// image URL boşsa veya yüklenemezse araç ikonu gösterilir.
class CarImage extends StatelessWidget {
  final Car car;
  final BoxFit fit;
  final Widget? errorWidget;

  const CarImage({
    super.key,
    required this.car,
    this.fit = BoxFit.cover,
    this.errorWidget,
  });

  Widget _fallback() {
    return errorWidget ??
        Container(
          color: Colors.grey[200],
          child: const Center(
            child: Icon(Icons.directions_car, size: 50, color: Colors.grey),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    if (car.image.isEmpty) return _fallback();

    return Image.network(
      car.image,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
      errorBuilder: (context, error, stack) => _fallback(),
    );
  }
}
