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

    // Reset credits if enough time has passed
    if (timeSinceReset >= _resetIntervalSeconds) {
      _remainingCredits = _maxCredits;
      _lastReset = now;
    }

    // If no credits available, wait for reset
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

  Map<String, List<Assignment>> assignments = {};
  int numCourses = 0;

  // Cache expiration settings
  static const int _cacheExpirationHours = 2;
  static const int _assignmentDayLimit = 90; // Only fetch assignments due within 90 days

  void loadAssignments() {
    Map<dynamic, dynamic> rawAssignments = hiveManager.box.get("assignments", defaultValue: {});
    assignments = _convertToTypedAssignments(rawAssignments);
    DateTime? lastFetch = hiveManager.box.get("lastAssignmentFetch");

    // Check if we need to refresh assignments
    bool shouldRefresh = _shouldRefreshAssignments(rawAssignments, lastFetch);

    if (shouldRefresh) {
      print("Cache expired or empty. Fetching fresh assignments...");
      getAssignments();
    } else {
      print("Using cached assignments (${assignments.length} courses)");
    }
  }

  bool _shouldRefreshAssignments(Map<dynamic, dynamic> rawAssignments, DateTime? lastFetch) {
    // Check if any course has assignments
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

      // Process courses sequentially to respect rate limits
      for (int i = 0; i < ids.length; i++) {
        print("Processing course ${i + 1}/${ids.length}: ${courses[i]}");

        try {
          await _fetchAssignments(ids[i], courses[i], authedClient);

          // Add delay between courses to be extra safe with rate limits
          if (i < ids.length - 1) {
            await Future.delayed(Duration(milliseconds: 300));
          }
        } catch (e) {
          print("Failed to fetch assignments for ${courses[i]}: $e");
          // Continue with other courses even if one fails
          continue;
        }
      }

      print("Assignment fetching complete. Total courses: ${assignments.length}");
      await hiveManager.box.put("assignments", assignments);
      await hiveManager.box.put("lastAssignmentFetch", DateTime.now());

    } catch (e) {
      print("Critical error in getAssignments: $e");
      rethrow;
    }
  }

  Future<void> getCourses() async {
    try {
      print("Fetching user courses...");
      final authedClient = _createAuthenticatedClient();

      // Get user ID
      await RateLimitManager.checkAndWait();
      final uidResponse = await authedClient
          .get(Uri.parse('https://api.schoology.com/v1/app-user-info/api_uid'));

      if (uidResponse.statusCode != 200) {
        throw Exception('Failed to get user ID: ${uidResponse.statusCode}');
      }

      Map<String, dynamic> uidJson = jsonDecode(uidResponse.body);
      dynamic uid = uidJson['api_uid'];

      // Get user sections
      await RateLimitManager.checkAndWait();
      final response = await authedClient
          .get(Uri.parse('https://api.schoology.com/v1/users/$uid/sections'));

      if (response.statusCode != 200) {
        throw Exception('Failed to get sections: ${response.statusCode}');
      }

      // Get user name
      await RateLimitManager.checkAndWait();
      final nameResponse = await authedClient
          .get(Uri.parse('https://api.schoology.com/v1/users/$uid'));

      if (nameResponse.statusCode != 200) {
        throw Exception('Failed to get user name: ${nameResponse.statusCode}');
      }

      // Process responses
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
    const int limit = 10; // Reduced from 20 to use fewer credits
    bool hasMore = true;
    List<Assignment> courseAssignments = [];
    const int maxRetries = 3; // Reduced max retries
    DateTime cutoffDate = DateTime.now().add(Duration(days: _assignmentDayLimit));

    int totalFetched = 0;
    int relevantAssignments = 0;

    while (hasMore && totalFetched < 200) { // Safety limit to prevent infinite loops
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

            // Filter and process assignments
            for (var a in assignments) {
              try {
                DateTime? dueDate;
                if (a['due'] != null && a['due'].toString().trim().isNotEmpty) {
                  dueDate = DateTime.parse(a['due']);

                  // Skip assignments that are too far in the future
                  if (dueDate.isAfter(cutoffDate)) {
                    continue;
                  }
                }

                courseAssignments.add(Assignment(
                  title: a["title"] ?? "Untitled Assignment",
                  dueDate: dueDate,
                  type: a['type'] ?? "assignment",
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
            Duration delay = Duration(seconds: 2 * retries); // Exponential backoff

            if (retryAfterHeader != null) {
              try {
                final seconds = int.parse(retryAfterHeader);
                delay = Duration(seconds: seconds + 1); // Add buffer
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

  List<Assignment> getAssignmentsForCourse(String courseName) {
    return assignments[courseName] ?? [];
  }

  // Utility method to force refresh assignments
  Future<void> forceRefreshAssignments() async {
    print("Force refreshing assignments...");
    assignments.clear();
    await hiveManager.box.delete("lastAssignmentFetch");
    await getAssignments();
  }

  // Get assignments across all courses
  List<Assignment> getAllAssignments() {
    List<Assignment> allAssignments = [];
    assignments.forEach((courseName, courseAssignments) {
      allAssignments.addAll(courseAssignments);
    });
    return allAssignments;
  }

  // Get upcoming assignments (due within next X days)
  List<Assignment> getUpcomingAssignments({int days = 7}) {
    DateTime cutoff = DateTime.now().add(Duration(days: days));
    return getAllAssignments()
        .where((assignment) =>
    assignment.dueDate != null &&
        assignment.dueDate!.isBefore(cutoff) &&
        assignment.dueDate!.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
  }

  // Assignment filtering methods

  List<Assignment> getAssignmentsDueToday() {
    DateTime now = DateTime.now();
    DateTime startOfToday = DateTime(now.year, now.month, now.day);
    DateTime endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return getAllAssignments()
        .where((assignment) =>
    assignment.dueDate != null &&
        assignment.dueDate!.isAfter(startOfToday.subtract(Duration(milliseconds: 1))) &&
        assignment.dueDate!.isBefore(endOfToday.add(Duration(milliseconds: 1))))
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
  }

  List<Assignment> getAssignmentsDueTomorrow() {
    DateTime now = DateTime.now();
    DateTime tomorrow = now.add(Duration(days: 1));
    DateTime startOfTomorrow = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    DateTime endOfTomorrow = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 23, 59, 59);

    return getAllAssignments()
        .where((assignment) =>
    assignment.dueDate != null &&
        assignment.dueDate!.isAfter(startOfTomorrow.subtract(Duration(milliseconds: 1))) &&
        assignment.dueDate!.isBefore(endOfTomorrow.add(Duration(milliseconds: 1))))
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
  }

  List<Assignment> getAssignmentsDueLaterThisWeek() {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime tomorrow = today.add(Duration(days: 1));

    // Find the end of this week (Sunday)
    int daysUntilSunday = 7 - now.weekday; // weekday: Monday = 1, Sunday = 7
    DateTime endOfWeek = today.add(Duration(days: daysUntilSunday));
    DateTime endOfSunday = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59);

    // Start from day after tomorrow
    DateTime startOfDayAfterTomorrow = tomorrow.add(Duration(days: 1));

    return getAllAssignments()
        .where((assignment) =>
    assignment.dueDate != null &&
        assignment.dueDate!.isAfter(startOfDayAfterTomorrow.subtract(Duration(milliseconds: 1))) &&
        assignment.dueDate!.isBefore(endOfSunday.add(Duration(milliseconds: 1))))
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
  }

  List<Assignment> getOverdueAssignments() {
    DateTime now = DateTime.now();
    DateTime startOfToday = DateTime(now.year, now.month, now.day);

    return getAllAssignments()
        .where((assignment) =>
    assignment.dueDate != null &&
        assignment.dueDate!.isBefore(startOfToday))
        .toList()
      ..sort((a, b) => b.dueDate!.compareTo(a.dueDate!)); // Most recently overdue first
  }

  List<Assignment> getOtherAssignments() {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    // Find the end of this week (Sunday)
    int daysUntilSunday = 7 - now.weekday;
    DateTime endOfWeek = today.add(Duration(days: daysUntilSunday));
    DateTime endOfSunday = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59);

    return getAllAssignments()
        .where((assignment) =>
    assignment.dueDate == null || // No due date
        assignment.dueDate!.isAfter(endOfSunday)) // Due after this week
        .toList()
      ..sort((a, b) {
        // Sort assignments with no due date to the end
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
  }

  // Get all assignments grouped by category
  Map<String, List<Assignment>> getAssignmentsByCategory() {
    return {
      'Due Today': getAssignmentsDueToday(),
      'Due Tomorrow': getAssignmentsDueTomorrow(),
      'Due Later This Week': getAssignmentsDueLaterThisWeek(),
      'Overdue': getOverdueAssignments(),
      'Other': getOtherAssignments(),
    };
  }

  // Helper methods for type conversion
  Map<String, List<Assignment>> _convertToTypedAssignments(Map<dynamic, dynamic> rawAssignments) {
    Map<String, List<Assignment>> typedAssignments = {};

    rawAssignments.forEach((key, value) {
      String courseName = key.toString();
      List<Assignment> courseAssignments = [];

      if (value is List) {
        // Since Assignment class uses Hive annotations, the objects are stored directly as Assignment instances
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