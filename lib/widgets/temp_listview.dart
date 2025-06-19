/*
//need to work on rebuilding the widgets when dismissing assignments - due date disappearing
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/assignment_cards.dart';
import '../class_essentials/assignment.dart';
import '../class_essentials/hive.dart';
import 'package:myapp/class_essentials/theme.dart';

class LargeListView extends StatefulWidget{
  final String name;
  final AnimationController animationController;
  final Animation<Offset> slideOutAnimation;
  final Animation<Offset> slideInAnimation;
  final Map<String, List<Assignment>> assignments; //maps courses to a list of assignments per course
  final Color currentColor;
  final List<Assignment> disA;
  final HiveBoxManager hiveManager;

  const LargeListView({
    super.key,
    required this.name,
    required this.animationController,
    required this.slideOutAnimation,
    required this.slideInAnimation,
    required this.assignments,
    required this.currentColor,
    required this.disA,
    required this.hiveManager,
  });

  @override
  LargeListViewState createState() => LargeListViewState();
}

class LargeListViewState extends State<LargeListView>{
  @override
  void initState(){
    super.initState();
  }

  @override
  Widget build(BuildContext context){
    //all these variables just save the time of having to write out widget.variable instead of variable
    //that's only for this class because it's super long (and likely temporary)
    String name = widget.name;
    AnimationController animationController = widget.animationController;
    Animation<Offset> slideOutAnimation = widget.slideOutAnimation;
    Animation<Offset> slideInAnimation = widget.slideInAnimation;
    Map<String, List<Assignment>> assignments = widget.assignments; //maps courses to a list of assignments per course
    Color currentColor = widget.currentColor;
    List<Assignment> disA = widget.disA;
    HiveBoxManager hiveManager = widget.hiveManager;
    bool showHiddenAssignments = false;

    return Column(
      children: <Widget>[
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 25, 0, 10),
                    child: Text("Hello $name!",
                        textAlign: TextAlign.left,
                        style: GoogleFonts.redHatDisplay(
                          textStyle: const TextStyle(
                              fontSize: 30, fontWeight: FontWeight.w700),
                        )),
                  )),
              Padding(
                  padding: const EdgeInsets.fromLTRB(0, 18, 10, 0),
                  child: IconButton(
                      icon: const Icon(Icons.hide_image_rounded),
                      iconSize: 30,
                      onPressed: () {
                        setState(() {
                          showHiddenAssignments = !showHiddenAssignments;
                          if (showHiddenAssignments) {
                            animationController.forward();
                          } else {
                            animationController.reverse();
                          }
                        });
                      })),
            ]),
        // Main content area - lists all the courses AND assignments (think of the itemBuilders like nested for loops)

        Expanded(
            child: Stack(children: [
              SlideTransition(
                position: slideOutAnimation,
                child: assignments.isEmpty
                    ? const Center(child: Text("No assignments to display"))
                    : ListView.builder(
                  itemCount: assignments.length,
                  //this iterates and displays each individual course
                  itemBuilder: (BuildContext context, int courseIndex) {
                    String courseTitle =
                    assignments.keys.elementAt(courseIndex);
                    List<Assignment> courseAssignments =
                        assignments[courseTitle] ?? [];
                    // Pre-filter assignments
                    List<Assignment> currentMonthAssignments =
                    courseAssignments.where((assignment) {
                      if (assignment.dueDate == null || assignment.dueDate.toString().trim().isEmpty) return true;
                      try {
                        DateTime dueDate = assignment.dueDate;
                        DateTime now = DateTime.now();
                        return dueDate.day == now.day ||
                            dueDate ==
                                DateTime(now.year, now.month, now.day + 1);
                      } catch (e) {
                        return true; // Include assignments with invalid dates
                      }
                    }).toList();

                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      color: Theme.of(context).colorScheme.primary,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              courseTitle,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          if (currentMonthAssignments.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(
                                  child:
                                  Text("No assignments for this course")),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: currentMonthAssignments.length,
                              itemBuilder: (BuildContext context, int index) {
                                Assignment assignment =
                                currentMonthAssignments[index];
                                if (!disA.contains(
                                    assignment) /*!dismissedAssignments.contains(assignment.title)*/) {
                                  if (assignment.dueDate.toString().trim().isEmpty) {
                                    //this allows the user to slide and remove an assignment
                                    return Dismissible(
                                        key: Key(assignment.title),
                                        direction:
                                        DismissDirection.endToStart,
                                        onDismissed: (direction) {
                                          setState(() {
                                            currentMonthAssignments
                                                .removeAt(index);
                                            // Find the actual index in the full assignments list
                                            final fullListIndex =
                                            assignments[courseTitle]
                                                ?.indexWhere((a) =>
                                            a.title ==
                                                assignment.title);
                                            if (fullListIndex != null &&
                                                fullListIndex != -1) {
                                              assignments[courseTitle]
                                                  ?.removeAt(fullListIndex);
                                            }
                                            //dismissedAssignments.add(assignment.title);
                                            disA.add(assignment);
                                          });
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  '${assignment.title} removed'),
                                              action: SnackBarAction(
                                                label: 'UNDO',
                                                onPressed: () {
                                                  setState(() {
                                                    assignments[courseTitle]?.add(
                                                        assignment); // Just add to the end
                                                    //dismissedAssignments.remove(assignment.title);
                                                    disA.remove(assignment);
                                                    //hiveManager.box.put("dismissedAssignments", dismissedAssignments);
                                                    disA.add(assignment);
                                                  });
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                        child: LargeListCard(dueDate: assignment.dueDate, invalidDate: false, title: assignment.title, type: assignment.type, color: const Color.fromARGB(225, 252, 252, 252))
                                    );
                                  }
                                  try {
                                    return Dismissible(
                                        key: Key(assignment.title),
                                        direction:
                                        DismissDirection.endToStart,
                                        onDismissed: (direction) {
                                          setState(() {
                                            currentMonthAssignments
                                                .removeAt(index);
                                            // Find the actual index in the full assignments list
                                            final fullListIndex =
                                            assignments[courseTitle]
                                                ?.indexWhere((a) =>
                                            a.title ==
                                                assignment.title);
                                            if (fullListIndex != null &&
                                                fullListIndex != -1) {
                                              assignments[courseTitle]
                                                  ?.removeAt(fullListIndex);
                                            }
                                            //dismissedAssignments.add(assignment.title);
                                            disA.add(assignment);
                                            //hiveManager.box.put("dismissedAssignments", dismissedAssignments);
                                            hiveManager.box.put("disA", disA);
                                          });
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  '${assignment.title} removed'),
                                              action: SnackBarAction(
                                                label: 'UNDO',
                                                onPressed: () {
                                                  setState(() {
                                                    assignments[courseTitle]?.add(
                                                        assignment); // Just add to the end
                                                    disA.remove(assignment);
                                                    //dismissedAssignments.remove(assignment.title);
                                                    //hiveManager.box.put("dismissedAssignments", dismissedAssignments);
                                                    hiveManager.box
                                                        .put("disA", disA);
                                                  });
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                        child: LargeListCard(dueDate: assignment.dueDate, invalidDate: false, title: assignment.title, type: assignment.type, color: const Color.fromARGB(225, 252, 252, 252))
                                    );
                                  } catch (e) {
                                    return Tooltip(
                                        message: assignment.dueDate,
                                        child: LargeListCard(dueDate: assignment.dueDate, invalidDate: true, title: assignment.title, type: assignment.type, color: const Color.fromARGB(225, 252, 252, 252))
                                    );
                                  }
                                } else {
                                  return Container();
                                }
                              },
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SlideTransition(
                  position: slideInAnimation,
                  child: Center(
                      child: /* dismissedAssignments.isEmpty || (dismissedAssignments.length == 1 && dismissedAssignments[0] == "") */
                      (disA.isEmpty ||
                          (disA.length == 1 && disA[0].title == ""))
                          ? const Text("No dismissed assignments")
                          : ListView.builder(
                          itemCount: disA.length,
                          itemBuilder:
                              (BuildContext context, int dismissedIndex) {
                            //String assignment = dismissedAssignments[dismissedIndex];
                            Assignment as = disA[dismissedIndex];
                            if (as.title.trim().isNotEmpty) {
                              return Dismissible(
                                  key: Key(as.title),
                                  direction: DismissDirection.endToStart,
                                  onDismissed: (direction) {
                                    Assignment? originalAssignment;
                                    String? originalCourse;

                                    for (var course in assignments.keys) {
                                      var courseAssignments =
                                      assignments[course];
                                      if (courseAssignments != null) {
                                        for (var a in courseAssignments) {
                                          if (a.title == as.title) {
                                            originalAssignment = a;
                                            originalCourse = course;
                                            break;
                                          }
                                        }
                                        if (originalAssignment != null) {
                                          break;
                                        }
                                      }
                                    }
                                    setState(() {
                                      //dismissedAssignments.remove(assignment);
                                      disA.remove(as);
                                      if (originalCourse != null &&
                                          originalAssignment != null) {
                                        assignments[originalCourse]
                                            ?.add(originalAssignment);
                                      }
                                      //hiveManager.box.put("dismissedAssignments", dismissedAssignments);
                                      hiveManager.box.put("disA", disA);
                                    });
                                  },
                                  child: Card(
                                      color: const Color.fromARGB(
                                          200, 244, 244, 244),
                                      child: ListTile(
                                        title: Text(
                                          //assignment,
                                          as.title,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                        //subtitle: Text("Due: ${assignment.dueDate.split(" ")[0]}\n${assignment.dueDate.split(" ")[1]}"),
                                        contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 16.0,
                                            vertical: 4.0),
                                      )));
                            } else {
                              return Container();
                            }
                          })))
            ]))
      ],
    );
  }
}
*/