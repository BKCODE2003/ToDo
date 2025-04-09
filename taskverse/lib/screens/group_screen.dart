import 'package:flutter/material.dart';
import '../services/alarm_service.dart';

class GroupScreen extends StatelessWidget {
  const GroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // return Center(
    //   child: Text('Group Screen', style: TextStyle(fontSize: 24)),
      
    // );
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await AlarmService.testAlarm();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Test alarm set for 10 seconds from now')),
          );
        },
        child: const Icon(Icons.alarm),
      )
    );
  }

}
