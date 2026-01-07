import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oauth1/oauth1.dart' as oauth1;
import 'package:google_fonts/google_fonts.dart';
import 'home.dart' as home;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/class_essentials/hive.dart';
import 'package:myapp/class_essentials/assignment_manager.dart';
import 'package:myapp/screens/course_selection_screen.dart';

const storage = FlutterSecureStorage();

// App Theme Colors
class AppTheme {
  static const Color primary = Color.fromARGB(255, 253, 115, 12);
  static const Color secondary = Color.fromARGB(255, 15, 15, 50);
  static const Color surface = Color.fromARGB(255, 255, 247, 240);
  static const Color error = Color.fromARGB(255, 230, 20, 40);
  static const Color success = Color.fromARGB(255, 46, 160, 67);
  static const Color textPrimary = Color.fromARGB(255, 33, 33, 33);
  static const Color textSecondary = Color.fromARGB(255, 117, 117, 117);
}

// State management providers
final domainProvider = StateProvider<String>((ref) => '');
final isLoadingProvider = StateProvider<bool>((ref) => false);
final errorProvider = StateProvider<String?>((ref) => null);
final loginStageProvider = StateProvider<LoginStage>((ref) => LoginStage.domainEntry);

enum LoginStage {
  domainEntry,
  oauthLogin,
  completing,
  success
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  final hiveManager = HiveBoxManager();
  await hiveManager.init();

  String? token = await storage.read(key: 'oauth_token');
  String? secret = await storage.read(key: 'oauth_secret');

  if (secret == null || token == null) {
    FlutterNativeSplash.remove();
    runApp(
        const ProviderScope(
            child: MyApp()
        )
    );
  } else {
    runApp(
        ProviderScope(
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: _buildTheme(),
              home: home.Central(
                oauthToken: token,
                oauthSecret: secret,
              ),
            )
        )
    );
  }
}

ThemeData _buildTheme() {
  return ThemeData(
    primarySwatch: Colors.orange,
    primaryColor: AppTheme.primary,
    scaffoldBackgroundColor: AppTheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.figtree(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.figtree(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    textTheme: GoogleFonts.figtreeTextTheme(),
  );
}

void clearLogin() async {
  await storage.deleteAll();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Schoology Connect',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const LoginFlowWrapper(),
    );
  }
}

class LoginFlowWrapper extends ConsumerStatefulWidget {
  const LoginFlowWrapper({super.key});

  @override
  ConsumerState<LoginFlowWrapper> createState() => _LoginFlowWrapperState();
}

