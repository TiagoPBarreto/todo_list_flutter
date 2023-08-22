import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _todoController = TextEditingController();
  List _todoList = [];
  late Map<String, dynamic> _lastRemove;
  int? _lastRemovePos;

  @override
  void initState() {
    super.initState();
    _readData().then((data) => {
          setState(() {
            _todoList = json.decode(data);
          })
        });
  }

  void _addTodo() {
    setState(() {
      Map<String, dynamic> newTodo = Map();
      newTodo["title"] = _todoController.text;
      _todoController.text = "";
      newTodo["OK"] = false;
      _todoList.add(newTodo);
      _saveData();
    });
  }

  Future<Null> _refresh()async{
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _todoList.sort((a,b){
        if(a["OK"] && !b["OK"]) return 1;
        else if(!a["OK"] && b["OK"]) return -1;
        else return 0;
      });
      _saveData();
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Lista de tarefa",
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              17.0,
              1,
              7,
              1,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: "Nova Tarefa",
                      labelStyle: TextStyle(
                        color: Colors.blueAccent,
                      ),
                    ),
                    controller: _todoController,
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent),
                  onPressed: _addTodo,
                  child: const Text(
                    "ADD",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: EdgeInsets.only(top: 10.0),
                itemCount: _todoList.length,
                itemBuilder: buildItem,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().microsecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child:  Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_todoList[index]["title"]),
        value: _todoList[index]["OK"],
        secondary: CircleAvatar(
          child: Icon(
            _todoList[index]["OK"] ? Icons.check : Icons.error,
          ),
        ),
        onChanged: (check) {
          setState(() {
            _todoList[index]["OK"] = check;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemove = Map.from(_todoList[index]);
          _lastRemovePos = index;
          _todoList.removeAt(index);
          _saveData();
          SnackBar(
            content: Text(
              "Tarefa ${_lastRemove["title"]} removida",
            ),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  _todoList.insert(_lastRemovePos!, _lastRemove);
                  _saveData();
                });
              },
            ),
            duration: Duration(
              seconds: 2,
            ),
          );
          //Scaffold.of(context).removeCurrentSnackBar();
          //Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_todoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return "";
    }
  }
}
