import 'dart:convert';

import 'package:bytes_cloud/core/manager/CloudFileLogic.dart';
import 'package:bytes_cloud/entity/CloudFileEntity.dart';
import 'package:bytes_cloud/utils/UI.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'content/MDListPage.dart';

class RemoteRoute extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return RemoteRouteState();
  }
}

class RemoteRouteState extends State<RemoteRoute>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  List<CloudFileEntity> currentPageFiles = [];
  List<CloudFileEntity> path = []; // 路径
  List<List<CloudFileEntity>> dirStack = []; //列表

  @override
  void initState() {
    super.initState();
    enterFolder(CloudFileManager.instance().rootId);
  }

  enterFolderAndRefresh(int pid) => setState(() {
        enterFolder(pid);
      });

  enterFolder(int pid) {
    path.add(CloudFileManager.instance().getEntityById(pid));
    currentPageFiles = CloudFileManager.instance().listFiles(pid);
    dirStack.add(currentPageFiles);
  }

  bool outFolderAndRefresh() {
    if (path.length == 1) return true;
    setState(() {
      path.removeLast();
      dirStack.removeLast();
      currentPageFiles = dirStack.last;
    });
    return false;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.widgets),
            onPressed: () {},
          ),
          actions: <Widget>[
            IconButton(icon: Icon(Icons.add), onPressed: () {}),
            IconButton(
              icon: Icon(Icons.transform),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.sort),
              onPressed: () {},
            )
          ],
        ),
        body: WillPopScope(
          child: cloudListView(),
          onWillPop: () async => outFolderAndRefresh(),
        ));
  }

  cloudListView() {
    var listView = ListView.separated(
        itemCount: currentPageFiles.length,
        separatorBuilder: (BuildContext context, int index) {
          return UI.divider2(left: 80, right: 32);
        },
        itemBuilder: (BuildContext context, int index) {
          CloudFileEntity entity = currentPageFiles[index];
          Widget item;
          if (entity.isFolder()) {
            item = UI.buildCloudFolderItem(
                file: entity,
                childrenCount:
                    CloudFileManager.instance().childrenCount(entity.id),
                onTap: () {
                  enterFolderAndRefresh(entity.id);
                });
          } else {
            item = UI.buildCloudFileItem(file: entity, onTap: () {});
          }
          return Padding(
            padding: EdgeInsets.only(left: 8, right: 8),
            child: item,
          );
        });
    return RefreshIndicator(
      child: Scrollbar(child: listView),
      onRefresh: () async {
        await CloudFileHandle.reflashCloudFileList();
        setState(() {});
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