class _LoginFlowWrapperState extends ConsumerState<LoginFlowWrapper>
    with WidgetsBindingObserver {
  bool _isOAuthInProgress = false;
  String? _currentDomain;
  Timer? _oauthTimeoutTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _oauthTimeoutTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isOAuthInProgress) {
      _handleOAuthReturn();
    }
  }

  void _handleOAuthReturn() async {
    if (!mounted) return;

    ref.read(loginStageProvider.notifier).state = LoginStage.completing;
    ref.read(isLoadingProvider.notifier).state = true;

    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Small delay for UX
      await _completeOAuth();
    } catch (e) {
      _handleOAuthError(e.toString());
    }
  }

  Future<void> _completeOAuth() async {
    if (_currentDomain == null) {
      throw Exception('Domain not set');
    }

    try {
      const String consK = "4228fad5be57913f4a288c71007cce38066a6a9c6";
      const String consS = "f16aa4e412861b3be29314970e2740ba";

      final oauth1. Platform platform = oauth1.Platform(
          'https://api.schoology.com/v1/oauth/request_token',
          'https://$_currentDomain/oauth/authorize',
          'https://api.schoology.com/v1/oauth/access_token',
          oauth1.SignatureMethods.hmacSha1
      );

      final oauth1.ClientCredentials clientCredentials = oauth1.ClientCredentials(consK, consS);

      // Get stored temp credentials
      final tempToken = await storage.read(key: 'temp_oauth_token');
      final tempSecret = await storage.read(key: 'temp_oauth_secret');

      if (tempToken == null || tempSecret == null) {
        throw Exception('OAuth session expired.  Please try again.');
      }

      final tempCredentials = oauth1.Credentials(tempToken, tempSecret);
      final tempClient = oauth1.Client(
          platform. signatureMethod,
          clientCredentials,
          tempCredentials
      );

      final accessTokenResponse = await tempClient.get(
          Uri.parse('https://api.schoology.com/v1/oauth/access_token? oauth_verifier=$tempToken')
      );

      final accessParams = Uri(query: accessTokenResponse.body).queryParameters;
      final accessToken = accessParams['oauth_token'];
      final accessTokenSecret = accessParams['oauth_token_secret'];

      if (accessToken == null || accessTokenSecret == null) {
        throw Exception('Failed to complete login.  Please try again.');
      }

      // Store credentials securely
      await storage.write(key: 'oauth_token', value: accessToken);
      await storage.write(key: 'oauth_secret', value: accessTokenSecret);

      // Clean up temp credentials
      await storage. delete(key: 'temp_oauth_token');
      await storage.delete(key: 'temp_oauth_secret');

      _isOAuthInProgress = false;
      _oauthTimeoutTimer?.cancel();

      // Show success state briefly
      ref.read(loginStageProvider.notifier).state = LoginStage.success;
      await Future.delayed(const Duration(milliseconds: 800));

      // NEW: Check course count and navigate accordingly
      if (mounted) {
        await _navigateToAppOrCourseSelection(accessToken, accessTokenSecret);
      }
    } catch (e) {
      _handleOAuthError(e. toString());
    }
  }

// NEW METHOD: Handle navigation with course selection check
  // UPDATED METHOD:  Handle navigation with course selection check
  Future<void> _navigateToAppOrCourseSelection(String accessToken, String accessTokenSecret) async {
    try {
      // Create temporary assignment manager to fetch courses
      final hiveManager = HiveBoxManager();
      final tempAM = AssignmentManager(hiveManager, accessToken, accessTokenSecret);

      // Fetch courses (stores in temp if > 15)
      await tempAM.getCourses();

      if (! mounted) return;

      // Check if course selection is needed
      if (tempAM.needsCourseSelection()) {
        // Get temp courses from Hive
        final allCourses = hiveManager. box.get("temp_all_courses", defaultValue: []);
        final allCourseIds = hiveManager. box.get("temp_all_ids", defaultValue: []);

        // Navigate to course selection screen and wait for result
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CourseSelectionScreen(
              allCourses: allCourses,
              allCourseIds: allCourseIds,
              onConfirm: (selectedCourses, selectedIds) async {
                await _handleCourseSelection(selectedCourses, selectedIds);
              },
            ),
          ),
        );
      }

      // Navigate to main app (whether or not course selection happened)
      if (mounted) {
        _navigateToMainApp(accessToken, accessTokenSecret);
      }
    } catch (e) {
      print("Error checking courses: $e");
      // On error, proceed to main app anyway
      if (mounted) {
        _navigateToMainApp(accessToken, accessTokenSecret);
      }
    }
  }

// UPDATED METHOD: Handle course selection confirmation
  Future<void> _handleCourseSelection(
      List<dynamic> selectedCourses,
      List<dynamic> selectedIds,
      ) async {
    try {
      final hiveManager = HiveBoxManager();

      // Save selected courses to Hive
      await hiveManager.box.put("courses", selectedCourses);
      await hiveManager.box.put("ids", selectedIds);

      // Clean up temp storage
      await hiveManager. box.delete("temp_all_courses");
      await hiveManager.box.delete("temp_all_ids");

      print("Saved ${selectedCourses.length} selected courses");
    } catch (e) {
      print("Error saving course selection: $e");
      throw e;
    }
  }

