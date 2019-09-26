import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cipher2/cipher2.dart';

void main() {
  runApp(MyApp());
  if (Platform.isAndroid) {
    SystemUiOverlayStyle systemUiOverlayStyle =
        SystemUiOverlayStyle(statusBarColor: Colors.transparent);
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Landing(),
    );
  }
}

void showToast(String msg) {
  Fluttertoast.showToast(
      msg: '$msg',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIos: 1,
      backgroundColor: Colors.grey[100],
      textColor: Colors.grey[800],
      fontSize: 16.0);
}

class Config with ChangeNotifier {
  String time;
  String rule;
  dynamic json;
  bool isLoading;

  Config(this.time, this.rule) {
    if (rule != null) {
      json = jsonDecode(rule);
    }
    isLoading = false;
  }

  static String langdingPng = 'skmm.png';
  static Future<Config> init() async {
    final prefs = await SharedPreferences.getInstance();
    String time = prefs.getString("time");
    String rule = prefs.getString("rule");
    await Future.delayed(Duration(milliseconds: 100));
    return Config(time, rule);
  }

  Future<String> decrypt(String s) async {
    s = s.substring("data:app/exviewdata;".length);
    final encrypted = s.substring("83759ef7b6bef7c53347d30811e93424,".length);
    final kv = s.substring(0, "83759ef7b6bef7c53347d30811e93424".length);
    final key = <String>[];
    final iv = <String>[];
    for (int i = 0; i < 8; i++) {
      key.add(kv[i]);
      key.add(kv[i + 16]);
      iv.add(kv[i + 8]);
      iv.add(kv[i + 24]);
    }
    return await Cipher2.decryptAesCbc128Padding7(
        encrypted, key.join(), iv.join());
  }

  Future<void> copy() async {
    await Clipboard.setData(ClipboardData(text: rule));
    showToast('已复制');
  }

  Future<void> save(String time, String rule) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("time", time);
    prefs.setString("rule", rule);
  }

  Future<void> update() async {
    if (isLoading) return;
    isLoading = true;
    notifyListeners();
    try {
      final url =
          "https://dev.tencent.com/u/gentle/p/datas/git/raw/master/reader4exview/mhyd_sources.json";
      http.Response res = await http.get(url);
      rule = await decrypt(res.body);
      json = jsonDecode(rule);
      time = DateTime.now().toString();
      await save(time, rule);
      isLoading = false;
      showToast('更新成功');
      NotificationListener();
    } catch (e) {
      showToast(e.toString());
    } finally {
      isLoading = false;
    }
  }
}

class Landing extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Config.init(),
      builder: (BuildContext context, AsyncSnapshot<Config> snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            body: Center(
              child: Image.asset(Config.langdingPng),
            ),
          );
        }
        return HomePage(config: snapshot.data);
      },
    );
  }
}

class HomePage extends StatelessWidget {
  HomePage({
    this.config,
    Key key,
  }) : super(key: key);

  final Config config;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('狐狸头的追随者'),
      ),
      body: ChangeNotifierProvider(
        builder: (context) => config,
        child: Consumer<Config>(
          builder: (BuildContext context, Config config, Widget _) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    '规则总数 ${config.json?.length ?? 0}',
                    style: TextStyle(fontSize: 16, height: 2),
                  ),
                  Text(
                    '更新时间 ${config.time ?? '暂无'}',
                    style: TextStyle(fontSize: 16, height: 2),
                  ),
                  RaisedButton(
                    child: Text('查看规则'),
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (BuildContext context) =>
                                RuleListPage(json: config.json))),
                  ),
                  RaisedButton(
                    child: Text('复制全部'),
                    onPressed: () => config.copy(),
                  ),
                  RaisedButton(
                    child: Text('更新'),
                    onPressed: () => config.update(),
                  ),
                  config.isLoading
                      ? Image.asset(Config.langdingPng)
                      : Container(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class RuleListPage extends StatelessWidget {
  RuleListPage({
    this.json,
    Key key,
  }) : super(key: key);
  final List json;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('规则列表'),
        ),
        body: ListView.builder(
          itemCount: json?.length ?? 0,
          itemBuilder: (BuildContext context, int index) {
            final Map rule = json[index];
            return ListTile(
              leading: Text(index.toString()),
              title: Text('${rule["bookSourceName"]}'),
              subtitle: Text('${rule["bookSourceGroup"]}'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (BuildContext context) => RulePage(rule: rule))),
            );
          },
        ));
  }
}

class RulePage extends StatelessWidget {
  RulePage({
    this.rule,
    Key key,
  }) : super(key: key);
  final Map rule;

  @override
  Widget build(BuildContext context) {
    final keys = rule.keys.toList();
    return Scaffold(
      appBar: AppBar(
        title: Text('${rule["bookSourceName"]}'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.content_copy),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: jsonEncode(rule)));
              showToast('已复制');
            },
          )
        ],
      ),
      body: ListView.builder(
        padding: EdgeInsets.only(left: 12, right: 12, top: 0, bottom: 12),
        itemCount: keys.length,
        itemBuilder: (BuildContext context, int index) {
          return TextField(
            minLines: 1,
            maxLines: 18,
            controller: TextEditingController(text: '${rule[keys[index]]}'),
            decoration: InputDecoration(
              labelText: keys[index],
            ),
          );
        },
      ),
    );
  }
}
