import 'dart:typed_data';

import 'package:aim/states/garments.dart';
import 'package:aim/states/tryon.dart';
import 'package:aim/utils/network.dart';
import 'package:aim/widgets/tryon_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:aim/states/configs.dart';
import 'package:aim/utils/image.dart';
import 'package:aim/widgets/titled_widget.dart';
import 'package:aim/widgets/garment_widget.dart';
import 'package:aim/widgets/chat_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _getSelfie(ConfigState configProvider,
      TryOnResultsState tryOnResultsProvider) async {
    var data = await getImageFromUser(context);
    if (data == null) return;
    configProvider.prevTryOnImage = data;
    tryOnResultsProvider.clean();
  }

  Widget _getStartPage(
      ConfigState configProvider, TryOnResultsState tryOnResultsProvider) {
    final Size size = MediaQuery.of(context).size;

    var body = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Image(
            image: Assets.image(context, "logo.png"),
            width: size.width * 0.5,
          ),
          SizedBox(height: size.height * 0.05),
          Image(
            image: Assets.image(context, "title-secondary.png",
                isDarkModeAware: true),
            width: size.width * 0.7,
          ),
          SizedBox(height: size.height * 0.1),
          Transform.scale(
            scale: 1.25,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.image),
              label: const Text("选择自拍照"),
              onPressed: () => _getSelfie(configProvider, tryOnResultsProvider),
            ),
          ),
          SizedBox(height: size.height * 0.1),
        ],
      ),
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.inversePrimary,
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: body,
      ),
    );
  }

  Widget _getMainPage(
    ConfigState configProvider,
    GarmentsState garmentsProvider,
    TryOnResultsState tryOnResultsProvider,
  ) {
    Size size = MediaQuery.of(context).size;

    final imageLevel = Row(
      children: <Widget>[
        Expanded(
          child: TitledWidget(
            title: "  😕 改造前",
            child: Expanded(
              child: Card(
                color: Colors.grey,
                clipBehavior: Clip.antiAliasWithSaveLayer,
                semanticContainer: true,
                child: Ink.image(
                  image: Image.memory(context.select<ConfigState, Uint8List?>(
                          (config) => config.prevTryOnImage)!)
                      .image,
                  fit: BoxFit.contain,
                  child: InkWell(
                    onTap: () =>
                        _getSelfie(configProvider, tryOnResultsProvider),
                  ),
                ),
              ),
            ),
          ),
        ),
        const Expanded(
          child: TitledWidget(
            title: "  🥰 改造后",
            child: Expanded(
              child: Card(
                color: Colors.grey,
                semanticContainer: true,
                clipBehavior: Clip.antiAliasWithSaveLayer,
                child: TryonWidget(),
              ),
            ),
          ),
        ),
      ],
    );

    var garmentLevel = const TitledWidget(
      title: "  👕 穿搭组合：",
      child: Expanded(child: GarmentWidget()),
    );

    final buttonLevel = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Transform.scale(
          scale: 1.2,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.chat),
            label: const Text("与AI对话"),
            onPressed: () {
              showModalBottomSheet<int>(
                isScrollControlled: true,
                context: context,
                clipBehavior: Clip.antiAliasWithSaveLayer,
                builder: (BuildContext context) {
                  return const FractionallySizedBox(
                    heightFactor: 0.8,
                    child: ChatWidget(),
                  );
                },
              );
            },
          ),
        ),
        Transform.scale(
          scale: 1.2,
          child: ElevatedButton.icon(
            icon: Transform.scale(
              scale: 0.75,
              child: const FaIcon(FontAwesomeIcons.shirt),
            ),
            label: const Text("穿搭改造"),
            onPressed: context.select<GarmentsState, int>(
                        (config) => config.getSelectedGID().length) ==
                    0
                ? null
                : () => requestTryOn(
                      garmentsProvider,
                      configProvider,
                      tryOnResultsProvider,
                    ),
          ),
        ),
      ],
    );

    var body = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(height: size.height * 0.01),
          Expanded(
            flex: 4,
            child: imageLevel,
          ),
          SizedBox(height: size.height * 0.01),
          Expanded(
            flex: 3,
            child: garmentLevel,
          ),
          SizedBox(height: size.height * 0.01),
          Expanded(
            flex: 2,
            child: buttonLevel,
          )
        ],
      ),
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Image(
          image:
              Assets.image(context, "title-primary.png", isDarkModeAware: true),
          height: AppBar().preferredSize.height * 0.35,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.secondaryContainer,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: body,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    final GarmentsState garmentsProvider =
        Provider.of<GarmentsState>(context, listen: false);
    final ConfigState configProvider =
        Provider.of<ConfigState>(context, listen: false);
    final TryOnResultsState tryOnResultsProvider =
        Provider.of<TryOnResultsState>(context, listen: false);

    return context.select<ConfigState, bool>(
            (config) => config.prevTryOnImage == null)
        ? _getStartPage(configProvider, tryOnResultsProvider)
        : _getMainPage(configProvider, garmentsProvider, tryOnResultsProvider);
  }
}
