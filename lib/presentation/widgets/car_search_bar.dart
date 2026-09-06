import 'dart:async';

import 'package:car_rental_app/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Search input that reports changes after a short pause.
///
/// Filtering is local, but debouncing still matters: without it every
/// keystroke rebuilds the whole list mid-typing.
class CarSearchBar extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const CarSearchBar({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<CarSearchBar> createState() => _CarSearchBarState();
}

class _CarSearchBarState extends State<CarSearchBar> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 250),
      () => widget.onChanged(value),
    );
    setState(() {});
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    widget.onChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search by model',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Clear search',
                onPressed: _clear,
              ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }
}
