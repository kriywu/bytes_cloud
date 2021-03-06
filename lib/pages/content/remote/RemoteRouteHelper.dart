import 'dart:io';

import 'package:bytes_cloud/core/Constants.dart';
import 'package:bytes_cloud/core/http/http.dart';
import 'package:bytes_cloud/core/manager/CloudFileManager.dart';
import 'package:bytes_cloud/core/manager/DBManager.dart';
import 'package:bytes_cloud/entity/CloudFileEntity.dart';
import 'package:bytes_cloud/entity/ShareEntity.dart';
import 'package:bytes_cloud/pages/content/MoreInfoPage.dart';
import 'package:bytes_cloud/pages/selectors/CloudFolderSelector.dart';
import 'package:bytes_cloud/pages/widgets/ShareWindow.dart';
import 'package:bytes_cloud/utils/FileUtil.dart';
import 'package:bytes_cloud/utils/SPUtil.dart';
import 'package:bytes_cloud/utils/UI.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

// 对文件或者文件夹对操作独立出来
class RemoteRouteHelper {
  static const SHOW_TYPE_FILE = 0;
  static const SHOW_TYPE_PHOTO = 1;
  static const SHOW_TYPE_VIDEO = 2;
  static const SHOW_TYPE_MUSIC = 3;
  static const SHOW_TYPE_DOC = 4;
  static const SHOW_TYPE_RAR = 5;

  BuildContext context;
  RemoteRouteHelper(this.context);

  /// [type] 0 文件夹展示：全量显示, !0 分类展示，不显示移动&重命名
  /// [callBack] 方法执行完成的回调
  showBottomSheet(CloudFileEntity entity, {int type = 0}) async {
    List<Widget> content = [];
    Widget downloadActionWidget = Expanded(
        child: UI.iconTxtBtn(Constants.DOWNLOADED, '下载', () async {
      Navigator.pop(context);
      await downloadAction(entity);
    }, fontWeight: FontWeight.normal));
    Widget shareActionWidget = Expanded(
        child: UI.iconTxtBtn(Constants.SHARE2, '分享', () async {
      Navigator.pop(context);
      await shareAction(entity);
    }, fontWeight: FontWeight.normal));
    Widget moveActionWidget = Expanded(
        child: UI.iconTxtBtn(Constants.MOVE, '移动', () async {
      Navigator.pop(context);
      await moveAction(entity);
    }, fontWeight: FontWeight.normal));
    Widget deleteActionWidget = Expanded(
        child: UI.iconTxtBtn(Constants.DELETE, '删除', () async {
      Navigator.pop(context);
      await deleteAction(entity);
    }, fontWeight: FontWeight.normal));
    Widget renameActionWidget = Expanded(
        child: UI.iconTxtBtn(Constants.MODIFY, '重命名', () async {
      Navigator.pop(context);
      await reNameAction(entity);
    }, fontWeight: FontWeight.normal));
    Widget moreActionWidget = Expanded(
        child: UI.iconTxtBtn(Constants.MORE, '详情', () async {
      Navigator.pop(context);
      await moreInfoAction(entity);
    }, fontWeight: FontWeight.normal));

    if (type == RemoteRouteHelper.SHOW_TYPE_FILE) {
      content.add(downloadActionWidget);
      content.add(shareActionWidget);
      content.add(moveActionWidget);
      content.add(deleteActionWidget);
      content.add(renameActionWidget);
      content.add(moreActionWidget);
    } else {
      content.add(downloadActionWidget);
      content.add(shareActionWidget);
      //content.add(moveActionWidget);
      content.add(deleteActionWidget);
      //content.add(renameActionWidget);
      content.add(moreActionWidget);
    }

    UI.bottomSheet(
        context: context,
        content: Padding(
          padding: EdgeInsets.only(left: 8, right: 8),
          child: Row(
            children: content,
          ),
        ),
        height: 100,
        radius: 8,
        padding: 8);
  }

  moveAction(CloudFileEntity entity) async {
    // 因为Svr暂时不支持移动操作，所以这里先下载再上传实现移动
    if (!FileUtil.haveDownloaded(entity)) {
      CloudFileManager.instance().downloadFile([entity]);
    }
    // 上传
    UI.newPage(
        context, CloudFolderSelector([FileUtil.getDownloadFilePath(entity)]));
    // 删除当前
    // 因为不容易判断是否上传成功，所以暂时不删除原来的文件
  }

  // 分享 ACTION
  shareAction(CloudFileEntity entity) async {
    await UI.bottomSheet(
        context: context, content: ShareWindow(entity), height: 700);
  }

  // 下载 ACTION
  downloadAction(CloudFileEntity entity) async {
    if (entity.isFolder()) {
      UI.showSnackBar(context, Text('文件夹暂时不支持批量下载'));
      return;
    }
    File localFile = File(FileUtil.getDownloadFilePath(entity));
    if (SP.getBool(SP.downloadedKey(entity.id.toString()), false) &&
        localFile.existsSync()) {
      UI.openFile(context, localFile);
      return;
    }
    UI.showSnackBar(context, Text('开始下载 ${entity.fileName}'));
    await CloudFileManager.instance().downloadFile([entity]);
    UI.showSnackBar(
        context,
        InkWell(
          child: Text('${entity.fileName} 下载完成'),
          onTap: () =>
              UI.openFile(context, File(FileUtil.getDownloadFilePath(entity))),
        ),
        duration: Duration(seconds: 2));
  }

  // 重命名 ACTION
  reNameAction(CloudFileEntity entity) async {
    String input = await UI.showInputDialog(context, '重命名');
    if (input == null || input.trim() == '') return;
    String newName = input + FileUtil.ext(entity.fileName);
    bool success = await CloudFileManager.instance()
        .renameFile(entity.id, newName); // 告诉Svr
  }

  // 删除 ACTION
  deleteAction(CloudFileEntity entity) async {
    bool success = await CloudFileManager.instance().deleteFile(entity.id);
    return success;
  }

  moreInfoAction(CloudFileEntity entity) {
    Future.delayed(Duration(milliseconds: 100)).whenComplete(() {
      UI.newPage(context, MoreInfoPage(entity));
    });
  }
}
