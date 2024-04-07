import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tiktok_download/web_util.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_toastr/flutter_toastr.dart';

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
      iframeAllowFullscreen: true,
      userAgent: WebUtil.UA);

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
          shouldInterceptRequest: (controller, request) async {
            String url = request.url.toString();
            //eg通常是这个地址
            //https://v3-web.douyinvod.com/1f7ef7e17ad7dc1dc469c91e6841ffd4/6612d487/video/tos/cn/tos-cn-ve-15/
            //oEHhdi7ZIlPANJ9B5tOztAQeRCAfQ6sgB9FyEh/?a=6383&ch=26&cr=3&dr=0&lr=all&cd=0%7C0%7C0%7C3&cv=1&br=1240&bt=1240&cs=0&ds=3&ft=
            //LjhJEL998xI7uEPmD0P58lZW_3iX3QiTxVJEMZlClbPD-Ipz&mime_type=video_mp4&qs=1&rc=
            //Ojk4aDo2Zzk8NDMzZjU7ZkBpM3Nxcmk6ZjRycTMzNGkzM0A1NDAtYDIxNi4xXzU2XmI0YSM1a19mcjRfZWpgLS1kLWFzcw%3D%3D&btag=
            //e00008000&cquery=100x_100z_100a_100w_100B&dy_q=1712506475&feature_id=46a7bb47b4fd1280f3d3825bf2b29388&l=
            //20240408001435BB11DC6ED73220137EC8
            if (url.contains("video/") || url.contains(".mp4")) {
              // 这里可以添加你的视频下载逻辑
              // 示例：如果是视频请求，可以选择不拦截，让视频正常播放
              // 如果需要下载，可以使用其他方法实现，这里不展示具体下载逻辑
              String type = await WebUtil.getContentType(url) as String;
              print("byx------拦截地址: $url \n type:$type");
              if (type.startsWith('video')) {
                print("byx------下载地址: $url");
                _showDownloadDialog(context, url);
              }
              return Future.value(null); // 返回一个包含null的Future，表示不拦截请求
            }
            // 对于非视频请求，返回null表示不拦截
            return Future.value(null);
          },
        ));
  }
}

void _showDownloadDialog(BuildContext pContext, String url) {
  showDialog(
    context: pContext,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('是否下载视频？'),
        actions: <Widget>[
          TextButton(
            child: const Text('确认'),
            onPressed: () {
              Navigator.of(context).pop(); // 关闭弹窗
              _downloadVideo(pContext, url); // 下载视频
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

Future<void> _downloadVideo(BuildContext context,String url) async {
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
    FlutterToastr.show("下载完成！", context,
          duration: FlutterToastr.lengthShort, position: FlutterToastr.bottom);
    print('byx----下载完成');
  } catch (e) {
    print('byx-----下载视频时发生错误：$e');
  }
}
