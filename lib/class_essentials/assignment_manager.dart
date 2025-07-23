import 'hive.dart';
import 'assignment.dart';
import 'package:oauth1/oauth1.dart' as oauth1;
import 'dart:convert';

class RateLimitManager {
  static int _remainingCredits = 50;
  static DateTime _lastReset = DateTime.now();
  static const int _maxCredits = 50;
  static const int _resetIntervalSeconds = 5;

  static Future<void> checkAndWait() async {
    final now = DateTime.now();
    final timeSinceReset = now.difference(_lastReset).inSeconds;

    if (timeSinceReset >= _resetIntervalSeconds) {
      _remainingCredits = _maxCredits;
      _lastReset = now;
    }

    if (_remainingCredits <= 0) {
      final waitTime = _resetIntervalSeconds - timeSinceReset;
      if (waitTime > 0) {
        print("Rate limit reached. Waiting ${waitTime}s for reset...");
        await Future.delayed(Duration(seconds: waitTime));
        _remainingCredits = _maxCredits;
        _lastReset = DateTime.now();
      }
    }

    _remainingCredits--;
    print("Credits remaining: $_remainingCredits");
  }

  static void consumeCredit() {
    if (_remainingCredits > 0) {
      _remainingCredits--;
    }
  }

  static int get remainingCredits => _remainingCredits;
}

class AssignmentManager {
  final HiveBoxManager hiveManager;
  final String oToken;
  final String oSecret;

  AssignmentManager(this.hiveManager, this.oToken, this.oSecret);

  // Original course-based storage for reference
  Map<String, List<Assignment>> assignments = {};

  // NEW: Date-sorted list for efficient lookups
  List<Assignment> _sortedAssignments = [];

  // Index mapping for quick course-based access
  Map<String, List<int>> _courseIndexes = {};

  int numCourses = 0;

  // Cache expiration settings
  static const int _cacheExpirationHours = 2;
  static const int _assignmentDayLimit = 90;

  // Data retention settings
  static const int _oldAssignmentThresholdDays = 30; // Keep assignments from last 30 days
  static const int _futureAssignmentLimitDays = 365; // Keep assignments up to 1 year ahead

  void loadAssignments() {
    Map<dynamic, dynamic> rawAssignments = hiveManager.box.get("assignments", defaultValue: {});
    assignments = _convertToTypedAssignments(rawAssignments);
    DateTime? lastFetch = hiveManager.box.get("lastAssignmentFetch");

    // Build optimized data structures
    _buildOptimizedStructures();

    bool shouldRefresh = _shouldRefreshAssignments(rawAssignments, lastFetch);

    if (shouldRefresh) {
      print("Cache expired or empty. Fetching fresh assignments...");
      getAssignments();
    } else {
      print("Using cached assignments (${assignments.length} courses, ${_sortedAssignments.length} total assignments)");
    }
  }

  void saveAssignments()async{
    await hiveManager.box.put("assignments", assignments);
  }

  /// Build the optimized data structures for fast lookups
  void _buildOptimizedStructures() {
    _sortedAssignments.clear();
    _courseIndexes.clear();

    // Define relevance window
    DateTime now = DateTime.now();
    DateTime oldThreshold = now.subtract(Duration(days: _oldAssignmentThresholdDays));
    DateTime futureThreshold = now.add(Duration(days: _futureAssignmentLimitDays));

    // Collect relevant assignments with course information
    List<_AssignmentWithCourse> allWithCourse = [];
    int totalAssignments = 0;
    int filteredAssignments = 0;

    assignments.forEach((courseName, courseAssignments) {
      totalAssignments += courseAssignments.length;

      for (int i = 0; i < courseAssignments.length; i++) {
        Assignment assignment = courseAssignments[i];

        // Keep assignment if:
        // 1. No due date (important assignments)
        // 2. Due within our retention window
        // 3. Due in reasonable future
        bool shouldKeep = assignment.dueDate == null ||
            (assignment.dueDate!.isAfter(oldThreshold) &&
                assignment.dueDate!.isBefore(futureThreshold));

        if (shouldKeep) {
          allWithCourse.add(_AssignmentWithCourse(
            assignment: assignment,
            courseName: courseName,
          ));
          filteredAssignments++;
        }
      }
    });

    // Sort by due date (null dates go to end)
    allWithCourse.sort((a, b) {
      if (a.assignment.dueDate == null && b.assignment.dueDate == null) return 0;
      if (a.assignment.dueDate == null) return 1;
      if (b.assignment.dueDate == null) return -1;
      return a.assignment.dueDate!.compareTo(b.assignment.dueDate!);
    });

    // Build sorted list and course indexes
    for (int i = 0; i < allWithCourse.length; i++) {
      final item = allWithCourse[i];
      _sortedAssignments.add(item.assignment);

      // Track indexes by course
      _courseIndexes.putIfAbsent(item.courseName, () => []).add(i);
    }

    print("Built optimized structures: ${_sortedAssignments.length}/${totalAssignments} assignments " +
        "kept (filtered ${totalAssignments - filteredAssignments} old/distant assignments)");

    // Log memory usage estimate
    double estimatedMB = (filteredAssignments * 0.5) / 1024; // Rough estimate: 0.5KB per assignment
    print("Estimated memory usage: ${estimatedMB.toStringAsFixed(2)} MB");
  }

