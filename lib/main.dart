import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DBProvider.db.database;
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
      home: MyHomePage(title: 'Flutter Demo Home Page'),
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

  Future<void> insertDBData() async{
    var random = Random();
    var test = Test(name: random.nextInt(100).toString(), text: random.nextInt(100).toString());
    await Future.wait([DBProvider.db.insertData(test)]);
    setState(() {});
  }

  Future<List<Map<String, dynamic>>> queryDBData() async {
    return await DBProvider.db.queryData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.height,
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FutureBuilder(
                  future: queryDBData(),
                  builder: (context, snapshot){
                    if(snapshot.hasData){
                      print(snapshot.data);
                      return ListView.builder(
                        itemCount: snapshot.data.length,
                        shrinkWrap: true,
                        reverse: true,
                        itemBuilder: (context, index){
                          return Container(
                            child: Text(
                              '${snapshot.data[index]['text']}'
                            ),
                          );
                        },
                      );
                    } else {
                      return Container();
                    }
                  }
                )
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: insertDBData,
        tooltip: 'カスタム文字入力',
        child: Icon(Icons.add),
      ),
    );
  }
}

const scripts = {
  '2' : ['ALTER TABLE test ADD COLUMN name TEXT;'],
  '3' : ['ALTER TABLE test ADD COLUMN test TEXT;'],
};

class DBProvider {

  DBProvider._();

  static final DBProvider db = DBProvider._();

  Database _databaseData;

  Future<Database> get database async {
    if (_databaseData != null) {
      return _databaseData;
    } else {
      _databaseData = await initDB();
      return _databaseData;
    }
  }

  Future<Database> initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final path = join(documentsDirectory.path, 'test.db');
    Database _db = await openDatabase(path, version: 3,
        onCreate: (Database db, int version) async {
          await db.execute('''
              CREATE TABLE test (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT,
                text TEXT,
                test TEXT
              )
            ''');
        },
        onUpgrade: (Database db, int oldVersion, int newVersion) async {
          for (var i = oldVersion + 1; i <= newVersion; i++) {
            var queries = scripts[i.toString()];
            for (String query in queries) {
              await db.execute(query);
            }
          }
        }
      );
    return _db;
  }

  Future<int> insertData(Test test) async {
    final _db = await database;
    var result = await _db.insert(
      'test',
      test.insertToMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return result;
  }

  Future<List<Map<String, dynamic>>> queryData() async {
    final _db = await database;
    List<Map<String, dynamic>> maps = await _db.query('test');
    return maps;
  }

}

class Test {
  final int id;
  final String name;
  final String text;

  Test({this.id, this.name, this.text});

  Map<String, dynamic> insertToMap(){
    return {
      'name': name,
      'text': text,
    };
  }
}
