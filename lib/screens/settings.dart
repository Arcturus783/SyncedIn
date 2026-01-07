import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/class_essentials/theme.dart';
import 'package:myapp/class_essentials/hive.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final Future<void> Function(BuildContext) logout;
  final HiveBoxManager hiveManager;
  final bool autoHide;
  final bool visibleCalendar;

  const SettingsScreen({
    super.key,
    required this.logout,
    required this.hiveManager,
    required this.autoHide,
    required this.visibleCalendar,
  });

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Local state variables for the toggles
  late bool _autoHideEnabled;
  late bool _visibleCalendarEnabled;
  late String _defaultScreen;

  @override
  void initState() {
    super.initState();
    // Initialize from constructor parameters (loaded from Hive at app startup)
    _autoHideEnabled = widget.autoHide;
    _visibleCalendarEnabled = widget.visibleCalendar;
    // Initialize default screen from Hive, defaulting to "Assignments"
    _defaultScreen = widget.hiveManager.box.get("defaultScreen", defaultValue: "Assignments") as String;
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(currentThemeProvider);
    final availableThemes = ThemeManager.getAvailableThemes();
    final theme = (Theme.of(context).brightness == Brightness.dark)
        ? currentTheme. darkTheme
        : currentTheme.lightTheme;

    return Scaffold(
      backgroundColor: theme! .colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child:  Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeader(context, theme),
                const SizedBox(height: 32),

                // Functionality Section
                _buildFunctionalitySection(context, ref, currentTheme),
                const SizedBox(height: 32),

                // Theme Section
                _buildThemeSection(context, ref, currentTheme, availableThemes),
                const SizedBox(height: 32),

                // Account Section
                _buildAccountSection(context, theme),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.7),
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.7),
          ],
          begin:  Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:  theme.colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child:  Icon(
              Icons.settings_rounded,
              color: theme. colorScheme.onPrimary,
              size: 32,
            ),
          ),
          const SizedBox(width:  20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight. bold,
                    color: theme. colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Personalize your experience',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionalitySection(BuildContext context, WidgetRef ref, AppTheme currentTheme) {
    final contextTheme = Theme.of(context);
    final isDark = contextTheme.brightness == Brightness.dark;
    final theme = isDark ? currentTheme.darkTheme : currentTheme.lightTheme;

    return Container(
      padding: const EdgeInsets. all(24),
      decoration: BoxDecoration(
        color:  theme! .colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme. colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color:  theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment. start,
                  children: [
                    Text(
                      'Functionality',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme. colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Customize app behavior',
                      style: theme.textTheme.bodyMedium?. copyWith(
                        color:  theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Default Screen Dropdown
          _buildDefaultScreenDropdown(context:  context, theme: theme),
          const SizedBox(height:  16),

          // Visible Calendar Assignments Toggle
          _buildFunctionalityToggle(
            context: context,
            theme:  theme,
            title: 'Visible Calendar Assignments',
            subtitle: 'Show hidden assignments in the calendar',
            icon: Icons.visibility_rounded,
            isEnabled:  _visibleCalendarEnabled,
            onTap: () {
              print('Visible Calendar toggle tapped.  Current:  $_visibleCalendarEnabled');
              setState(() {
                _visibleCalendarEnabled = !_visibleCalendarEnabled;
              });
              // Only save to Hive - no StateProvider needed
              widget.hiveManager.box.put("visibleCalendar", _visibleCalendarEnabled);
              print('Visible Calendar updated to: $_visibleCalendarEnabled');
            },
          ),
          const SizedBox(height:  16),

          // Auto-Hide Assignments Toggle
          _buildFunctionalityToggle(
            context: context,
            theme: theme,
            title: 'Auto-Hide Assignments',
            subtitle: 'Hide assignments upon completion',
            icon: Icons.auto_awesome_rounded,
            isEnabled: _autoHideEnabled,
            onTap: () {
              print('Auto-Hide toggle tapped. Current: $_autoHideEnabled');
              setState(() {
                _autoHideEnabled = !_autoHideEnabled;
              });
              // Only save to Hive - no StateProvider needed
              widget. hiveManager.box.put("autoHide", _autoHideEnabled);
              print('Auto-Hide updated to: $_autoHideEnabled');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultScreenDropdown({
    required BuildContext context,
    required ThemeData theme,
  }) {
    final List<String> screenOptions = ['Calendar', 'Assignments', 'Tasks'];

    return Container(
      padding:  const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.08),
            theme.colorScheme.primary.withValues(alpha: 0.04),
          ],
          begin:  Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:  BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.home_rounded,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Default Screen',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose your starting screen',
                  style: theme. textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme. primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme. primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _defaultScreen,
                      icon: Icon(
                        Icons.arrow_drop_down_rounded,
                        color: theme.colorScheme. primary,
                      ),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                      dropdownColor: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      items: screenOptions.map((String screen) {
                        return DropdownMenuItem<String>(
                          value: screen,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                Icon(
                                  _getScreenIcon(screen),
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(screen),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          print('Default screen changed from $_defaultScreen to $newValue');
                          setState(() {
                            _defaultScreen = newValue;
                          });
                          // Save to Hive
                          widget.hiveManager. box.put("defaultScreen", newValue);
                          print('Default screen updated to: $newValue');
                        }
                      },
                    ),
                  ),
                ),

              ],
            ),
          ),
          //const SizedBox(width: 16),

        ],
      ),
    );
  }

  IconData _getScreenIcon(String screen) {
    switch (screen) {
      case 'Calendar':
        return Icons.calendar_today_rounded;
      case 'Assignments':
        return Icons. assignment_rounded;
      case 'Tasks':
        return Icons. task_alt_rounded;
      default:
        return Icons.home_rounded;
    }
  }

  Widget _buildFunctionalityToggle({
    required BuildContext context,
    required ThemeData theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isEnabled
                ? [
              theme.colorScheme.primary. withValues(alpha: 0.12),
              theme.colorScheme.primary.withValues(alpha: 0.08),
            ]
                : [
              theme. colorScheme.primary.withValues(alpha: 0.06),
              theme.colorScheme.primary.withValues(alpha: 0.03),
            ],
            begin:  Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius:  BorderRadius.circular(16),
          border: Border.all(
            color: isEnabled
                ? theme.colorScheme.primary.withValues(alpha: 0.3)
                : theme.colorScheme.primary.withValues(alpha: 0.1),
            width: isEnabled ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isEnabled
                    ? theme.colorScheme.primary.withValues(alpha: 0.2)
                    : theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isEnabled
                    ? theme.colorScheme. primary
                    : theme.colorScheme.primary.withValues(alpha: 0.7),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight:  FontWeight.w600,
                      color: isEnabled
                          ? theme.colorScheme.onSurface
                          : theme. colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?. copyWith(
                      color:  theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Custom Toggle Switch
            AnimatedContainer(
              duration: const Duration(milliseconds:  300),
              curve: Curves.easeInOut,
              width: 60,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: isEnabled
                      ? [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.9),
                  ]
                      : [
                    theme.colorScheme.outline. withValues(alpha: 0.4),
                    theme.colorScheme.outline.withValues(alpha: 0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment. bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isEnabled
                        ? theme.colorScheme.primary.withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.15),
                    blurRadius:  isEnabled ? 12 : 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves. easeInOut,
                    left: isEnabled ? 28 : 2,
                    top: 2,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius:  6,
                            offset:  const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration:  const Duration(milliseconds: 200),
                        child: isEnabled
                            ? Icon(
                          Icons.check,
                          key: const ValueKey('check'),
                          color: theme. colorScheme.primary,
                          size: 16,
                        )
                            : Icon(
                          Icons. close,
                          key: const ValueKey('close'),
                          color: theme.colorScheme.outline,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSection(
      BuildContext context,
      WidgetRef ref,
      AppTheme currentTheme,
      List<String> availableThemes,
      ) {
    final contextTheme = Theme.of(context);
    final isDark = contextTheme. brightness == Brightness.dark;
    final theme = isDark ? currentTheme.darkTheme : currentTheme.lightTheme;

    return Container(
      padding:  const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme!. colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border. all(
          color: theme. colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 20,
            offset:  const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.palette_rounded,
                  color:  theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment. start,
                  children: [
                    Text(
                      'Appearance',
                      style: theme. textTheme.titleLarge?. copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme. colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Choose your preferred theme',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Metallic Look Toggle
          _buildMetallicToggle(context, ref, theme),
          const SizedBox(height: 24),

          _buildThemeGrid(context, ref, currentTheme, availableThemes, isDark),
        ],
      ),
    );
  }

  Widget _buildMetallicToggle(BuildContext context, WidgetRef ref, ThemeData theme) {
    final isMetallic = ref.watch(metallicProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme. primary.withValues(alpha: 0.08),
            theme. colorScheme.primary.withValues(alpha: 0.04),
          ],
          begin:  Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme. primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children:  [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme. primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMetallic ? 'Metallic Look' : 'Matte Look',
                  style:  theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose between a metallic or matte look',
                  style: theme. textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () {
              ref.read(metallicProvider.notifier).state = !isMetallic;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: isMetallic
                      ? [
                    theme.colorScheme.primary,
                    theme. colorScheme.primary.withValues(alpha: 0.8),
                  ]
                      : [
                    theme.colorScheme.outline.withValues(alpha: 0.3),
                    theme.colorScheme.outline.withValues(alpha: 0.2),
                  ],
                  begin:  Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color:  isMetallic
                        ?  theme.colorScheme.primary. withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.1),
                    blurRadius:  8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    left: isMetallic ? 28 : 4,
                    top: 4,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors. white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius:  4,
                            offset:  const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: isMetallic
                          ? Icon(
                        Icons.auto_awesome,
                        color: theme.colorScheme.primary,
                        size: 12,
                      )
                          : null,
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

  Widget _buildThemeGrid(
      BuildContext context,
      WidgetRef ref,
      AppTheme currentTheme,
      List<String> availableThemes,
      bool isDark,
      ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: availableThemes.length,
      itemBuilder: (context, index) {
        final themeId = availableThemes[index];
        final appTheme = ThemeManager.getTheme(themeId);
        final isSelected = themeId == currentTheme.name. toLowerCase();
        final previewTheme = isDark ? appTheme.darkTheme : appTheme.lightTheme;

        return _buildThemeCard(
          context,
          ref,
          appTheme,
          themeId,
          isSelected,
          previewTheme! ,
        );
      },
    );
  }

  Widget _buildThemeCard(
      BuildContext context,
      WidgetRef ref,
      AppTheme appTheme,
      String themeId,
      bool isSelected,
      ThemeData previewTheme,
      ) {
    return GestureDetector(
      onTap: () {
        if(appTheme.isPremium){
          ThemeData?  a = Theme.of(context).brightness == Brightness.light ? appTheme.lightTheme : appTheme.darkTheme;
          _showComingSoonSnackbar(context, a! );
        } else{
          ref.read(themeProvider.notifier).changeTheme(themeId);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              previewTheme.colorScheme.primary.withValues(alpha: 0.8),
              previewTheme. colorScheme.primary.withValues(alpha: 0.6),
            ],
            begin:  Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? previewTheme.colorScheme.onPrimary. withValues(alpha: 0.8)
                : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: previewTheme.colorScheme. primary.withValues(alpha: 0.3),
              blurRadius: isSelected ? 20 : 12,
              offset:  Offset(0, isSelected ? 8 : 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern with course colors
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: CustomPaint(
                  painter:  ThemePatternPainter(appTheme.courseColors),
                ),
              ),
            ),

            // Content overlay
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end:  Alignment.topCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Premium badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (appTheme.isPremium)
                        const Icon(
                          Icons.lock_sharp,
                          color: Colors. grey,
                        ),
                      const SizedBox(width: 10),

                      if (isSelected && ! appTheme.isPremium)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white. withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            color: previewTheme.colorScheme. primary,
                            size: 16,
                          ),
                        ),
                    ],
                  ),

                  const Spacer(),

                  // Theme name
                  Text(
                    appTheme.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors. black.withValues(alpha: 0.5),
                          blurRadius:  4,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Color preview dots
                  Row(
                    children: appTheme.courseColors.take(4).map((color) {
                      return Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets. only(right: 4),
                        decoration: BoxDecoration(
                          color: color,
                          shape:  BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoonSnackbar(BuildContext context, ThemeData theme) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white. withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child:  const Icon(
                Icons.lock_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width:  12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Coming Soon! ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors. white,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Premium themes will be available soon',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(milliseconds: 1500),
        elevation: 8,
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 20,
            offset:  const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:  theme.colorScheme.primary. withValues(alpha: 0.1),
                  borderRadius:  BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_circle_rounded,
                  color: theme.colorScheme. primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account',
                      style: theme.textTheme. titleLarge?.copyWith(
                        fontWeight: FontWeight. bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage your account settings',
                      style: theme.textTheme.bodyMedium?. copyWith(
                        color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildAccountActions(context, theme),
        ],
      ),
    );
  }

  Widget _buildAccountActions(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        /* In case this is needed later.
        _buildLargeActionTile(
          context:  context,
          theme: theme,
          icon: Icons.help_outline_rounded,
          title: 'Help & Support',
          subtitle: 'Get assistance and contact support',
          color: theme.colorScheme.primary,
          onTap: () {
            // Add help action
          },
        ),
        const SizedBox(height: 16),
        _buildLargeActionTile(
          context: context,
          theme: theme,
          icon: Icons.info_outline_rounded,
          title: 'About',
          subtitle: 'App version and information',
          color: theme.colorScheme.tertiary,
          onTap:  () {
            // Add about action
          },
        ),
        */
        const SizedBox(height: 16),
        _buildLargeActionTile(
          context:  context,
          theme: theme,
          icon: Icons.logout_rounded,
          title: 'Sign Out',
          subtitle: 'Log out of your account',
          color: theme.colorScheme.error,
          onTap: () => widget.logout(context),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildLargeActionTile({
    required BuildContext context,
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child:  Icon(
                icon,
                color: color,
                size:  24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:  theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?. copyWith(
                      color:  theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color.withValues(alpha: 0.7),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for theme pattern background
class ThemePatternPainter extends CustomPainter {
  final List<Color> colors;

  ThemePatternPainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Create a subtle pattern using the theme's course colors
    for (int i = 0; i < colors.length && i < 6; i++) {
      final radius = (size.width * 0.3) - (i * 8);
      final opacity = 0.1 - (i * 0.015);

      paint.color = colors[i]. withValues(alpha: opacity);

      canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.2),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}