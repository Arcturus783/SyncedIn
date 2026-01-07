import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CourseSelectionScreen extends StatefulWidget {
  final List<dynamic> allCourses;
  final List<dynamic> allCourseIds;
  final Future<void> Function(List<dynamic> selectedCourses, List<dynamic> selectedIds) onConfirm; // Changed to Future<void>

  const CourseSelectionScreen({
    super.key,
    required this. allCourses,
    required this.allCourseIds,
    required this.onConfirm,
  });

  @override
  State<CourseSelectionScreen> createState() => _CourseSelectionScreenState();
}

class _CourseSelectionScreenState extends State<CourseSelectionScreen> {
  final Set<int> _selectedIndices = {};
  static const int maxCourses = 15;

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedIndices.length;
    final canConfirm = selectedCount > 0 && selectedCount <= maxCourses;

    return Scaffold(
      backgroundColor: const Color. fromARGB(255, 248, 248, 245),
      appBar: AppBar(
        backgroundColor: const Color. fromARGB(255, 253, 115, 12),
        elevation: 0,
        title:  Text(
          'Select Your Courses',
          style: GoogleFonts.figtree(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors. white,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header card with instructions
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors:  [
                  const Color.fromARGB(255, 253, 115, 12),
                  const Color.fromARGB(255, 253, 115, 12).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(255, 253, 115, 12).withOpacity(0.3),
                  blurRadius:  12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Course Limit',
                      style: GoogleFonts.figtree(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors. white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'You have ${widget.allCourses.length} courses.  Please select up to $maxCourses courses to continue. To change courses later, simply sign out of your account.',
                  style: GoogleFonts.figtree(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.95),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Selected: $selectedCount / $maxCourses',
                  style: GoogleFonts. figtree(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Course list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.allCourses.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedIndices.contains(index);
                final courseName = widget.allCourses[index]. toString();

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: isSelected ? 4 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected
                          ? const Color.fromARGB(255, 253, 115, 12)
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: CheckboxListTile(
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          if (_selectedIndices.length < maxCourses) {
                            _selectedIndices.add(index);
                          } else {
                            // Show snackbar when limit reached
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Maximum $maxCourses courses allowed',
                                  style: GoogleFonts.figtree(),
                                ),
                                backgroundColor: const Color.fromARGB(255, 230, 20, 40),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        } else {
                          _selectedIndices.remove(index);
                        }
                      });
                    },
                    title:  Text(
                      courseName,
                      style: GoogleFonts.figtree(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: const Color.fromARGB(255, 33, 33, 33),
                      ),
                    ),
                    activeColor: const Color.fromARGB(255, 253, 115, 12),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom action bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius:  8,
                  offset:  const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (! canConfirm && selectedCount > maxCourses)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Please deselect ${selectedCount - maxCourses} course(s)',
                        style: GoogleFonts.figtree(
                          color: const Color.fromARGB(255, 230, 20, 40),
                          fontWeight: FontWeight. w600,
                        ),
                      ),
                    ),
                  if (! canConfirm && selectedCount == 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Please select at least one course',
                        style:  GoogleFonts.figtree(
                          color: const Color.fromARGB(255, 230, 20, 40),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  SizedBox(
                    width:  double.infinity,
                    child: ElevatedButton(
                      onPressed: canConfirm ?  _handleConfirm : null,
                      style: ElevatedButton. styleFrom(
                        backgroundColor:  const Color.fromARGB(255, 253, 115, 12),
                        disabledBackgroundColor: Colors. grey.shade300,
                        foregroundColor: Colors.white,
                        elevation: canConfirm ? 4 :  0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Confirm Selection',
                        style: GoogleFonts.figtree(
                          fontSize: 16,
                          fontWeight:  FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleConfirm() async {
    if (_selectedIndices. isEmpty || _selectedIndices.length > maxCourses) {
      return;
    }

    // Create lists of selected courses and IDs
    final selectedCourses = _selectedIndices
        . map((index) => widget.allCourses[index])
        .toList();
    final selectedIds = _selectedIndices
        .map((index) => widget.allCourseIds[index])
        .toList();

    // Call the callback and wait for it
    await widget.onConfirm(selectedCourses, selectedIds);

    // Then pop this screen if still mounted
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}