  bool _shouldRefreshAssignments(Map<dynamic, dynamic> rawAssignments, DateTime? lastFetch) {
    bool hasAnyAssignments = false;
    rawAssignments.forEach((key, value) {
      if (value is List && value.isNotEmpty) {
        hasAnyAssignments = true;
      }
    });

    return !hasAnyAssignments ||
        lastFetch == null ||
        DateTime.now().difference(lastFetch).inHours > _cacheExpirationHours;
  }

  Future<void> getAssignments() async {
    try {
      List<dynamic> ids = hiveManager.box.get("ids", defaultValue: []);
      if (ids.isEmpty) await getCourses();

      final authedClient = _createAuthenticatedClient();
      List<dynamic> courses = hiveManager.box.get("courses", defaultValue: []);

      print("Starting to fetch assignments for ${ids.length} courses...");

      for (int i = 0; i < ids.length; i++) {
        print("Processing course ${i + 1}/${ids.length}: ${courses[i]}");

        try {
          await _fetchAssignments(ids[i], courses[i], authedClient);

          if (i < ids.length - 1) {
            await Future.delayed(const Duration(milliseconds: 300));
          }
        } catch (e) {
          print("Failed to fetch assignments for ${courses[i]}: $e");
          continue;
        }
      }

      print("Assignment fetching complete. Total courses: ${assignments.length}");
      await hiveManager.box.put("assignments", assignments);
      await hiveManager.box.put("lastAssignmentFetch", DateTime.now());

      // Rebuild optimized structures after fetching
      _buildOptimizedStructures();

    } catch (e) {
      print("Critical error in getAssignments: $e");
      rethrow;
    }
  }

  // EXISTING METHODS (getCourses, _fetchAssignments, etc.) remain the same...
  Future<void> getCourses() async {
    try {
      print("Fetching user courses...");
      final authedClient = _createAuthenticatedClient();

      await RateLimitManager.checkAndWait();
      final uidResponse = await authedClient
          .get(Uri.parse('https://api.schoology.com/v1/app-user-info/api_uid'));

      if (uidResponse.statusCode != 200) {
        throw Exception('Failed to get user ID: ${uidResponse.statusCode}');
      }

      Map<String, dynamic> uidJson = jsonDecode(uidResponse.body);
      dynamic uid = uidJson['api_uid'];

      await RateLimitManager.checkAndWait();
      final response = await authedClient
          .get(Uri.parse('https://api.schoology.com/v1/users/$uid/sections'));

      if (response.statusCode != 200) {
        throw Exception('Failed to get sections: ${response.statusCode}');
      }

      await RateLimitManager.checkAndWait();
      final nameResponse = await authedClient
          .get(Uri.parse('https://api.schoology.com/v1/users/$uid'));

      if (nameResponse.statusCode != 200) {
        throw Exception('Failed to get user name: ${nameResponse.statusCode}');
      }

      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      Map<String, dynamic> jsonNameResponse = jsonDecode(nameResponse.body);
      List<dynamic> sections = jsonResponse['section'] ?? [];

      if (sections.isEmpty) {
        print("No sections found for user");
        return;
      }

      List<dynamic> courseTitles =
      sections.map((section) => section['course_title']).toList();
      List<dynamic> courseIds =
      sections.map((section) => section['id']).toList();

      print("Found ${courseTitles.length} courses: $courseTitles");

      await hiveManager.box.put("courses", courseTitles);
      await hiveManager.box.put("ids", courseIds);
      await hiveManager.box.put("name", jsonNameResponse['name_first']);
      numCourses = courseTitles.length;

    } catch (e) {
      print("Error fetching courses: $e");
      rethrow;
    }
  }