// NEW METHOD: Navigate to main app
  void _navigateToMainApp(String accessToken, String accessTokenSecret) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => home.Central(
          oauthToken:  accessToken,
          oauthSecret: accessTokenSecret,
          coursesNeeded: false, // Changed to false since courses are already fetched
        ),
      ),
    );
  }

  void _handleOAuthError(String error) {
    _isOAuthInProgress = false;
    _oauthTimeoutTimer?.cancel();

    ref.read(isLoadingProvider.notifier).state = false;
    ref.read(errorProvider.notifier).state = error;
    ref.read(loginStageProvider.notifier).state = LoginStage.oauthLogin;
  }

  @override
  Widget build(BuildContext context) {
    final stage = ref.watch(loginStageProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _buildCurrentScreen(stage),
    );
  }

  Widget _buildCurrentScreen(LoginStage stage) {
    switch (stage) {
      case LoginStage.domainEntry:
        return DomainEntryScreen(
          onNext: (domain) {
            _currentDomain = domain;
            ref.read(domainProvider.notifier).state = domain;
            ref.read(loginStageProvider.notifier).state = LoginStage.oauthLogin;
          },
        );
      case LoginStage.oauthLogin:
        return OAuthLoginScreen(
          domain: _currentDomain ?? '',
          onStartOAuth: _startOAuth,
          onBack: () {
            ref.read(loginStageProvider.notifier).state = LoginStage.domainEntry;
          },
        );
      case LoginStage.completing:
        return const CompletingLoginScreen();
      case LoginStage.success:
        return const SuccessScreen();
    }
  }

  Future<void> _startOAuth(String domain) async {
    ref.read(isLoadingProvider.notifier).state = true;
    ref.read(errorProvider.notifier).state = null;

    try {
      const String consK = "4228fad5be57913f4a288c71007cce38066a6a9c6";
      const String consS = "f16aa4e412861b3be29314970e2740ba";

      final oauth1.Platform platform = oauth1.Platform(
          'https://api.schoology.com/v1/oauth/request_token',
          'https://$domain/oauth/authorize',
          'https://api.schoology.com/v1/oauth/access_token',
          oauth1.SignatureMethods.hmacSha1
      );

      final oauth1.ClientCredentials clientCredentials = oauth1.ClientCredentials(consK, consS);
      final oauth1.Client client = oauth1.Client(
          platform.signatureMethod,
          clientCredentials,
          null
      );

      final requestTokenResponse = await client.get(
          Uri.parse('https://api.schoology.com/v1/oauth/request_token')
      );

      final params = Uri(query: requestTokenResponse.body).queryParameters;
      final tempToken = params['oauth_token'];
      final tempTokenSecret = params['oauth_token_secret'];

      if (tempToken == null || tempTokenSecret == null) {
        throw Exception('Failed to initialize login. Please check your domain and try again.');
      }

      // Store temp credentials
      await storage.write(key: 'temp_oauth_token', value: tempToken);
      await storage.write(key: 'temp_oauth_secret', value: tempTokenSecret);

      final authUri = 'https://$domain/oauth/authorize?oauth_token=$tempToken';

      if (!await launchUrl(
        Uri.parse(authUri),
        mode: LaunchMode.externalApplication,
      )) {
        throw Exception('Could not open login page. Please check your internet connection and try again.');
      }

      _isOAuthInProgress = true;
      ref.read(isLoadingProvider.notifier).state = false;

      // Set timeout for OAuth process
      _oauthTimeoutTimer = Timer(const Duration(minutes: 10), () {
        if (_isOAuthInProgress) {
          _handleOAuthError('Login timed out. Please try again.');
        }
      });

    } catch (e) {
      _handleOAuthError(e.toString());
    }
  }
}

class DomainEntryScreen extends ConsumerStatefulWidget {
  final Function(String) onNext;

  const DomainEntryScreen({super.key, required this.onNext});

  @override
  ConsumerState<DomainEntryScreen> createState() => _DomainEntryScreenState();
}

class _DomainEntryScreenState extends ConsumerState<DomainEntryScreen>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String? _validateDomain(String value) {
    if (value.isEmpty) {
      return 'Please enter your school\'s domain';
    }

