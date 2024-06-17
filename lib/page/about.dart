import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:aim/utils/prefs.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final prefs = Prefs.prefs;

  void _openHomePage() async {
    await launchUrl(Uri.parse("https://github.com/JesseSenior/aim"));
  }

  void _checkUpdates() async {
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
        });
  }

  void _updateServerAddress() async {
    String currentServerAddress = prefs.getString('server_address')!;
    final controller = TextEditingController(text: currentServerAddress);

    int? updateAddress = await showDialog(
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
                  currentServerAddress = controller.text;
                  Navigator.of(context).pop(1);
                },
              ),
            ],
          );
        });
    if (updateAddress != null) {
      await prefs.setString('server_address', currentServerAddress);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    Size size = MediaQuery.of(context).size;

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
            Image.asset(
              "assets/images/banner.png",
              width: size.width * 0.8,
            ),
            Expanded(
              child: ListView(
                shrinkWrap: true,
                children: <Widget>[
                  const Divider(thickness: 2),
                  ListTile(
                    leading: const Icon(Icons.public),
                    title: const Text('项目主页'),
                    onTap: _openHomePage,
                  ),
                  ListTile(
                    leading: const Icon(Icons.update),
                    title: const Text('检查更新'),
                    onTap: _checkUpdates,
                  ),
                  const Divider(thickness: 2),
                  ListTile(
                    leading: Transform.scale(
                      scale: 0.75,
                      child: const FaIcon(FontAwesomeIcons.server),
                    ),
                    title: const Text('服务器地址'),
                    subtitle: Text(prefs.getString('server_address')!),
                    onTap: _updateServerAddress,
                  ),
                  const ListTile(
                    leading: Icon(Icons.cached),
                    title: Text('清除缓存'), // TODO: Add method to clean cache
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