  Future<void> _fetchAssignments(
      String id, String courseName, oauth1.Client authedClient) async {
    print("Fetching assignments for: $courseName");

    int start = 0;
    const int limit = 25; // Adjusted limit for better performance
    bool hasMore = true;
    List<Assignment> courseAssignments = [];
    const int maxRetries = 3;
    DateTime cutoffDate = DateTime.now().add(Duration(days: _assignmentDayLimit));

    int totalFetched = 0;
    int relevantAssignments = 0;

    while (hasMore && totalFetched < 200) {
      int retries = 0;
      bool requestSuccessful = false;

      while (!requestSuccessful && retries < maxRetries) {
        try {
          await RateLimitManager.checkAndWait();

          final response = await authedClient.get(Uri.parse(
              'https://api.schoology.com/v1/sections/$id/assignments?start=$start&limit=$limit'));

          if (response.statusCode == 200) {
            Map<String, dynamic> data = jsonDecode(response.body);
            List<dynamic> assignments = data['assignment'] ?? [];
            totalFetched += assignments.length;

            if (assignments.isEmpty) {
              hasMore = false;
              requestSuccessful = true;
              break;
            }

            for (var a in assignments) {
              try {
                DateTime? dueDate;
                if (a['due'] != null && a['due'].toString().trim().isNotEmpty) {
                  dueDate = DateTime.parse(a['due']);

                  if (dueDate.isAfter(cutoffDate)) {
                    continue;
                  }
                }

                courseAssignments.add(Assignment(
                  title: a["title"] ?? "Untitled Assignment",
                  dueDate: dueDate,
                  type: a['type'] ?? "assignment",
                  completed: a['completed'] == 1,
                  visible: true,
                ));
                relevantAssignments++;

              } catch (e) {
                print("Error processing assignment in $courseName: $e");
                continue;
              }
            }

            start += limit;
            requestSuccessful = true;

          } else if (response.statusCode == 429) {
            retries++;
            final retryAfterHeader = response.headers['retry-after'];
            Duration delay = Duration(seconds: 2 * retries);

            if (retryAfterHeader != null) {
              try {
                final seconds = int.parse(retryAfterHeader);
                delay = Duration(seconds: seconds + 1);
              } catch (e) {
                print("Failed to parse Retry-After header: $e");
              }
            }

            print("Rate limited for $courseName. Retry $retries/$maxRetries in ${delay.inSeconds}s");
            await Future.delayed(delay);

          } else {
            throw Exception('HTTP ${response.statusCode}: ${response.body}');
          }

        } catch (e) {
          retries++;
          if (retries >= maxRetries) {
            print("Max retries exceeded for $courseName: $e");
            hasMore = false;
            break;
          }

          print("Request failed for $courseName (attempt $retries): $e");
          await Future.delayed(Duration(seconds: retries * 2));
        }
      }

      if (!requestSuccessful) {
        print("Failed to fetch assignments for $courseName after $maxRetries retries");
        break;
      }
    }

    assignments[courseName] = courseAssignments;
    print("Fetched $relevantAssignments relevant assignments for $courseName (total processed: $totalFetched)");
  }

  oauth1.Client _createAuthenticatedClient() {
    const String schoologyDomain = "schoology.coppellisd.com";
    final oauth1.Platform platform = oauth1.Platform(
        'https://api.schoology.com/v1/oauth/request_token',
        'https://$schoologyDomain/oauth/authorize',
        'https://api.schoology.com/v1/oauth/access_token',
        oauth1.SignatureMethods.hmacSha1);

    const String consK = "4228fad5be57913f4a288c71007cce38066a6a9c6";
    const String consS = "f16aa4e412861b3be29314970e2740ba";

    final oauth1.ClientCredentials clientCredentials =
    oauth1.ClientCredentials(consK, consS);

    return oauth1.Client(platform.signatureMethod,
        clientCredentials, oauth1.Credentials(oToken, oSecret));
  }



