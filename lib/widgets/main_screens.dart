import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:myapp/class_essentials/assignment.dart';

/* This file keeps track of the main screens used in the app,
with the exception of the prototype "main" screen (the massive list
of assignments) and the initial log in screen (in main.dart).
 */

class SettingsScreen extends StatelessWidget{
  final Function(dynamic) logout;
  final Function(Color) changeColors;
  final Color currentColor;
  final List<Color> colorOptions;

  const SettingsScreen({
    super.key,
    required this.logout,
    required this.currentColor,
    required this.colorOptions,
    required this.changeColors,
  });

  @override
  Widget build(BuildContext context){
    return Center(
        child: Column(children: [
          const SizedBox(
            height: 100,
          ),
          const Text("Settings (button below is to logout)"),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              logout(context);
            },
          ),
          const Text(
            "Color Picker (saves color choice); Add like 8-16 choices",
          ),
          const SizedBox(height: 50),
          Expanded(
              child: BlockPicker(
                pickerColor: currentColor,
                availableColors: colorOptions,
                onColorChanged: changeColors,
              ))
        ]));
  }
}

class CalendarScreen extends StatefulWidget{
  final DateTime focusedDay;
  final Color currentColor;
  final Function(DateTime) getEventsToday;
  final Function(DateTime) getAssignmentsForDay;
  final List<Assignment> assignmentsPerDay;

  const CalendarScreen({
    super.key,
    required this.focusedDay,
    required this.currentColor,
    required this.assignmentsPerDay,
    required this.getEventsToday,
    required this.getAssignmentsForDay,
  });

  @override
  CalendarScreenState createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen>{
  @override
  void initState(){
    super.initState();
  }

  @override
  Widget build(BuildContext context){
    CalendarFormat calendarFormat = CalendarFormat.month;
    final _selectedDay = DateTime.now();
    widget.getEventsToday(_selectedDay);
    return Column(children: <Widget>[
      TableCalendar(
        availableCalendarFormats: const {CalendarFormat.month: "Month"},
        headerStyle: const HeaderStyle(
            titleCentered: true,
            titleTextStyle: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            )),
        firstDay: DateTime.utc(2025, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: widget.focusedDay,
        eventLoader: (day) {
          return widget.getEventsToday(day);
        },
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          widget.getAssignmentsForDay(selectedDay);
          setState(() {
            focusedDay = focusedDay;
            selectedDay = selectedDay;
          });
        },
        calendarFormat: calendarFormat,
        onFormatChanged: (format) {
          setState(() {
            calendarFormat = format;
          });
        },
        calendarStyle: CalendarStyle(
          //you can specify a font too for the calendar text here
          defaultTextStyle:
          const TextStyle(color: Color.fromARGB(255, 5, 5, 5)),
          markerSize: 7,
          //size of an event dot
          markersMaxCount: 3,
          //default is 4, looks crowded if they have 4+ assignments
          todayDecoration: BoxDecoration(
            color: Color.fromARGB(
                125, widget.currentColor.red, widget.currentColor.green, widget.currentColor.blue),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: widget.currentColor,
            shape: BoxShape.circle,
          ),
        ),
      ),
      const SizedBox(height: 30),
      Expanded(
          child: ListView.builder(
              itemCount: widget.assignmentsPerDay.length,
              itemBuilder: (BuildContext context, int index) {
                //return Text("1. ${assignmentsPerDay[index].title}");
                Assignment assignment = widget.assignmentsPerDay[index];
                return Card(
                    color: const Color.fromARGB(225, 252, 252, 252),
                    child: ListTile(
                      title: Text(
                        assignment.title,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      subtitle: Text(
                          "Due: ${assignment.dueDate.split(" ")[0]}\n${assignment.dueDate.split(" ")[1]}"),
                      trailing: (assignment.type == "assessment")
                          ? const Tooltip(
                        message: "Assessment",
                        child: Icon(Icons.assessment_rounded),
                      )
                          : (assignment.type == "discussion")
                          ? const Tooltip(
                          message: "Discussion",
                          child: Icon(Icons.message_rounded))
                          : const Tooltip(
                          message: "Assignment",
                          child: Icon(Icons.assignment_rounded)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 4.0),
                    ));
              }))
    ]);
  }
}