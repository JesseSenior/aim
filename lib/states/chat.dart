import 'dart:async';
import 'dart:typed_data';

import 'package:aim/states/base.dart';

class Message {
  final int sender; // 0: User, 1: GPT
  final int type; // 0: Common message, 1: Recommendation message
  final String content; // 1: 下划线分割gid

  const Message(
      {required this.sender, required this.type, required this.content});
}

class ChatState extends BaseState {
  static Future<void> init() async {
    SPUtils.defaultDict["temp_message_amount"] = 0;
  }

  int size() => getCache("temp_message_amount", getInt);

  Iterable<Message> iterateMessage() sync* {
    final sz = size();
    for (int id = 0; id < sz; id++) {
      final sender = getCache("temp_message_sender_$id", getInt);
      final type = getCache("temp_message_type_$id", getInt);
      final content = getCache("temp_message_content_$id", getString);
      yield Message(sender: sender, type: type, content: content);
    }
  }

  appendMessage(Message message, {bool overwriteLast = false}) async {
    final id = overwriteLast ? size() - 1 : size();
    await setCache("temp_message_amount", id + 1, setInt);
    await setCache('temp_message_sender_$id', message.sender, setInt);
    await setCache('temp_message_type_$id', message.type, setInt);
    await setCache('temp_message_content_$id', message.content, setString);
    notifyListeners();
  }
}
