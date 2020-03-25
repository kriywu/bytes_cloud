import 'dart:io';

import 'package:bytes_cloud/core/common.dart';
import 'package:bytes_cloud/core/manager/TranslateManager.dart';
import 'package:bytes_cloud/entity/CloudFileEntity.dart';
import 'package:bytes_cloud/entity/DBManager.dart';
import 'package:bytes_cloud/entity/entitys.dart';
import 'package:bytes_cloud/http/http.dart';
import 'package:bytes_cloud/utils/FileUtil.dart';
import 'package:bytes_cloud/utils/SPWrapper.dart';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';

class CloudFileManager {
  List<CloudFileEntity> _entities = []; // 初始化
  List<CloudFileEntity> get photos {
    List<CloudFileEntity> _photos = [];
    _entities.forEach((f) {
      if (f.type == 'png' || f.type == 'jpg' || f.type == 'jpeg') {
        _photos.add(f);
      }
    });
    return _photos;
  }

  CloudFileEntity _root;
  int get rootId => _root.id;
  static CloudFileManager _instance;
  static bool _isInit = false;

  static CloudFileManager instance() {
    if (_instance == null) {
      _instance = CloudFileManager._init();
    }
    return _instance;
  }

  CloudFileManager._init() {
    initDataFromDB().whenComplete(() {
      _isInit = true;
    });
  }

  // 读取数据库的数据
  Future initDataFromDB() async {
    List es =
        await DBManager.instance.queryAll(CloudFileEntity.tableName, null);
    if (es == null) return;
    List<CloudFileEntity> temp = [];
    es.forEach((f) {
      CloudFileEntity entity = CloudFileEntity.fromJson(f);
      if (entity.id == 0) {
        _root = entity;
        print('_root 初始化完成');
        print(_root.toMap());
      }
      temp.add(entity);
    });
    _entities = temp;
  }

  Future<CloudFileEntity> insertCloudFile(CloudFileEntity entity) async {
    CloudFileEntity result = entity;
    try {
      _entities.add(result); // 更新缓存
      result = await DBManager.instance
          .insert(CloudFileEntity.tableName, entity); // 更新DB
    } catch (e) {
      print("insertCloudFile error!");
      result = null;
    }
    return result;
  }

  // 存DB
  saveAllCloudFiles(List<CloudFileEntity> entities) async {
    await (await DBManager.instance.db).transaction((txn) async {
      Batch batch = txn.batch();
      batch.delete(CloudFileEntity.tableName); // 先 clear 本地数据库
      entities.forEach((e) {
        batch.insert(CloudFileEntity.tableName, e.toMap()); // 再批量插入
      });
      await batch.commit(noResult: true);
    });
  }

  CloudFileEntity getEntityById(int id) {
    try {
      return _entities.firstWhere((e) {
        print('${e.id} == $id');
        return e.id == id;
      });
    } catch (e) {
      print('getEntityById ' + e.toString());
    }
    print('getEntityById null');
    return null;
  }

  List<CloudFileEntity> listRootFiles({bool justFolder = false}) {
    return listFiles(_root.id, justFolder: justFolder);
  }

  // sort type
  // type = 0 time default
  // type = 1 A-z
  List<CloudFileEntity> listFiles(int pId, {justFolder = false, type = 0}) {
    List<CloudFileEntity> result = [];
    _entities.forEach((f) {
      if (f.parentId == pId) {
        if (!justFolder) {
          result.add(f);
        } else if (justFolder && f.isFolder()) {
          result.add(f);
          print(f.uploadTime);
        }
      }
    });
    // 排序，文件夹在前，文件在后，uploadTime 由远到近
    if (type == 0) {
      result.sort((a, b) {
        if (a.isFolder() && !b.isFolder())
          return -1;
        else if (!a.isFolder() && b.isFolder()) return 1;
        return a.uploadTime - b.uploadTime;
      });
    } else if (type == 1) {
      result.sort((a, b) {
        if (a.isFolder() && !b.isFolder())
          return -1;
        else if (!a.isFolder() && b.isFolder()) return 1;
        return a.fileName.toLowerCase().compareTo(b.fileName.toLowerCase());
      });
    }
    return result;
  }

