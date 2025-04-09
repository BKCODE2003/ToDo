import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../widgets/task_tile.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  _TasksScreenState createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  @override
  void initState() {
    super.initState();
    _sortTasks();
  }

  void _sortTasks() {
    setState(() {
      tasks.sort((a, b) {
        if (a.isCompleted == b.isCompleted) {
          return a.dueDateTime.compareTo(b.dueDateTime); // Sort by due date
        }
        return a.isCompleted ? 1 : -1; // Incomplete first
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Tasks')),
      body: tasks.isEmpty
          ? const Center(child: Text('No tasks added yet!'))
          : ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return TaskTile(
                  task: tasks[index],
                  onTaskDeleted: () {
                    setState(() {
                      tasks.removeAt(index); // Delete & refresh list
                      _sortTasks();
                    });
                  },
                  onTaskCompleted: () {
                    setState(() {
                      tasks[index].isCompleted = true; // Mark complete
                      _sortTasks();
                    });
                  },
                  onTaskIncompleted: () {
                    setState(() {
                      tasks[index].isCompleted = false; // Mark incomplete
                      _sortTasks();
                    });
                  },
                );
              },
            ),
    );
  }
}
