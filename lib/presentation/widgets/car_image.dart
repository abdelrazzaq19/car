import 'package:cached_network_image/cached_network_image.dart';
import 'package:car_rental_app/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Renders a car photo from the network when the document has one, and falls
/// back to the bundled asset otherwise. A broken URL shows the fallback rather
/// than a red error box.
class CarImage extends StatelessWidget {
  final String? imageUrl;
  final double? height;
  final BoxFit fit;

  const CarImage({
    super.key,
    required this.imageUrl,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;

    if (url == null) return _fallback();

    return CachedNetworkImage(
      imageUrl: url,
      height: height,
      fit: fit,
      placeholder: (context, _) => _Placeholder(height: height),
      errorWidget: (context, _, __) => _fallback(),
    );
  }

  Widget _fallback() => Image.asset(
        'assets/car_image.png',
        height: height,
        fit: fit,
      );
}

class _Placeholder extends StatelessWidget {
  final double? height;

  const _Placeholder({this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.mdAll,
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
