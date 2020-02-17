import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';

class FileUtils {
//  static Directory tempDir;
//  static Directory appDir;
//  static FileUtils _instance;
//
//  // 工厂模式
//  factory FileUtils() => _getInstance();
//  static FileUtils get instance => _getInstance();
//  FileUtils._internal() {
//    init();
//  }
//  static FileUtils _getInstance() {
//    if (_instance == null) {
//      _instance = new FileUtils._internal();
//    }
//    return _instance;
//  }
//
//  init() async {
//    tempDir = await getTemporaryDirectory();
//    appDir = await getApplicationDocumentsDirectory();
//  }

  static String getFileName(String path) =>
      path.substring(path.lastIndexOf('/') + 1);

  static void writeToFile(
      {String path, String fileName, @required String content}) async {
    File file;
    if (path == null) {
      Directory dir = await getApplicationDocumentsDirectory();
      file = new File(dir.path + '/' + fileName);
    } else {
      file = new File(path);
    }
    if (!file.existsSync()) {
      file.createSync();
    }
    print(content);
    file.writeAsString(content);
  }

  static Future<String> readFromFile(String path) async {
    File file = new File(path);
    if (!file.existsSync()) {
      file.createSync();
    }
    return await file.readAsString();
  }

  static Future<List<FileSystemEntity>> listFiles(String path) async {
    Directory dir = await getApplicationDocumentsDirectory();
    Directory currentDir = new Directory(dir.path + '/' + path);
    if (!currentDir.existsSync()) {
      currentDir.createSync();
    }
    return currentDir.listSync();
  }

  static void createFile(String path, String fileName) async {
    Directory dir = await getApplicationDocumentsDirectory();
    File file = new File(dir.path + '/' + path + '/' + fileName);
    if (!file.existsSync()) {
      file.createSync();
    }
  }
}
