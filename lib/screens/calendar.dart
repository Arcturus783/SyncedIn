import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:myapp/class_essentials/assignment.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/assignment_cards.dart';

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
    final selectedDay = DateTime.now();
    List<Assignment> aToday = widget.getEventsToday(selectedDay);
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
          return isSameDay(selectedDay, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            focusedDay = focusedDay;
            selectedDay = selectedDay;
            aToday = widget.getEventsToday(selectedDay);
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
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
        ),
      ),
      const SizedBox(height: 30),
      Expanded(
          child: ListView.builder(
              itemCount: aToday.length,
              itemBuilder: (BuildContext context, int index) {
                Assignment assignment = aToday[index];
                return CalendarCard(
                    color: const Color.fromARGB(225, 252, 252, 252),
                    title: assignment.title,
                    dueDate: assignment.dueDate,
                    aType: assignment.type.toLowerCase()
                );
              }
          )
      )
    ]);
  }
}
