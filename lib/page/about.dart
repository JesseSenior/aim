import 'package:aim/states/chat.dart';
import 'package:aim/states/tryon.dart';
import 'package:aim/utils/network.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:aim/states/base.dart';
import 'package:aim/states/configs.dart';
import 'package:aim/states/garments.dart';
import 'package:aim/utils/image.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  void _openHomePage() async {
    await launchUrl(Uri.parse("https://github.com/JesseSenior/aim"));
  }

  void _checkUpdates(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("非常抱歉"),
          content: const Text("该功能没有实现捏QwQ"),
          actions: <Widget>[
            TextButton(
              child: const Text("好吧"),
              onPressed: () => Navigator.of(context).pop(), // 关闭对话框
            ),
          ],
        );
      },
    );
  }

  void _updateServerAddress(
      BuildContext context, ConfigState configProvider) async {
    String currentServerAddress = configProvider.serverAddress;
    final controller = TextEditingController(text: currentServerAddress);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("修改服务器地址"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: "服务器地址",
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("取消"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("确认"),
              onPressed: () async {
                configProvider.serverAddress = controller.text;
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
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
    final Size size = MediaQuery.of(context).size;
    final ConfigState configProvider =
        Provider.of<ConfigState>(context, listen: false);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.inversePrimary,
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Column(
          children: <Widget>[
            SizedBox(height: size.height * 0.1),
            Image(
              image: Assets.image(context, "banner.png"),
              width: size.width * 0.8,
            ),
            Expanded(
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: <Widget>[
                  const Divider(thickness: 2),
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: const Icon(Icons.public),
                      title: const Text('项目主页'),
                      onTap: _openHomePage,
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: const Icon(Icons.update),
                      title: const Text('检查更新'),
                      onTap: () => _checkUpdates(context),
                    ),
                  ),
                  const Divider(thickness: 2),
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: Transform.scale(
                        scale: 0.75,
                        child: const FaIcon(FontAwesomeIcons.server),
                      ),
                      title: const Text('服务器地址'),
                      subtitle: Selector<ConfigState, String>(
                          selector: (_, config) => config.serverAddress,
                          builder: (_, serverAddress, __) =>
                              Text(serverAddress)),
                      onTap: () =>
                          _updateServerAddress(context, configProvider),
                    ),
                  ),
                  const Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: Icon(Icons.cached),
                      title: Text('清除数据'),
                      onTap: SPUtils.clearCache,
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: const Icon(Icons.bug_report),
                      title: const Text('调试'),
                      onTap: () => _debugData(context),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  _debugData(BuildContext context) async {
    int? ret = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("这只是个调试按钮"),
          content: const Text("这只是个调试按钮"),
          actions: <Widget>[
            TextButton(
              child: const Text("好的"),
              onPressed: () => Navigator.of(context).pop(), // 关闭对话框
            ),
            TextButton(
              child: const Text("什么？摸一下"),
              onPressed: () => Navigator.of(context).pop(1), // 关闭对话框
            ),
          ],
        );
      },
    );
    if (ret == null) return;
    final ConfigState configProvider =
        Provider.of<ConfigState>(context, listen: false);
    final ChatState chatProvider =
        Provider.of<ChatState>(context, listen: false);
    final GarmentsState garmentsProvider =
        Provider.of<GarmentsState>(context, listen: false);
    final TryOnResultsState tryOnResultsProvider =
        Provider.of<TryOnResultsState>(context, listen: false);

    SPUtils.clearCache();

    readImage(String path) async =>
        (await rootBundle.load(path)).buffer.asUint8List();

    configProvider.prevTryOnImage =
        await readImage("assets/test/example_image.jpg");

    await garmentsProvider.appendGarment(Garment(
      gid: 12,
      image: await readImage("assets/test/1_1.jpg"),
      url: "https://example.com",
      type: "上衣",
    ));
    await garmentsProvider.appendGarment(Garment(
      gid: 13,
      image: await readImage("assets/test/1_2.jpg"),
      url: "https://example.com",
      type: "上衣",
    ));
    await garmentsProvider.appendGarment(Garment(
      gid: 22,
      image: await readImage("assets/test/2_2.jpg"),
      url: "https://example.com",
      type: "下衣",
    ));
    await garmentsProvider.appendGarment(Garment(
      gid: 21,
      image: await readImage("assets/test/2_1.jpg"),
      url: "https://example.com",
      type: "下衣",
    ));
    await garmentsProvider.appendGarment(Garment(
      gid: 32,
      image: await readImage("assets/test/3_2.jpg"),
      url: "https://example.com",
      type: "外套",
    ));
    await garmentsProvider.appendGarment(Garment(
      gid: 43,
      image: await readImage("assets/test/3_1.jpg"),
      url: "https://example.com",
      type: "外套",
    ));
    await garmentsProvider.setSelectedGID([12, 22, 32]);

    await chatProvider
        .appendMessage(const Message(sender: 0, type: 0, content: "测试消息"));
    await chatProvider
        .appendMessage(const Message(sender: 1, type: 0, content: "测试消息（AI）"));
    await chatProvider.appendMessage(const Message(
        sender: 1,
        type: 0,
        content:
            "测试消息（AI）测试消息（AI）测试消息（AI）测试消息（AI）测试消息（AI）测试消息（AI）测试消息（AI）测试消息（AI）测试消息（AI）测试消息（AI）"));
    await chatProvider
        .appendMessage(const Message(sender: 1, type: 1, content: "21_13_43"));
    await chatProvider
        .appendMessage(const Message(sender: 1, type: 2, content: "故障模拟"));

    tryOnResultsProvider.appendResult(TryOnResult(
        gids: "12_22_32",
        image: await readImage("assets/test/example_image.jpg")));
    tryOnResultsProvider.appendResult(TryOnResult(
        gids: "22_13_32",
        image: await readImage("assets/test/example_garment.jpg")));
    tryOnResultsProvider.appendResult(TryOnResult(
        gids: "12_32",
        image: await readImage("assets/test/example_image.jpg")));
  }
}
