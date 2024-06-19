import 'package:aim/states/configs.dart';
import 'package:aim/utils/image.dart';
import 'package:aim/utils/network.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:aim/states/garments.dart';
import 'package:aim/utils/image.dart';

class GarmentWidget extends StatelessWidget {
  const GarmentWidget({super.key});

  _chooseGarments(BuildContext context, GarmentsState garmentsProvider) async {
    List<int>? currentSelected;

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5),
                  child: GarmentTabs(
                      cacheResultCallback: (newSelected) =>
                          currentSelected = newSelected)),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: const Text("取消"),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  TextButton(
                    child: const Text("确认"),
                    onPressed: () async {
                      if (currentSelected != null) {
                        currentSelected!.removeWhere((item) => item == -1);
                        garmentsProvider.setSelectedGID(currentSelected!);
                      }
                      Navigator.of(context).pop();
                    },
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget renderGIDs(
    List<int> gids,
    BuildContext context,
    GarmentsState garmentsProvider,
    ConfigState configProvider,
  ) {
    List<Widget> figures = gids.map((gid) {
      final garment = garmentsProvider.getGarment(gid);
      final url = garment?.url;
      final image = garment?.image;

      //if (image == null) // TODO: Find more elegant method.
      //  Future.delayed(Duration(seconds: 5),
      //      () => requestGarment(configProvider, garmentsProvider, gid));

      return Card(
        semanticContainer: true,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: InkWell(
          onLongPress: () => launchUrl(Uri.parse(url ?? "https://example.com")),
          child: image != null
              ? Image.memory(image, fit: BoxFit.contain)
              : Image(image: Assets.image(context, "loading.png")),
        ),
      );
    }).toList();

    return ListView(
      scrollDirection: Axis.horizontal,
      children: figures,
    );
  }

  @override
  Widget build(BuildContext context) {
    final GarmentsState garmentsProvider =
        Provider.of<GarmentsState>(context, listen: false);

    final selected = context.select<GarmentsState, List<Garment?>>((state) =>
        state.getSelectedGID().map((gid) => state.getGarment(gid)).toList());

    bool isEnabled =
        context.select<GarmentsState, int>((state) => state.size()) > 0;

    wrapper(widget) {
      return Card(
        color: isEnabled
            ? Theme.of(context).colorScheme.secondaryContainer
            : Theme.of(context).disabledColor.withOpacity(
                Theme.of(context).brightness == Brightness.light ? 0 : 0.15),
        semanticContainer: true,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: SizedBox(
          width: double.infinity,
          child: widget,
        ),
      );
    }

    if (selected.isEmpty) {
      return wrapper(
        InkWell(
          onTap: isEnabled
              ? () => _chooseGarments(context, garmentsProvider)
              : null,
          child: Center(
            child: Transform.scale(
              scale: 1.2,
              child: Icon(
                Icons.add,
                color: isEnabled
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).disabledColor.withOpacity(0.3),
              ),
            ),
          ),
        ),
      );
    }

    List<Widget> figures = garmentsProvider
        .getSelectedGID()
        .map((gid) {
          final garment = garmentsProvider.getGarment(gid);
          if (garment == null) return null;

          return Card(
            semanticContainer: true,
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: Column(
              children: [
                Expanded(
                  child: Image.memory(
                    garment.image,
                    fit: BoxFit.contain,
                  ),
                ),
                Text(
                  garment.type,
                  style: Theme.of(context).textTheme.bodyMedium?.apply(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeightDelta: 1,
                      ),
                ),
              ],
            ),
          );
        })
        .where((e) => e != null)
        .cast<Widget>()
        .toList();

    return wrapper(
      InkWell(
        onTap: () => _chooseGarments(context, garmentsProvider),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: figures,
        ),
      ),
    );
  }
}

class GarmentTabs extends StatefulWidget {
  final Function(List<int>) cacheResultCallback;

  const GarmentTabs({super.key, required this.cacheResultCallback});

  @override
  GarmentTabsState createState() => GarmentTabsState();
}

class GarmentTabsState extends State<GarmentTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final GarmentsState garmentsProvider;
  late final List<Garment> garments;
  late final List<String> tabNames;
  late final List<List<Garment>> tabGarments;
  late final List<int> tabActives;

  @override
  void initState() {
    super.initState();
    garmentsProvider = Provider.of<GarmentsState>(context, listen: false);
    garments = garmentsProvider.iterateGarment().toList();
    tabNames = garments.map((garment) => garment.type).toSet().toList();
    tabGarments =
        List<List<Garment>>.generate(tabNames.length, (i) => <Garment>[]);

    tabActives = List<int>.filled(tabNames.length, -1, growable: true);

    for (Garment g in garments) {
      int index = tabNames.indexOf(g.type);
      if (index != -1) {
        tabGarments[index].add(g);
      }
    }

    for (int gid in garmentsProvider.getSelectedGID()) {
      final garment = garmentsProvider.getGarment(gid);
      if (garment != null) {
        int index = tabNames.indexOf(garment.type);
        tabActives[index] = gid;
      }
    }

    _tabController = TabController(length: tabNames.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("选择穿搭组合"),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: tabNames.map((e) => Tab(text: e)).toList(),
        ),
      ),
      body: TabBarView(
        //构建
        controller: _tabController,
        children: Iterable<int>.generate(tabGarments.length).map(
          (gi) {
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.0,
              ),
              itemCount: tabGarments[gi].length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Radio<dynamic>(
                          value: -1,
                          groupValue: tabActives[gi],
                          onChanged: (val) {
                            tabActives[gi] = val;
                            widget.cacheResultCallback(tabActives);
                            setState(() {});
                          }),
                      const Center(child: Text("不更换😊")),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Radio<dynamic>(
                        value: tabGarments[gi][index - 1].gid,
                        groupValue: tabActives[gi],
                        onChanged: (val) {
                          tabActives[gi] = val;
                          widget.cacheResultCallback(tabActives);
                          setState(() {});
                        }),
                    Expanded(
                      child: InkWell(
                        onLongPress: () => launchUrl(
                            Uri.parse(tabGarments[gi][index - 1].url)),
                        child: Image.memory(tabGarments[gi][index - 1].image),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ).toList(),
      ),
    );
  }

  @override
  void dispose() {
    // 释放资源
    _tabController.dispose();
    super.dispose();
  }
}
