import 'dart:convert';

import 'package:aim/states/base.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';

import 'package:aim/states/chat.dart';
import 'package:aim/states/tryon.dart';
import 'package:aim/states/configs.dart';
import 'package:aim/states/garments.dart';

Future<void> requestTryOn(
  GarmentsState garmentsProvider,
  ConfigState configProvider,
  TryOnResultsState tryOnResultsProvider,
) async {
  final logger = SPUtils.logger;
  logger.i("[TryOn] Start request tryon");

  final image = base64Encode(configProvider.prevTryOnImage!);
  final gids = garmentsProvider.getSelectedGID();

  final url = 'http://${configProvider.serverAddress}/preview';
  final headers = {"Content-Type": "application/json"};
  final body = jsonEncode({
    "person_image": image,
    "gids": gids,
  });

  Dio dio = Dio();
  dio.interceptors.add(RetryInterceptor(
    dio: dio,
    logPrint: (str) => Fluttertoast.showToast(
      msg: "[TryOn]错误: API调用失败: $str",
    ), // specify log function (optional)
    retries: 10, // retry count (optional)
  ));

  logger.d("[TryOn] Request header $headers | body $body");
  try {
    final response = await dio.post(
      url,
      data: body,
      options: Options(
        headers: headers,
        followRedirects: false,
        validateStatus: (status) {
          return status! < 500;
        },
      ),
    );
    logger.d("[TryOn] Response $response");

    if (response.statusCode == 200) {
      final responseJson = response.data;
      String tryonImageBase64 = responseJson['tryon_image'];

      tryOnResultsProvider.appendResult(TryOnResult(
          gids: gids.join("_"), image: base64Decode(tryonImageBase64)));
    } else {
      Fluttertoast.showToast(
        msg: "[TryOn]错误: API调用失败[${response.statusCode}]",
      );
    }
  } catch (e) {
    logger.e("[TryOn] Error $e");
    Fluttertoast.showToast(
      msg: "[TryOn]错误: API调用失败[Err:${e.toString()}]",
    );
  }
  logger.i("[TryOn] Request end");
}

Future<void> requestGarment(
  ConfigState configProvider,
  GarmentsState garmentsProvider,
  int gid,
) async {
  final logger = SPUtils.logger;
  logger.i("[Garment-$gid] Start requesting garment information");

  final url = 'http://${configProvider.serverAddress}/garment';
  final headers = {
    "Content-Type": "application/json",
    'Connection': 'Keep-Alive',
  };
  final body = jsonEncode({
    "gid": gid,
  });

  Dio dio = Dio();
  dio.interceptors.add(RetryInterceptor(
    dio: dio,
    logPrint: (str) => Fluttertoast.showToast(
      msg: "[Garment-$gid]错误: API调用失败: $str",
    ), // specify log function (optional)
    retries: 10, // retry count (optional)
  ));

  logger.d("[Garment-$gid] Sending request $body");
  try {
    final response = await dio.post(
      url,
      data: body,
      options: Options(
        headers: headers,
        followRedirects: false,
        validateStatus: (status) {
          return status! < 500;
        },
      ),
    );

    logger.d("[Garment-$gid] Response $response");

    if (response.statusCode == 200) {
      final responseJson = response.data;
      String garmentImageBase64 = responseJson['image'];
      String type = responseJson['type'];
      String url = responseJson['url'];

      garmentsProvider.appendGarment(Garment(
          gid: gid,
          image: base64Decode(garmentImageBase64),
          type: type,
          url: url));
    } else {
      Fluttertoast.showToast(
        msg: "[Garment-$gid]错误: API调用失败[${response.statusCode}]",
      );
    }
  } catch (e) {
    logger.e("[Garment-$gid] Error $e");
    Fluttertoast.showToast(
      msg: "[Garment-$gid]错误: API调用失败[Err:${e.toString()}]",
    );
  }
  logger.i("[Garment-$gid] Request end");
}

Future<void> requestChat(
  ConfigState configProvider,
  ChatState chatProvider,
  GarmentsState garmentsProvider, {
  bool resend = false,
}) async {
  final logger = SPUtils.logger;
  logger.i("[Chat] Start requesting chat information");

  var messages = chatProvider
      .iterateMessage()
      .map((message) => {
            "role": message.sender == 0 ? "user" : "assistant",
            "content": message.content,
          })
      .toList();
  // Use last 10 message.
  messages =
      messages.length >= 10 ? messages.sublist(messages.length - 10) : messages;

  bool setImageText = false;
  String? body;
  Message? resultMessage;
  if (configProvider.prevTryOnImageText != null) {
    body = jsonEncode({
      "person_image_text": configProvider.prevTryOnImageText,
      "message": messages,
    });
  } else {
    final image = base64Encode(configProvider.prevTryOnImage!);
    body = jsonEncode({
      "person_image": image,
      "message": messages,
    });
    setImageText = true;
  }

  final url = 'http://${configProvider.serverAddress}/chat';
  final headers = {"Content-Type": "application/json"};

  Dio dio = Dio();
  dio.interceptors.add(RetryInterceptor(
    dio: dio,
    logPrint: (str) => Fluttertoast.showToast(
      msg: "[Chat]错误: API调用失败: $str",
    ), // specify log function (optional)
    retries: 3, // retry count (optional)
  ));

  logger.d("[Chat] Sending message: $url | $headers | $body");
  try {
    final response = await dio.post(
      url,
      data: body,
      options: Options(
        headers: headers,
        followRedirects: false,
        validateStatus: (status) {
          return status! < 500;
        },
      ),
    );

    logger.d("[Chat] Response $response");

    if (response.statusCode == 200) {
      final responseJson = response.data;
      logger.d("[Chat] Get response: $responseJson");
      String answer = responseJson['answer'];
      int? answerType;
      if (responseJson['answer_type'] is bool) {
        answerType = responseJson['answer_type'] ? 1 : 0;
      } else {
        answerType = responseJson['answer_type'];
      }

      if (setImageText && responseJson['person_image_text'] != null) {
        configProvider.prevTryOnImageText = responseJson['person_image_text'];
      }

      if (answerType == 1) {
        List<int> gids = answer.split('_').map((s) => int.parse(s)).toList();
        for (int gid in gids) {
          await requestGarment(configProvider, garmentsProvider, gid);
        }
      }

      resultMessage = Message(sender: 1, type: answerType!, content: answer);
    } else {
      Fluttertoast.showToast(
        msg: "[Chat]错误: API调用失败[${response.statusCode}]",
      );
      resultMessage =
          Message(sender: 1, type: 2, content: "${response.statusCode}");
    }
  } catch (e) {
    logger.e("[Chat] Error $e");
    Fluttertoast.showToast(
      msg: "[Chat]错误: API调用失败[Err:${e.toString()}]",
    );
    resultMessage = Message(sender: 1, type: 2, content: e.toString());
  }
  logger.i("[Chat] Sending End, append to message");
  chatProvider.appendMessage(resultMessage, overwriteLast: resend);
}
