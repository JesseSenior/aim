import 'package:aim/states/configs.dart';
import 'package:aim/states/garments.dart';
import 'package:aim/utils/network.dart';
import 'package:aim/widgets/garment_widget.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import 'package:aim/states/chat.dart';

class ChatWidget extends StatelessWidget {
  const ChatWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🤖  AI 酱"),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatState>(
              builder: (context, chatState, child) {
                return GestureDetector(
                  onTap: () {
                    FocusScope.of(context)
                        .unfocus(); // <-- Hide virtual keyboard
                  },
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: chatState.size(),
                      itemBuilder: (context, index) {
                        final message =
                            chatState.iterateMessage().elementAt(index);
                        return MessageThread(
                          sender: message.sender,
                          type: message.type,
                          content: message.content,
                        );
                        ListTile(
                          leading: Icon(message.sender == 0
                              ? Icons.person
                              : Icons.computer),
                          title: Text(message.content),
                          subtitle: Text(message.type == 0
                              ? "Common message"
                              : "Recommendation message"),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                    ),
                  ),
                );
              },
            ),
          ),
          _BottomInputField(), // <- Fixed bottom TextField widget
        ],
      ),
    );
  }
}

class MessageThread extends StatelessWidget {
  const MessageThread({
    super.key,
    required this.sender,
    required this.type,
    required this.content,
  });

  final int sender;
  final int type;
  final String content;

  _getMessageContent(
    BuildContext context,
    bool isMe,
    int type,
    String text,
  ) {
    ConfigState configProvider =
        Provider.of<ConfigState>(context, listen: false);
    GarmentsState garmentsProvider =
        Provider.of<GarmentsState>(context, listen: false);
    ChatState chatProvider = Provider.of<ChatState>(context, listen: false);
    switch (type) {
      case 0:
        return Text(
          content,
          style: TextStyle(
              color: isMe
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.tertiary),
        );
      case 1:
        assert(!isMe);
        List<int> gids = content.split('_').map((s) => int.parse(s)).toList();

        return Column(
          children: [
            Text(
              "好的，以下是我向你推荐的穿搭组合：",
              style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
            ),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return Container(
                  height: 75,
                  width: constraints.maxWidth,
                  child: GarmentWidget.renderGIDs(
                      gids, context, garmentsProvider, configProvider),
                );
              },
            ),
            OutlinedButton(
              child: const Text("试一下！"),
              onPressed: () {
                garmentsProvider.setSelectedGID(gids);
                Navigator.pop(context);
              },
            )
          ],
        );
      case 2:
        assert(!isMe);
        return Column(
          children: [
            Text(
              "似乎出了一些小问题",
              style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
            ),
            OutlinedButton(
              child: const Text("重试"),
              onPressed: () {
                requestChat(configProvider, chatProvider, garmentsProvider,
                    resend: true);
              },
            )
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMe = sender == 0;
    Size size = MediaQuery.of(context).size;
    return Padding(
      padding: isMe
          ? const EdgeInsets.only(right: 5, top: 10, bottom: 10)
          : const EdgeInsets.only(left: 5, top: 10, bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment:
                  isMe ? MainAxisAlignment.end : MainAxisAlignment.center,
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    Widget container = Container(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth * 0.55,
                      ),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.tertiaryContainer,
                        borderRadius: isMe
                            ? const BorderRadius.only(
                                topLeft: Radius.circular(15),
                                topRight: Radius.circular(15),
                                bottomLeft: Radius.circular(15),
                              )
                            : const BorderRadius.only(
                                topLeft: Radius.circular(15),
                                topRight: Radius.circular(15),
                                bottomRight: Radius.circular(15),
                              ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _getMessageContent(context, isMe, type, content),
                      ),
                    );

                    Widget icon = MaterialButton(
                      onPressed: () {},
                      color: isMe
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.tertiaryContainer,
                      textColor: isMe
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.tertiary,
                      padding: const EdgeInsets.all(8),
                      shape: const CircleBorder(),
                      child: sender == 0
                          ? const Icon(Icons.person)
                          : Transform.scale(
                              scale: 0.75,
                              child: const FaIcon(FontAwesomeIcons.robot),
                            ),
                    );

                    icon = Transform.scale(
                      scale: 1.2,
                      child: icon,
                    );

                    return Row(
                      mainAxisAlignment: sender == 0
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children:
                          sender == 0 ? [container, icon] : [icon, container],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomInputField extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    ConfigState configProvider =
        Provider.of<ConfigState>(context, listen: false);
    GarmentsState garmentsProvider =
        Provider.of<GarmentsState>(context, listen: false);
    ChatState chatProvider = Provider.of<ChatState>(context, listen: false);

    Widget quickBar = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        ElevatedButton.icon(
          onPressed: () async {
            await chatProvider.appendMessage(
                const Message(sender: 0, type: 0, content: "向我进行穿搭推荐"));
            requestChat(configProvider, chatProvider, garmentsProvider);
          },
          icon: const Icon(Icons.shopping_bag),
          label: const Text("穿搭推荐"),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            await chatProvider.appendMessage(
                const Message(sender: 0, type: 0, content: "怎样才能穿得更加优雅自信一些呢"));
            requestChat(configProvider, chatProvider, garmentsProvider);
          },
          icon: const Icon(Icons.rocket_launch),
          label: const Text("一键提问"),
        ),
      ],
    );
    Widget inputBar = Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: '你希望怎样改造你自己',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.secondaryContainer,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.send),
          iconSize: 25.0,
          color: Theme.of(context).colorScheme.secondary,
          onPressed: () async {
            if (_controller.text.isNotEmpty) {
              await chatProvider.appendMessage(
                  Message(sender: 0, type: 0, content: _controller.text));
              requestChat(configProvider, chatProvider, garmentsProvider);
            }
            _controller.clear();
          },
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      height: 120.0,
      child: Column(
        children: [quickBar, inputBar],
      ),
    );
  }
}
