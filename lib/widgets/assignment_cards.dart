import 'package:flutter/material.dart';
//this will hold the code for assignment cards across different screens

class CalendarCard extends StatelessWidget{
  final Color color;
  final String title;
  final DateTime? dueDate;
  final String aType; //assignment type (discussion, assessment, etc.)

  const CalendarCard({
    super.key,
    required this.color,
    required this.title,
    this.dueDate,
    required this.aType,
  });

  @override
  Widget build(BuildContext context){
    String date = dueDate != null ? dueDate.toString().split(" ")[0].trim() : "No Due Date";
    String time = dueDate != null ? dueDate.toString().split(" ")[1].trim() : "";
    return Card(
      color: const Color.fromARGB(225, 252, 252, 252),
      child: ListTile(
      title: Text(
        title,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
        subtitle: Text("Due: $date\n$time"),
        trailing: (aType == "assessment")
        ? const Tooltip(
            message: "Assessment",
            child: Icon(Icons.assessment_rounded),
          )
          : (aType == "discussion")
          ? const Tooltip(
            message: "Discussion",
            child: Icon(Icons.message_rounded)
          )
          : const Tooltip(
              message: "Assignment",
              child: Icon(Icons.assignment_rounded)
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        )
    );
  }
}

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