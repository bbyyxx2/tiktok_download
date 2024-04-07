import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter/material.dart';
import 'web_view_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_toastr/flutter_toastr.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: '下载抖音无水印视频'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();

  void _downloadVideo() async {
    String waitParseUrl = _controller.text.trim();
    print('byx-------原始url=$waitParseUrl');
    String PREFIX = 'v.douyin.com/';

    if (waitParseUrl.isNotEmpty) {
      if (waitParseUrl.contains("http") && waitParseUrl.contains(PREFIX)) {
        int last1 = waitParseUrl.lastIndexOf(PREFIX);
        int last2 = waitParseUrl.substring(last1 + PREFIX.length).indexOf("/") + last1 + PREFIX.length;
        if (last2 == -1) {
          last2 = waitParseUrl.length;
        }
        if (last1 != -1 && last2 != -1) {
          String realRoute =
              waitParseUrl.substring(last1 + PREFIX.length, last2);
          String url = "https://$PREFIX$realRoute";
          print('byx-------跳转url=$url');
          if (Platform.isAndroid || Platform.isIOS) {
            // 下载视频的逻辑
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WebViewPage(title: '下载视频', url: url),
              ),
            );
          } else {
            //试图调用浏览器打开
            final Uri _url = Uri.parse(url);
            if (!await launchUrl(_url)) {
              throw Exception('Could not launch $_url');
            }
          }
        }
      }
    } else {
      FlutterToastr.show("请输入正确的视频链接！", context,
          duration: FlutterToastr.lengthShort, position: FlutterToastr.bottom);
    }
  }

  void _openTikTok() {
    // 打开抖音的逻辑
    print('打开抖音');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '请输入视频链接',
                ),
              ),
            ),
            const SizedBox(height: 16), // 添加间距
            SizedBox(
              width: double.infinity, // 宽度填充整个屏幕宽度
              height: 50.0, // 设置按钮高度
              child: ElevatedButton(
                onPressed: _downloadVideo,
                child: const Text('下载(无水印)视频'),
              ),
            ),
            const SizedBox(height: 16), // 添加间距
            SizedBox(
              width: double.infinity, // 宽度填充整个屏幕宽度
              height: 50.0, // 设置按钮高度
              child: ElevatedButton(
                onPressed: _openTikTok,
                child: const Text('打开抖音'),
              ),
            ),
            const SizedBox(height: 16), // 添加间距
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('该app用于下载抖音无水印视频。\n\n'
                  ' 使用说明：\n '
                  '1.输入抖音分享链接->点击下载按钮->跳转webView->等待提示下载，确认后下载无水印视频。\n'
                  '2.下载问界保存在Download目录下'),
            ),
          ],
        ),
      ),
    );
  }
}