  int childrenCount(int pid, {justFolder = false}) {
    return listFiles(pid, justFolder: justFolder).length;
  }

  renameFile(int id, String newName) async {
    CloudFileEntity entity = getEntityById(id);
    if (entity == null) {
      return;
    }
    entity.fileName = newName; // update memory
    await DBManager.instance.update(
        CloudFileEntity.tableName, entity, MapEntry('id', id)); // update db
  }
}

class CloudFileHandle {
  // 获取所有的目录信息
  static Future reflashCloudFileList(
      {Function successCall, Function failedCall}) async {
    try {
      Map<String, dynamic> rsp =
          await httpGet(HTTP_GET_ALL_FILES, {'curUid': '0'});
      List maps = rsp['data'];
      List<CloudFileEntity> result = [];
      maps.forEach((json) {
        if (json['filename'] != null) {
          // 这里最好多检查一些字段
          result.add(CloudFileEntity.fromJson(json));
        }
      });
      print('getAllFile ${result.length}');
      await CloudFileManager.instance().saveAllCloudFiles(result); // 存DB
    } catch (e) {
      print('CloudFileHandle#getAllFile error! $e');
      if (failedCall != null) failedCall();
    }
    await CloudFileManager.instance().initDataFromDB(); // 更新内存数据
    if (successCall != null) successCall();
    return;
  }

  static Future newFolder(int curId, String folderName,
      {Function successCall, Function failedCall}) async {
    Map<String, dynamic> rsp;
    // 网络创建
    try {
      rsp = await httpPost(HTTP_POST_NEW_FOLDER,
          form: {'curId': curId, 'foldername': folderName});
    } catch (e) {
      failedCall({'code': -1, 'data': '', 'errMsg': '创建失败：网络错误'});
      return;
    }
    if (rsp['code'] != 0) {
      failedCall(rsp);
      return;
    }
    // 刷新DB
    try {
      await CloudFileManager.instance()
          .insertCloudFile(CloudFileEntity.fromJson(rsp['data']));
    } catch (e) {
      failedCall({'code': -1, 'data': '', 'errMsg': '插入数据库错误'});
      return;
    }
    successCall(rsp);
  }

  static Future uploadOneFile(int dirId, String path) async {
    String name = FileUtil.getFileNameWithExt(path);
    print('uploadOneFile ${path}');
    UploadTask task = UploadTask(path: path, token: CancelToken());
    TranslateManager.instant().addDownTask(task);
    int lastTime = DateTime.now().millisecondsSinceEpoch;
    var resp = await httpPost(HTTP_POST_A_FILE, call: (sent, total) {
      print('$sent / $total');
      int currentTime = DateTime.now().millisecondsSinceEpoch;
      task.v = 1000 * ((sent - task.sent) / (currentTime - lastTime));
      lastTime = currentTime;
      task.sent = sent;
      task.total = total;
    }, form: {
      'curId': 0,
      'file': await MultipartFile.fromFile(path, filename: name),
    });
    print(resp.toString());
  }

  static Future downloadOneFile(
      int id, String fileName, CancelToken cancelToken,
      {Function call}) async {
    print('downloadOneFile ${id} ${fileName}');
    // check file exist
    DownloadTask task = DownloadTask(
        id: id,
        fileName: fileName,
        path: Common().appDownload + '/' + fileName,
        token: cancelToken);
    TranslateManager.instant().addDoingTask(task);
    int lastTime = DateTime.now().millisecondsSinceEpoch;
    print('--------- begin ${DateTime.now().toString()}');
    try {
      var resp = await httpDownload(
          HTTP_POST_DOWNLOAD_FILE, {'id': task.id}, task.path, (sent, total) {
        int currentTime = DateTime.now().millisecondsSinceEpoch;
        task.v = 1000 * ((sent - task.sent) / (currentTime - lastTime));
        lastTime = currentTime;
        task.sent = sent;
        task.total = total;
      });
      // download finished, 可能文件没有下载完成，但是
      print('download finished id $id');
      SPUtil.setBool(SPUtil.downloadedKey(id), true);
    } catch (e) {
      print(e.toString());
    }
    print('---------- end ${DateTime.now().toString()}');
  }
}