  // ==============================================================================
  // NEW OPTIMIZED QUERY METHODS USING BINARY SEARCH
  // ==============================================================================

  /// Get assignments for a specific date - O(log n) complexity
  List<Assignment> getAssignmentsForDate(DateTime date) {
    if (_sortedAssignments.isEmpty) return [];

    DateTime startOfDay = DateTime(date.year, date.month, date.day);
    DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _getAssignmentsInRange(startOfDay, endOfDay);
  }

  /// Get assignments for a date range - O(log n) complexity
  List<Assignment> getAssignmentsInDateRange(DateTime startDate, DateTime endDate) {
    return _getAssignmentsInRange(startDate, endDate);
  }

  /// Get assignments for entire month - optimized for calendar view
  /// Returns Map<day, assignments> for efficient calendar rendering
  Map<int, List<Assignment>> getAssignmentsForMonth(int year, int month) {
    DateTime monthStart = DateTime(year, month, 1);
    DateTime monthEnd = DateTime(year, month + 1, 0, 23, 59, 59);

    List<Assignment> monthAssignments = _getAssignmentsInRange(monthStart, monthEnd);

    // Group by day of month for calendar view
    Map<int, List<Assignment>> dayGroups = {};
    for (Assignment assignment in monthAssignments) {
      if (assignment.dueDate != null) {
        int day = assignment.dueDate!.day;
        dayGroups.putIfAbsent(day, () => []).add(assignment);
      }
    }

    print("Calendar query for $year-$month: ${monthAssignments.length} assignments across ${dayGroups.length} days");
    return dayGroups;
  }

  /// Get assignment count for each day in a month (lightweight for calendar previews)
  Map<int, int> getAssignmentCountsForMonth(int year, int month) {
    Map<int, List<Assignment>> dayAssignments = getAssignmentsForMonth(year, month);
    return dayAssignments.map((day, assignments) => MapEntry(day, assignments.length));
  }

  /// Get assignments for a week starting from the given date
  Map<DateTime, List<Assignment>> getAssignmentsForWeek(DateTime weekStart) {
    DateTime weekEnd = weekStart.add(const Duration(days: 7));
    List<Assignment> weekAssignments = _getAssignmentsInRange(weekStart, weekEnd);

    Map<DateTime, List<Assignment>> dayGroups = {};
    for (Assignment assignment in weekAssignments) {
      if (assignment.dueDate != null) {
        DateTime dayKey = DateTime(
            assignment.dueDate!.year,
            assignment.dueDate!.month,
            assignment.dueDate!.day
        );
        dayGroups.putIfAbsent(dayKey, () => []).add(assignment);
      }
    }

    return dayGroups;
  }

  /// Core binary search method for date ranges
  List<Assignment> _getAssignmentsInRange(DateTime startDate, DateTime endDate) {
    if (_sortedAssignments.isEmpty) return [];

    // Find first assignment >= startDate
    int startIndex = _findFirstAssignmentAtOrAfter(startDate);
    if (startIndex == -1) return [];

    // Find first assignment > endDate
    int endIndex = _findFirstAssignmentAfter(endDate);
    if (endIndex == -1) endIndex = _sortedAssignments.length;

    // Return slice
    return _sortedAssignments.sublist(startIndex, endIndex);
  }

  /// Binary search for first assignment at or after target date
  int _findFirstAssignmentAtOrAfter(DateTime targetDate) {
    int left = 0;
    int right = _sortedAssignments.length - 1;
    int result = -1;

    while (left <= right) {
      int mid = left + (right - left) ~/ 2;
      Assignment assignment = _sortedAssignments[mid];

      if (assignment.dueDate == null) {
        // Null dates are at the end, search left
        right = mid - 1;
      } else if (assignment.dueDate!.compareTo(targetDate) >= 0) {
        result = mid;
        right = mid - 1; // Look for earlier match
      } else {
        left = mid + 1;
      }
    }

    return result;
  }

  /// Binary search for first assignment after target date
  int _findFirstAssignmentAfter(DateTime targetDate) {
    int left = 0;
    int right = _sortedAssignments.length - 1;
    int result = -1;

    while (left <= right) {
      int mid = left + (right - left) ~/ 2;
      Assignment assignment = _sortedAssignments[mid];

      if (assignment.dueDate == null) {
        right = mid - 1;
      } else if (assignment.dueDate!.compareTo(targetDate) > 0) {
        result = mid;
        right = mid - 1;
      } else {
        left = mid + 1;
      }
    }

    return result;
  }

