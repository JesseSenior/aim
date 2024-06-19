import 'package:flutter/material.dart';

import 'package:aim/utils/image.dart';

class TitledWidget extends StatelessWidget {
  const TitledWidget({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.bodyLarge?.apply(
              color: Theme.of(context).colorScheme.primary, fontWeightDelta: 1),
        ),
        child,
      ],
    );
  }
}
