import 'package:flutter/material.dart';
//this will hold the code for assignment cards across different screens

class LargeListCard extends StatelessWidget{
  final String dueDate;
  final String title;
  final String type;
  final Color color;
  final bool invalidDate;

  const LargeListCard({
    super.key,
    required this.dueDate,
    required this.title,
    required this.type,
    required this.color,
    required this.invalidDate,
  });

  @override
  Widget build(BuildContext context){
    return Card(
      color: color,
      child: ListTile(
        title: Text(
          title,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        subtitle: invalidDate ? const Text("Invalid Due Date") : dueDate.trim().isEmpty ? const Text("No Due Date") : Text(
          "Due: ${dueDate.split(" ")[0]}\n${dueDate.split(" ")[1]}",
        ),
        trailing: (type ==
              "assessment")
              ? const Tooltip(
                message: "Assessment",
                child: Icon(Icons.assessment_rounded),
              )
              : (type == "discussion") ? const Tooltip(
                message: "Discussion",
                child: Icon(Icons.message_rounded))
              : const Tooltip(
              message: "Assignment",
              child: Icon(Icons.assignment_rounded)
              ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      ),
    );
  }
}