  // ==============================================================================
  // OPTIMIZED CONVENIENCE METHODS
  // ==============================================================================

  List<Assignment> getAssignmentsDueToday() {
    return getAssignmentsForDate(DateTime.now());
  }

  List<Assignment> getAssignmentsDueTomorrow() {
    return getAssignmentsForDate(DateTime.now().add(const Duration(days: 1)));
  }

  List<Assignment> getUpcomingAssignments({int days = 7}) {
    DateTime now = DateTime.now();
    DateTime cutoff = now.add(Duration(days: days));
    return _getAssignmentsInRange(now, cutoff);
  }

  List<Assignment> getOverdueAssignments() {
    DateTime now = DateTime.now();
    DateTime startOfToday = DateTime(now.year, now.month, now.day);

    // Get all assignments before today
    int endIndex = _findFirstAssignmentAtOrAfter(startOfToday);
    if (endIndex == -1) return _sortedAssignments.where((a) => a.dueDate != null).toList();

    return _sortedAssignments.sublist(0, endIndex).reversed.toList(); // Most recent first
  }

  List<Assignment> getAssignmentsDueLaterThisWeek() {
    DateTime now = DateTime.now();
    DateTime dayAfterTomorrow = DateTime(now.year, now.month, now.day + 2);

    // Find end of week (Sunday)
    int daysUntilSunday = 7 - now.weekday;
    DateTime endOfWeek = DateTime(now.year, now.month, now.day + daysUntilSunday, 23, 59, 59);

    return _getAssignmentsInRange(dayAfterTomorrow, endOfWeek);
  }

  // ==============================================================================
  // LEGACY METHODS (maintained for compatibility)
  // ==============================================================================

  List<Assignment> getAssignmentsForCourse(String courseName) {
    return assignments[courseName] ?? [];
  }

  Future<void> forceRefreshAssignments() async {
    print("Force refreshing assignments...");
    assignments.clear();
    _sortedAssignments.clear();
    _courseIndexes.clear();
    await hiveManager.box.delete("lastAssignmentFetch");
    await getAssignments();
  }

  List<Assignment> getAllAssignments() {
    return List.from(_sortedAssignments); // Return copy to prevent external modification
  }

  Map<String, List<Assignment>> getAssignmentsByCategory() {
    return {
      'Due Today': getAssignmentsDueToday(),
      'Due Tomorrow': getAssignmentsDueTomorrow(),
      'Due Later This Week': getAssignmentsDueLaterThisWeek(),
      'Overdue': getOverdueAssignments(),
      'Other': getOtherAssignments(),
    };
  }

  List<Assignment> getOtherAssignments() {
    DateTime now = DateTime.now();
    int daysUntilSunday = 7 - now.weekday;
    DateTime endOfWeek = DateTime(now.year, now.month, now.day + daysUntilSunday, 23, 59, 59);

    // Get assignments after this week + assignments with no due date
    List<Assignment> afterThisWeek = [];
    List<Assignment> noDueDate = [];

    for (Assignment assignment in _sortedAssignments) {
      if (assignment.dueDate == null) {
        noDueDate.add(assignment);
      } else if (assignment.dueDate!.isAfter(endOfWeek)) {
        afterThisWeek.add(assignment);
      }
    }

    return [...afterThisWeek, ...noDueDate];
  }

  Map<String, List<Assignment>> _convertToTypedAssignments(Map<dynamic, dynamic> rawAssignments) {
    Map<String, List<Assignment>> typedAssignments = {};

    rawAssignments.forEach((key, value) {
      String courseName = key.toString();
      List<Assignment> courseAssignments = [];

      if (value is List) {
        for (var item in value) {
          if (item is Assignment) {
            courseAssignments.add(item);
          }
        }
      }

      typedAssignments[courseName] = courseAssignments;
      print("Loaded ${courseAssignments.length} assignments for course: $courseName");
    });

    return typedAssignments;
  }
}

/// Helper class for building optimized structures
class _AssignmentWithCourse {
  final Assignment assignment;
  final String courseName;

  _AssignmentWithCourse({required this.assignment, required this.courseName});
}