    // Basic domain validation
    if (!value.contains('.') || value.contains(' ')) {
      return 'Please enter a valid domain';
    }

    // Ensure it looks like a schoology domain
    if (!value.contains('schoology')) {
      return 'Please enter a valid Schoology domain';
    }

    return null;
  }

  void _handleNext() {
    final domain = _controller.text.trim();
    final error = _validateDomain(domain);

    if (error != null) {
      ref.read(errorProvider.notifier).state = error;
      return;
    }

    ref.read(errorProvider.notifier).state = null;
    widget.onNext(domain);
  }

  @override
  Widget build(BuildContext context) {
    final error = ref.watch(errorProvider);
    final isLoading = ref.watch(isLoadingProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.surface,
              Color.fromARGB(255, 255, 252, 247),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // App Icon/Logo
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.primary, Colors.deepOrange],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // App Title
                          Text(
                            'Schoology Connect',
                            style: GoogleFonts.figtree(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.secondary,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Text(
                            'Connect to your school\'s Schoology platform',
                            style: GoogleFonts.figtree(
                              fontSize: 16,
                              color: AppTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 48),

                          // Input Card
                          Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'School Domain',
                                    style: GoogleFonts.figtree(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.secondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  Text(
                                    'Enter your school\'s Schoology website URL',
                                    style: GoogleFonts.figtree(
                                      fontSize: 14,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  TextField(
                                    controller: _controller,
                                    focusNode: _focusNode,
                                    decoration: InputDecoration(
                                      hintText: 'schoology.yourschool.com',
                                      prefixIcon: const Icon(Icons.language),
                                      errorText: error,
                                    ),
                                    keyboardType: TextInputType.url,
                                    textInputAction: TextInputAction.next,
                                    onSubmitted: (_) => _handleNext(),
                                  ),
                                  const SizedBox(height: 16),

                                  // Examples
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Examples:',
                                          style: GoogleFonts.figtree(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'schoology.coppellisd.com\nschoology.district.edu\nmyschool.schoology.com',
                                          style: GoogleFonts.figtree(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Next Button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleNext,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Text(
                      'Continue',
                      style: GoogleFonts.figtree(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OAuthLoginScreen extends ConsumerStatefulWidget {
  final String domain;
  final Function(String) onStartOAuth;
  final VoidCallback onBack;

  const OAuthLoginScreen({
    super.key,
    required this.domain,
    required this.onStartOAuth,
    required this.onBack,
  });

  @override
  ConsumerState<OAuthLoginScreen> createState() => _OAuthLoginScreenState();
}

class _OAuthLoginScreenState extends ConsumerState<OAuthLoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = ref.watch(errorProvider);
    final isLoading = ref.watch(isLoadingProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.surface,
              Color.fromARGB(255, 255, 252, 247),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back Button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back_ios),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.secondary,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ),

                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Success Icon
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.success, Colors.green],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.success.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_circle_outline,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 32),

                          Text(
                            'Ready to Connect',
                            style: GoogleFonts.figtree(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.secondary,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Text(
                            'Domain: ${widget.domain}',
                            style: GoogleFonts.figtree(
                              fontSize: 16,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 24),

                          Text(
                            'We\'ll open your school\'s login page in your browser. After logging in, you\'ll be automatically brought back to the app.',
                            style: GoogleFonts.figtree(
                              fontSize: 16,
                              color: AppTheme.textSecondary,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),

                          // Login Card
                          Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.security,
                                    size: 48,
                                    color: AppTheme.primary,
                                  ),
                                  const SizedBox(height: 16),

                                  Text(
                                    'Secure Login',
                                    style: GoogleFonts.figtree(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.secondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  Text(
                                    'Your login credentials are handled securely by your school\'s Schoology system.',
                                    style: GoogleFonts.figtree(
                                      fontSize: 14,
                                      color: AppTheme.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (error != null) ...[
                            const SizedBox(height: 16),
                            Card(
                              color: AppTheme.error.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: AppTheme.error),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: AppTheme.error,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        error,
                                        style: GoogleFonts.figtree(
                                          fontSize: 14,
                                          color: AppTheme.error,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // Login Button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () => widget.onStartOAuth(widget.domain),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Opening login page...',
                          style: GoogleFonts.figtree(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.login, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Login with Schoology',
                          style: GoogleFonts.figtree(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CompletingLoginScreen extends StatefulWidget {
  const CompletingLoginScreen({super.key});

  @override
  State<CompletingLoginScreen> createState() => _CompletingLoginScreenState();
}

class _CompletingLoginScreenState extends State<CompletingLoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.surface,
              Color.fromARGB(255, 255, 252, 247),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, Colors.deepOrange],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.sync,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'Completing Login...',
                style: GoogleFonts.figtree(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondary,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Please wait while we securely connect\nyour account.',
                style: GoogleFonts.figtree(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SuccessScreen extends StatefulWidget {
  const SuccessScreen({super.key});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.surface,
              Color.fromARGB(255, 255, 252, 247),
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.success, Colors.green],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.success.withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                Text(
                  'Welcome!',
                  style: GoogleFonts.figtree(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondary,
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'Successfully connected to Schoology.\nLoading your dashboard...',
                  style: GoogleFonts.figtree(
                    fontSize: 18,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.success),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/*
  import 'dart:async';
  import 'package:flutter/material.dart';
  import 'package:oauth1/oauth1.dart' as oauth1;
  import 'package:google_fonts/google_fonts.dart';
  import 'home.dart' as home;
  import 'package:url_launcher/url_launcher.dart';
  import 'package:flutter_secure_storage/flutter_secure_storage.dart';
  import 'package:flutter_native_splash/flutter_native_splash.dart';
  import 'package:myapp/class_essentials/theme.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:myapp/class_essentials/assignment_manager.dart';
  import 'package:myapp/class_essentials/hive.dart';

  const storage = FlutterSecureStorage();

  void main() async {
    WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

    final hiveManager = HiveBoxManager();
    await hiveManager.init();

    String? token = await storage.read(key: 'oauth_token');
    String? secret = await storage.read(key: 'oauth_secret');
    if (secret == null || token == null){
      FlutterNativeSplash.remove();
      runApp(
        const ProviderScope(
          child: MyApp()
        )
      );
    } else{
      runApp(
        ProviderScope(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: home.Central(
              oauthToken: token,
              oauthSecret: secret,
            ),
          )
        )
      );
    }
  }

  void clearLogin() async {
    await storage.deleteAll();
  }
  
  class MyApp extends StatelessWidget {
    const MyApp({super.key});
  
    // This widget is the root of your application.
    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        title: 'Schoology API Test',
        debugShowCheckedModeBanner: false,
        theme: basic.lightTheme,
        home: const MyHomePage(),
      );
    }
  }
  
  class MyHomePage extends StatefulWidget {
    const MyHomePage({super.key});
  
    @override
    State<MyHomePage> createState() => _MyHomePageState();
  }
  
  class _MyHomePageState extends State<MyHomePage> {
    final Completer<void> _buttonCompleter = Completer<void>();
    var url = "url thingy";
  
    @override
    void dispose() {
      super.dispose();
    }
  
    @override
    void initState() {
      super.initState();
    }

    Future<void> stepOne() async {
      setState((){
        url = "First half of log in";
      });
      try {
        const String schoologyDomain = "schoology.coppellisd.com";
        final oauth1.Platform platform = oauth1.Platform(
            'https://api.schoology.com/v1/oauth/request_token',
            'https://$schoologyDomain/oauth/authorize',
            'https://api.schoology.com/v1/oauth/access_token',
            oauth1.SignatureMethods.hmacSha1
        );
        const String consK = "4228fad5be57913f4a288c71007cce38066a6a9c6";
        const String consS = "f16aa4e412861b3be29314970e2740ba";
        final oauth1.ClientCredentials clientCredentials = oauth1.ClientCredentials(consK, consS);
        final oauth1.Authorization auth = oauth1.Authorization(clientCredentials, platform);
        try {
          final oauth1.Client client = oauth1.Client(
              platform.signatureMethod,
              clientCredentials,
              null
          );
          final requestTokenResponse = await client.get(
              Uri.parse('https://api.schoology.com/v1/oauth/request_token')
          );
  
          final params = Uri(query: requestTokenResponse.body).queryParameters;
          final tempToken = params['oauth_token'];
          final tempTokenSecret = params['oauth_token_secret'];
  
          if (tempToken == null || tempTokenSecret == null) {
            throw Exception('Failed to parse oauth tokens from response');
          }
  
          final tempCredentials = oauth1.Credentials(tempToken, tempTokenSecret);
  
          // Using Coppell ISD's domain for authorization for now
          final authUri = 'https://$schoologyDomain/oauth/authorize?oauth_token=$tempToken';
          print('Open with your browser: $authUri');
          if(!await launchUrl(Uri.parse(authUri))){
            throw Exception('Could not open log-in link. Please check your settings, firewall, etc. for restrictions your device may have on opening urls.');
          }
  
          //break before continuing
          if(!_buttonCompleter.isCompleted){
            await _buttonCompleter.future;
          }
  
          final tempClient = oauth1.Client(
              platform.signatureMethod,
              clientCredentials,
              tempCredentials
          );
  
          final accessTokenResponse = await tempClient.get(
              Uri.parse('https://api.schoology.com/v1/oauth/access_token?oauth_verifier=$tempToken')
          );
  
          print('Access token response: ${accessTokenResponse.body}');
  
          final accessParams = Uri(query: accessTokenResponse.body).queryParameters;
          final accessToken = accessParams['oauth_token'];
          final accessTokenSecret = accessParams['oauth_token_secret'];
  
          if (accessToken == null || accessTokenSecret == null) {
            throw Exception('Failed to parse access tokens from response');
          }

          /*
          final authedClient = oauth1.Client(
              platform.signatureMethod,
              clientCredentials,
              oauth1.Credentials(accessToken, accessTokenSecret)
          );
  
          final response = await authedClient.get(
              Uri.parse('https://api.schoology.com/v1/messages/inbox')
          );
          print('API Response: ${response.body}');
          */
          await storage.write(key: 'oauth_token', value: accessToken);
          await storage.write(key: 'oauth_secret', value: accessTokenSecret);
          //after logging in, "restart" the app to trigger the main function's conditional checking for log-in credentials
          runApp(
            ProviderScope(
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                home: home.Central(
                  oauthToken: accessToken,
                  oauthSecret: accessTokenSecret,
                  coursesNeeded: true,
                ),
              ))
          );
  
        } catch (e, stackTrace) {
          print('Error during OAuth process: $e');
          print('Detailed stack trace:');
          print(stackTrace.toString().split('\n').take(10).join('\n'));
        }
  
      } catch (e) {
        print('Error during OAuth setup: $e');
        print('Stack trace: ${StackTrace.current}');
      }
    }
  
  //-------------------------------------------------------------\\
  //------Back End^------------------------vFront End------------\\
  //-------------------------------------------------------------\\
  
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 175, 20, 210),
          title: Text('Insert App Name',
              style: GoogleFonts.figtree(
                  textStyle: const TextStyle(
                      color: Color.fromARGB(255, 241, 241, 241)))),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                url,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              //this button must be pressed to complete log-in. don't remove it.
              IconButton(
                onPressed: (){
                  _buttonCompleter.complete();
                },
                icon: const Icon(
                  Icons.login_rounded,
                  color: Color.fromARGB(255, 175, 20, 210),
                )
              )
            ],
          ),
        ),
        //start log in process - must be completed with the other button
        floatingActionButton: FloatingActionButton(
          onPressed: stepOne,
          tooltip: 'Log in',
          child: const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Color.fromARGB(255, 175, 20, 210),
          ),
        ),
        // This trailing comma makes auto-formatting nicer for build methods.
      );
    }
  }

 */