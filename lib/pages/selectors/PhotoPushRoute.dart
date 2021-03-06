import 'package:bytes_cloud/core/manager/CloudFileManager.dart';
import 'package:bytes_cloud/pages/selectors/CloudFolderSelector.dart';
import 'package:bytes_cloud/utils/FileUtil.dart';
import 'package:bytes_cloud/utils/UI.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:multi_image_picker/multi_image_picker.dart';

class PhotoPushRoute extends StatefulWidget {
  static int TYPE_OPEN_SELECT = 1;
  int type = 0;
  PhotoPushRoute({this.type = 0});

  @override
  State<StatefulWidget> createState() {
    return PhotoPushRouteState(type);
  }
}

class PhotoPushRouteState extends State<PhotoPushRoute> {
  int type = 0;
  List<Asset> images = List<Asset>();

  PhotoPushRouteState(this.type);

  @override
  void initState() {
    super.initState();
    if (type == PhotoPushRoute.TYPE_OPEN_SELECT) {
      loadAssets();
    }
  }

  Widget buildGridView() {
    return GridView.count(
      crossAxisCount: 3,
      children: List.generate(images.length, (index) {
        Asset asset = images[index];
        return AssetThumb(
          asset: asset,
          width: 300,
          height: 300,
        );
      }),
    );
  }

  Future<void> loadAssets() async {
    List<Asset> resultList = List<Asset>();

    resultList = await MultiImagePicker.pickImages(
      maxImages: 300,
      enableCamera: true,
      selectedAssets: images,
      cupertinoOptions: CupertinoOptions(takePhotoIcon: "chat"),
      materialOptions: MaterialOptions(
        actionBarTitle: "选取图片",
        allViewTitle: "所有照片",
        useDetailsView: true,
        selectCircleStrokeColor: "#000000",
      ),
    );

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      images = resultList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('选取照片'),
          leading: InkWell(
            child: Icon(Icons.arrow_left),
            onTap: () => Navigator.pop(context),
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.file_upload),
              onPressed: () async {
                if(images.length == 0) {
                  Fluttertoast.showToast(msg: '请先选择文件');
                  return;
                }
                UI.showProgressDialog(context: context);
                List<String> paths = [];
                for(Asset asset in images){
                  ByteData bytes = await asset.getByteData(quality: 0);
                  paths.add(await FileUtil.saveBytesAsFile(bytes));
                }
                Navigator.pop(context);
                UI.newPage(context, CloudFolderSelector(paths));
              },
            )
          ],
        ),
        body: Padding(
          child: buildGridView(),
          padding: EdgeInsets.all(8),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.insert_photo),
          onPressed: () {
            loadAssets();
          },
        ),
      ),
    );
  }
}
