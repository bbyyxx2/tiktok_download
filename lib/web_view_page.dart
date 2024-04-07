import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tiktok_download/web_util.dart';
import 'package:webview_flutter/webview_flutter.dart';
// Import for Android features.
import 'package:webview_flutter_android/webview_flutter_android.dart';
// Import for iOS features.
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class WebViewPage extends StatefulWidget {
  final String title;
  final String url;

  const WebViewPage({Key? key, required this.title, required this.url})
      : super(key: key);

  @override
  _WebViewPageState createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  @override
  Widget build(BuildContext context) {
    WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) {
          if (request.url.contains("video/") || request.url.contains(".mp4")) {
            print('byx---- request.url=${request.url}');
            //获取到视频下载地址
            // String type = WebUtil.getContentType(request.url).toString();
            if (!request.url.contains('share/video')) {
              // print('byx---- type=$type');
              print('byx---- 准备显示弹窗url=${request.url}');
              //弹窗
              _showDownloadDialog(context, request.url);
            }
          } else {
            //没有获取到视频下载地址
          }
          return NavigationDecision.navigate;
        },
      ))
      ..setUserAgent(
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:91.0) Gecko/20100101 Firefox/91.0')
      ..loadRequest(Uri.parse(widget.url));

    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: WebViewWidget(controller: controller));
  }
}

void _showDownloadDialog(BuildContext context, String url) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('是否下载视频？'),
        actions: <Widget>[
          TextButton(
            child: const Text('确认'),
            onPressed: () {
              Navigator.of(context).pop(); // 关闭弹窗
              _downloadVideo(url); // 下载视频
            },
          ),
          TextButton(
            child: const Text('取消'),
            onPressed: () {
              Navigator.of(context).pop(); // 关闭弹窗
            },
          ),
        ],
      );
    },
  );
}

Future<void> _downloadVideo(String url) async {
  try {
    // 获取文件路径
    // final directory = await getExternalStorageDirectory();
    final directory = '/storage/emulated/0/Download';
    var now = DateTime.now();
    var formatter = DateFormat('yyyyMMddHHmmss');
    String formattedDate = formatter.format(now);
    // final path = '${directory!.path}/dyDownload/$formattedDate.mp4';
    final path = '$directory/dyDownload/$formattedDate.mp4';
    print('byx---- path=$path');

    // 下载视频
    Uri uri = Uri.parse(url);
    print('byx-----host=${uri.host}');
    var response = await http.get(Uri.parse(url), headers: {
      HttpHeaders.hostHeader: uri.host,
      HttpHeaders.connectionHeader: 'keep-alive',
      HttpHeaders.userAgentHeader: WebUtil.UA
    });
    if (response.statusCode == 302) {
      response = await http.get(Uri.parse(url), headers: {
        HttpHeaders.hostHeader: uri.host,
        HttpHeaders.connectionHeader: 'keep-alive',
        HttpHeaders.userAgentHeader: WebUtil.UA,
        HttpHeaders.locationHeader:
            response.headers[HttpHeaders.locationHeader] ?? ''
      });
    } else if (response.statusCode != 200) {
      print('请求失败，状态码：${response.statusCode}');
      return;
    }

    final file = File(path);
    // 创建目录
    // final dir = Directory('${directory.path}/dyDownload');
    final dir = Directory('$directory/dyDownload');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    await file.writeAsBytes(response.bodyBytes);
    print('byx----下载完成');
  } catch (e) {
    print('byx-----下载视频时发生错误：$e');
  }
}
