import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tiktok_download/web_util.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewPage extends StatefulWidget {
  final String title;
  final String url;

  const WebViewPage({Key? key, required this.title, required this.url})
      : super(key: key);

  @override
  _WebViewPageState createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController? webViewController;
  InAppWebViewSettings settings = InAppWebViewSettings(
      isInspectable: kDebugMode,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      iframeAllow: "camera; microphone",
      iframeAllowFullscreen: true);

  PullToRefreshController? pullToRefreshController;
  String url = "";
  double progress = 0;
  final urlController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    pullToRefreshController = kIsWeb
        ? null
        : PullToRefreshController(
            settings: PullToRefreshSettings(
              color: Colors.blue,
            ),
            onRefresh: () async {
              if (defaultTargetPlatform == TargetPlatform.android) {
                webViewController?.reload();
              } else if (defaultTargetPlatform == TargetPlatform.iOS) {
                webViewController?.loadUrl(
                    urlRequest:
                        URLRequest(url: await webViewController?.getUrl()));
              }
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(widget.url)),
          initialSettings: settings,
          pullToRefreshController: pullToRefreshController,
          onWebViewCreated: (controller) {
            webViewController = controller;
          },
          onLoadStart: (controller, url) {
            setState(() {
              this.url = url.toString();
              urlController.text = this.url;
            });
          },
          onPermissionRequest: (controller, request) async {
            return PermissionResponse(
                resources: request.resources,
                action: PermissionResponseAction.GRANT);
          },
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            var uri = navigationAction.request.url!;

            if (![
              "http",
              "https",
              "file",
              "chrome",
              "data",
              "javascript",
              "about"
            ].contains(uri.scheme)) {
              if (await canLaunchUrl(uri)) {
                // Launch the App
                await launchUrl(
                  uri,
                );
                // and cancel the request
                return NavigationActionPolicy.CANCEL;
              }
            }

            return NavigationActionPolicy.ALLOW;
          },
          onLoadStop: (controller, url) async {
            pullToRefreshController?.endRefreshing();
            setState(() {
              this.url = url.toString();
              urlController.text = this.url;
            });
          },
          onReceivedError: (controller, request, error) {
            pullToRefreshController?.endRefreshing();
          },
          onProgressChanged: (controller, progress) {
            if (progress == 100) {
              pullToRefreshController?.endRefreshing();
            }
            setState(() {
              this.progress = progress / 100;
              urlController.text = url;
            });
          },
          onUpdateVisitedHistory: (controller, url, androidIsReload) {
            setState(() {
              this.url = url.toString();
              urlController.text = this.url;
            });
          },
          onConsoleMessage: (controller, consoleMessage) {
            if (kDebugMode) {
              print(consoleMessage);
            }
          },
        ));
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
