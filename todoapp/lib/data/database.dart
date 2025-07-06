import 'package:hive/hive.dart';

class ToDoDatabase {
  List toDoList = [];

//   reference box
  final _mybox = Hive.box('mybox');

//   first time loading app execution
  void createInitialData() {
    toDoList = [
      ["Make Tutorial", false],
      ["Do Exercise", false]
    ];
  }

//   load data from database
  void loadData() {
    toDoList = _mybox.get("TODOLIST");
  }

// update the database
  void updateDatabase() {
    _mybox.put("TODOLIST", toDoList);
  }
}