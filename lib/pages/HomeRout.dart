import 'package:bytes_cloud/core/manager/CloudFileManager.dart';
import 'package:bytes_cloud/utils/UI.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'NativeRoute.dart';
import 'content/remote/RemoteRoute.dart';
import 'RecentRoute.dart';
import 'SelfRoute.dart';

class HomeRoute extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return HomeRouteState();
  }
}

class HomeRouteState extends State<HomeRoute>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  TabController tabController;
  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 4, vsync: this);
    print("home route init");
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    print('home route build');
    UI.initSize(context);
    return Scaffold(
      body: TabBarView(controller: tabController, children: <Widget>[
        RecentRoute(),
        NativeRoute(),
        ListenableProvider.value(
          value: CloudFileManager.instance().model,
          child: RemoteRoute(),
        ),
        SelfRoute()
      ]),
      bottomNavigationBar: Material(
        child: TabBar(
            controller: tabController,
            labelColor: Theme.of(context).accentColor,
            unselectedLabelColor: Colors.grey,
            tabs: <Widget>[
              Tab(
                text: '最近',
                icon: const Icon(Icons.beach_access),
              ),
              Tab(
                text: '分类',
                icon: const Icon(Icons.phone_android),
              ),
              Tab(
                text: '云盘',
                icon: const Icon(Icons.cloud),
              ),
              Tab(
                text: '我的',
                icon: const Icon(Icons.person),
              )
            ]),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    tabController.dispose();
    print('home route dispose');
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void deactivate() {
    super.deactivate();
    print('home route deactivate');
  }
}
