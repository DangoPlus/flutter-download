import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_extend/share_extend.dart';
import 'dart:io';

final imgUrl =
    "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf";
var dio = Dio();

void main() async {
  await FlutterDownloader.initialize(debug: true);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Download Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  var _permissionStatus;
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  /// 检查是否有相关权限
  Future<void> checkPermissionStatus() async {
    final Future<PermissionStatus> statusFuture =
        (await Permission.storage.status) as Future<PermissionStatus>;

    statusFuture.then((PermissionStatus status) {
      setState(() {
        _permissionStatus = status;
      });
    });
  }

  void _requestDownload() async {
    Future<String> _findLocalPath() async {
      final directory = Theme.of(context).platform == TargetPlatform.android
          ? await getExternalStorageDirectory()
          : await getApplicationDocumentsDirectory();
      return directory.path;
    }

    // var _localPath =
    //     (await _findLocalPath()) + Platform.pathSeparator + 'Download';

    // final savedDir = Directory(_localPath);
    String localPath = await _findLocalPath() + Platform.pathSeparator;
    print(localPath);
    // String localPath = (await _findLocalPath()) + Platform.pathSeparator + 'Download';
    // String localPath = await ExtStorage.getExternalStoragePublicDirectory(ExtStorage.DIRECTORY_DOWNLOADS);
    // final savedDir = Directory(localPath);
    // bool hasExisted = await savedDir.exists();
    // if (!hasExisted) {
    //   savedDir.create();
    // }

    await FlutterDownloader.enqueue(
        url: imgUrl,
        headers: {"auth": "test_for_sql_encoding"},
        savedDir: localPath,
        showNotification: true,
        openFileFromNotification: true);
  }

  /// 请求系统权限，让用户确认授权
  Future requestPermission() async {
    if (Theme.of(context).platform == TargetPlatform.android) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
      ].request();
      print(statuses[Permission.storage]);
    }
  }

  openFile() async {
    var tempDir =  await _findLocalPath();
    ShareExtend.share(tempDir + '/boo2.pdf', "file");
  }
  Future download2(Dio dio, String url, String savePath) async {
    try {
      Response response = await dio.get(
        url,
        onReceiveProgress: showDownloadProgress,
        //Received data with List<int>
        options: Options(
            responseType: ResponseType.bytes,
            followRedirects: false,
            validateStatus: (status) {
              return status < 500;
            }),
      );
      print(response.headers);
      File file = File(savePath);
      var raf = file.openSync(mode: FileMode.write);
      // response.data is List<int> type
      raf.writeFromSync(response.data);
      await raf.close();
    } catch (e) {
      print(e);
    }
  }

  void showDownloadProgress(received, total) {
    if (total != -1) {
      print((received / total * 100).toStringAsFixed(0) + "%");
    }
  }

  Future<String> _findLocalPath() async {
    if(Theme.of(context).platform == TargetPlatform.android){
      return await ExtStorage.getExternalStoragePublicDirectory(ExtStorage.DIRECTORY_DOWNLOADS);
    }else {
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    }
    // final directory = Theme.of(context).platform == TargetPlatform.android
    //     ? await getExternalStorageDirectory()
    //     : await getApplicationDocumentsDirectory();
    // return directory.path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RaisedButton.icon(
                onPressed: () async {


                  // var tempDir =
                  //     await ExtStorage.getExternalStoragePublicDirectory(
                  //         ExtStorage.DIRECTORY_DOWNLOADS);
                  var tempDir =  await _findLocalPath();
                  // String fullPath = '/storage/emulated/0/Download/test.pdf';
                  String fullPath = tempDir + "/boo2.pdf";
                  print('full path $fullPath');

                  download2(dio, imgUrl, fullPath);
                },
                icon: Icon(
                  Icons.file_download,
                  color: Colors.white,
                ),
                color: Colors.green,
                textColor: Colors.white,
                label: Text('使用DIO下载')),
            Text(
              'You have pushed the button this many times:',
            ),
            RaisedButton(
              child: Text("使用flutter Downloader下载"),
              onPressed: _requestDownload,
            ),
            Text(
              "检查权限结果：",
            ),
            RaisedButton(
              child: Text("请求权限"),
              onPressed: requestPermission,
            ),
            RaisedButton(
              child: Text("打开"),
              onPressed: openFile,
            ),
          ],
        ),
      ),
    );
  }

  String hasPermissionText(permissionStatus) {
    return permissionStatus;
  }

  String getPermissionResult(permissionStatus) {
    return permissionStatus;
  }
}
