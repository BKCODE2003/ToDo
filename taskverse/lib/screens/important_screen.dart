import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../widgets/task_tile.dart';

class ImportantScreen extends StatefulWidget {
  const ImportantScreen({super.key});

  @override
  _ImportantScreenState createState() => _ImportantScreenState();
}

class _ImportantScreenState extends State<ImportantScreen> {
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
    // Get only important tasks
    List<Task> importantTasks = tasks.where((task) => task.isImportant).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Important')),
      body: importantTasks.isEmpty
          ? const Center(child: Text('No important tasks!'))
          : ListView.builder(
              itemCount: importantTasks.length,
              itemBuilder: (context, index) {
                return TaskTile(
                  task: importantTasks[index],
                  onTaskDeleted: () {
                    setState(() {
                      tasks.remove(importantTasks[index]); // Delete task
                      _sortTasks();
                    });
                  },
                  onTaskCompleted: () {
                    setState(() {
                      importantTasks[index].isCompleted = true; // Mark as complete
                      _sortTasks();
                    });
                  },
                  onTaskIncompleted: () {
                    setState(() {
                      importantTasks[index].isCompleted = false; // Mark as incomplete
                      _sortTasks();
                    });
                  },
                );
              },
            ),
    );
  }
}
