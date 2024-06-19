import 'dart:typed_data';

import 'package:aim/states/garments.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aim/states/tryon.dart';

class TryonWidget extends StatefulWidget {
  const TryonWidget({super.key});

  @override
  State<TryonWidget> createState() => _TryonWidgetState();
}

class _TryonWidgetState extends State<TryonWidget> {
  @override
  Widget build(BuildContext context) {
    TryOnResultsState tryONResultsProvider =
        Provider.of<TryOnResultsState>(context);
    GarmentsState garmentsProvider =
        Provider.of<GarmentsState>(context, listen: false);

    if (tryONResultsProvider.size() == 0) {
      return const InkWell(onTap: null, child: null);
    }

    return Swiper(
      index: tryONResultsProvider.activeID,
      loop: false,
      itemCount: tryONResultsProvider.size(),
      pagination: SwiperPagination(),
      onIndexChanged: (index) {
        List<int> gids = tryONResultsProvider
            .getResult(index)
            .gids
            .split('_')
            .map((s) => int.parse(s))
            .toList();
        garmentsProvider.setSelectedGID(gids);
      },
      itemBuilder: (_, index) => Selector<TryOnResultsState, Uint8List>(
        selector: (_, state) => state.getResult(index).image,
        builder: (_, data, __) => Image.memory(data, fit: BoxFit.contain),
      ),
    );
  }
}
