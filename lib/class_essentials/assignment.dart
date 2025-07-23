import 'package:hive/hive.dart';

part 'assignment.g.dart';

@HiveType(typeId: 0)
class Assignment extends HiveObject{
  @HiveField(0)
  final String title;
  @HiveField(1)
  final DateTime? dueDate;
  @HiveField(2)
  final String type;
  @HiveField(3)
  bool completed;
  @HiveField(4)
  bool visible;

  Assignment({
    required this.title,
    required this.type,
    this.dueDate,
    required this.completed,
    required this.visible,
  });
}
