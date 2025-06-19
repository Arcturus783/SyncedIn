import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/home.dart';

class AppTheme{
  final String name;
  final bool isPremium;
  final ThemeData lightTheme;
  final ThemeData? darkTheme;
  final List<Color> courseColors;

  const AppTheme({
    required this.name,
    required this.isPremium,
    required this.lightTheme,
    required this.courseColors,
    required this.darkTheme,
  });
}


AppTheme basic = AppTheme(
    name: 'Basic',
    isPremium: false,
    lightTheme: ThemeData(
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 255, 247, 240),
        foregroundColor: Color.fromARGB(255, 15, 15, 50),
      ),
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: Color.fromARGB(255, 253, 115, 12),
        onPrimary: Color.fromARGB(255, 252, 252, 252),
        secondary: Color.fromARGB(255, 15, 15, 50),
        onSecondary: Color.fromARGB(255, 250, 250, 255),
        surface: Color.fromARGB(255, 255, 247, 240),
        onSurface: Color.fromARGB(255, 15, 15, 50),
        error: Color.fromARGB(255, 230, 20, 40),
        onError: Color.fromARGB(255, 255, 255, 255),
      ),
      indicatorColor: const Color.fromARGB(255, 253, 115, 12),
    ),

    darkTheme: ThemeData(
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color.fromARGB(255, 253, 115, 12),          // Keep the orange for brand consistency
        onPrimary: Color.fromARGB(255, 15, 15, 50),          // Dark text on orange
        secondary: Color.fromARGB(255, 100, 150, 255),       // Lighter blue for dark mode
        onSecondary: Color.fromARGB(255, 15, 15, 50),        // Dark text on light blue
        surface: Color.fromARGB(255, 25, 25, 35),            // Dark surface
        onSurface: Color.fromARGB(255, 240, 240, 245),       // Light text on dark surface
        error: Color.fromARGB(255, 255, 100, 120),           // Softer red for dark mode
        onError: Color.fromARGB(255, 15, 15, 50),            // Dark text on error

        // Additional properties for better dark mode experience
        primaryContainer: Color.fromARGB(255, 50, 30, 20),   // Dark orange container
        onPrimaryContainer: Color.fromARGB(255, 255, 200, 150), // Light orange text
      ),
      indicatorColor: const Color.fromARGB(255, 253, 115, 12),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 25, 25, 35),
        foregroundColor: Color.fromARGB(255, 240, 240, 245),
      ),
    ),

    courseColors: const [
      Color.fromARGB(255, 253, 115, 12),   // Primary Orange
      Color.fromARGB(255, 240, 140, 50),   // Light Orange
      Color.fromARGB(255, 220, 100, 80),   // Orange-Red
      Color.fromARGB(255, 200, 120, 100),  // Warm Coral
      Color.fromARGB(255, 180, 130, 120),  // Dusty Orange
      Color.fromARGB(255, 160, 140, 130),  // Neutral Warm
      Color.fromARGB(255, 140, 150, 140),  // True Neutral
      Color.fromARGB(255, 120, 150, 160),  // Cool Neutral
      Color.fromARGB(255, 100, 140, 180),  // Cool Blue-Gray
      Color.fromARGB(255, 80, 130, 200),   // Medium Blue
      Color.fromARGB(255, 60, 120, 220),   // Bright Blue
      Color.fromARGB(255, 40, 100, 180),   // Deep Blue
      Color.fromARGB(255, 30, 80, 140),    // Navy Blue
      Color.fromARGB(255, 40, 60, 110),    // Dark Blue-Gray
      Color.fromARGB(255, 45, 45, 95),     // Secondary Dark Blue
    ]
);

AppTheme focus = AppTheme(
    name: 'Focus',
    isPremium: false,
    lightTheme: ThemeData(
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 248, 250, 252),
        foregroundColor: Color.fromARGB(255, 30, 41, 59),
      ),
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: Color.fromARGB(255, 59, 130, 246),
        onPrimary: Color.fromARGB(255, 255, 255, 255),
        secondary: Color.fromARGB(255, 30, 41, 59),
        onSecondary: Color.fromARGB(255, 248, 250, 252),
        surface: Color.fromARGB(255, 248, 250, 252),
        onSurface: Color.fromARGB(255, 30, 41, 59),
        error: Color.fromARGB(255, 239, 68, 68),
        onError: Color.fromARGB(255, 255, 255, 255),
      ),
      indicatorColor: const Color.fromARGB(255, 59, 130, 246),
    ),

    darkTheme: ThemeData(
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color.fromARGB(255, 59, 130, 246),          // Keep blue for brand consistency
        onPrimary: Color.fromARGB(255, 30, 41, 59),          // Dark text on blue
        secondary: Color.fromARGB(255, 148, 163, 184),       // Light gray for dark mode
        onSecondary: Color.fromARGB(255, 30, 41, 59),        // Dark text on light gray
        surface: Color.fromARGB(255, 15, 23, 42),            // Dark blue-gray surface
        onSurface: Color.fromARGB(255, 241, 245, 249),       // Light text on dark surface
        error: Color.fromARGB(255, 248, 113, 113),           // Softer red for dark mode
        onError: Color.fromARGB(255, 30, 41, 59),            // Dark text on error

        // Additional properties for better dark mode experience
        primaryContainer: Color.fromARGB(255, 30, 64, 175),  // Dark blue container
        onPrimaryContainer: Color.fromARGB(255, 191, 219, 254), // Light blue text
      ),
      indicatorColor: const Color.fromARGB(255, 59, 130, 246),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 15, 23, 42),
        foregroundColor: Color.fromARGB(255, 241, 245, 249),
      ),
    ),

    courseColors: const [
      Color.fromARGB(255, 59, 130, 246),   // Primary Blue
      Color.fromARGB(255, 79, 70, 229),    // Blue-Indigo
      Color.fromARGB(255, 99, 102, 241),   // Indigo
      Color.fromARGB(255, 124, 58, 237),   // Purple-Indigo
      Color.fromARGB(255, 147, 51, 234),   // Purple
      Color.fromARGB(255, 168, 85, 247),   // Light Purple
      Color.fromARGB(255, 192, 132, 252),  // Lavender
      Color.fromARGB(255, 196, 181, 253),  // Pale Lavender
      Color.fromARGB(255, 165, 180, 252),  // Periwinkle
      Color.fromARGB(255, 129, 140, 248),  // Light Indigo
      Color.fromARGB(255, 96, 165, 250),   // Sky Blue
      Color.fromARGB(255, 56, 189, 248),   // Bright Blue
      Color.fromARGB(255, 14, 165, 233),   // Cyan Blue
      Color.fromARGB(255, 6, 182, 212),    // Teal Blue
      Color.fromARGB(255, 20, 184, 166),   // Teal
    ]
);

AppTheme cac = AppTheme(
    name: 'Calm and Cool',
    isPremium: false,
    lightTheme: ThemeData(
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 240, 253, 250),
        foregroundColor: Color.fromARGB(255, 6, 78, 59),
      ),
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: Color.fromARGB(255, 16, 185, 129),
        onPrimary: Color.fromARGB(255, 255, 255, 255),
        secondary: Color.fromARGB(255, 6, 78, 59),
        onSecondary: Color.fromARGB(255, 240, 253, 250),
        surface: Color.fromARGB(255, 240, 253, 250),
        onSurface: Color.fromARGB(255, 6, 78, 59),
        error: Color.fromARGB(255, 239, 68, 68),
        onError: Color.fromARGB(255, 255, 255, 255),
      ),
      indicatorColor: const Color.fromARGB(255, 16, 185, 129),
    ),

    darkTheme: ThemeData(
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color.fromARGB(255, 16, 185, 129),          // Keep emerald for brand consistency
        onPrimary: Color.fromARGB(255, 6, 78, 59),           // Dark text on emerald
        secondary: Color.fromARGB(255, 134, 239, 172),       // Light green for dark mode
        onSecondary: Color.fromARGB(255, 6, 78, 59),         // Dark text on light green
        surface: Color.fromARGB(255, 6, 20, 15),             // Very dark green surface
        onSurface: Color.fromARGB(255, 236, 253, 245),       // Light mint text on dark surface
        error: Color.fromARGB(255, 248, 113, 113),           // Softer red for dark mode
        onError: Color.fromARGB(255, 6, 78, 59),             // Dark text on error

        // Additional properties for better dark mode experience
        primaryContainer: Color.fromARGB(255, 6, 95, 70),    // Dark emerald container
        onPrimaryContainer: Color.fromARGB(255, 167, 243, 208), // Light emerald text
      ),
      indicatorColor: const Color.fromARGB(255, 16, 185, 129),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 6, 20, 15),
        foregroundColor: Color.fromARGB(255, 236, 253, 245),
      ),
    ),

    courseColors: const [
      Color.fromARGB(255, 16, 185, 129),   // Primary Emerald
      Color.fromARGB(255, 5, 150, 105),    // Deep Emerald
      Color.fromARGB(255, 6, 120, 95),     // Forest Green
      Color.fromARGB(255, 22, 101, 52),    // Dark Green
      Color.fromARGB(255, 34, 197, 94),    // Bright Green
      Color.fromARGB(255, 74, 222, 128),   // Light Green
      Color.fromARGB(255, 134, 239, 172),  // Mint Green
      Color.fromARGB(255, 187, 247, 208),  // Pale Green
      Color.fromARGB(255, 165, 243, 252),  // Aqua Mint
      Color.fromARGB(255, 103, 232, 249),  // Light Cyan
      Color.fromARGB(255, 34, 211, 238),   // Cyan
      Color.fromARGB(255, 6, 182, 212),    // Teal Cyan
      Color.fromARGB(255, 8, 145, 178),    // Deep Teal
      Color.fromARGB(255, 14, 116, 144),   // Dark Teal
      Color.fromARGB(255, 21, 94, 117),    // Navy Teal
    ]
);

AppTheme carbon = AppTheme(
    name: 'Carbon',
    isPremium: true,
    lightTheme: ThemeData(
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 249, 250, 251),
        foregroundColor: Color.fromARGB(255, 17, 24, 39),
      ),
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: Color.fromARGB(255, 55, 65, 81),
        onPrimary: Color.fromARGB(255, 255, 255, 255),
        secondary: Color.fromARGB(255, 107, 114, 128),
        onSecondary: Color.fromARGB(255, 255, 255, 255),
        surface: Color.fromARGB(255, 249, 250, 251),
        onSurface: Color.fromARGB(255, 17, 24, 39),
        error: Color.fromARGB(255, 220, 38, 38),
        onError: Color.fromARGB(255, 255, 255, 255),
      ),
      indicatorColor: const Color.fromARGB(255, 55, 65, 81),
    ),

    darkTheme: ThemeData(
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color.fromARGB(255, 156, 163, 175),         // Lighter gray for dark mode accent
        onPrimary: Color.fromARGB(255, 17, 24, 39),          // Dark text on light gray
        secondary: Color.fromARGB(255, 75, 85, 99),          // Medium gray
        onSecondary: Color.fromARGB(255, 229, 231, 235),     // Light text on medium gray
        surface: Color.fromARGB(255, 17, 24, 39),            // Deep charcoal surface
        onSurface: Color.fromARGB(255, 243, 244, 246),       // Near-white text
        error: Color.fromARGB(255, 248, 113, 113),           // Softer red for dark mode
        onError: Color.fromARGB(255, 17, 24, 39),            // Dark text on error

        // Additional properties for sophisticated dark mode
        primaryContainer: Color.fromARGB(255, 31, 41, 55),   // Darker gray container
        onPrimaryContainer: Color.fromARGB(255, 209, 213, 219), // Light gray text
      ),
      indicatorColor: const Color.fromARGB(255, 156, 163, 175),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 17, 24, 39),
        foregroundColor: Color.fromARGB(255, 243, 244, 246),
      ),
    ),

    courseColors: const [
      Color.fromARGB(255, 17, 24, 39),     // Deep Charcoal
      Color.fromARGB(255, 31, 41, 55),     // Dark Slate
      Color.fromARGB(255, 55, 65, 81),     // Graphite
      Color.fromARGB(255, 75, 85, 99),     // Steel Gray
      Color.fromARGB(255, 107, 114, 128),  // Slate Gray
      Color.fromARGB(255, 156, 163, 175),  // Silver Gray
      Color.fromARGB(255, 209, 213, 219),  // Light Silver
      Color.fromARGB(255, 229, 231, 235),  // Platinum
      Color.fromARGB(255, 243, 244, 246),  // Pearl White
      Color.fromARGB(255, 156, 163, 175),  // Return to Silver
      Color.fromARGB(255, 107, 114, 128),  // Return to Slate
      Color.fromARGB(255, 75, 85, 99),     // Return to Steel
      Color.fromARGB(255, 55, 65, 81),     // Return to Graphite
      Color.fromARGB(255, 31, 41, 55),     // Return to Dark Slate
      Color.fromARGB(255, 17, 24, 39),     // Return to Charcoal
    ]
);

AppTheme midnight = AppTheme(
    name: 'Midnight',
    isPremium: true,
    lightTheme: ThemeData(
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 248, 250, 255),
        foregroundColor: Color.fromARGB(255, 30, 27, 75),
      ),
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: Color.fromARGB(255, 67, 56, 202),
        onPrimary: Color.fromARGB(255, 255, 255, 255),
        secondary: Color.fromARGB(255, 30, 27, 75),
        onSecondary: Color.fromARGB(255, 248, 250, 255),
        surface: Color.fromARGB(255, 248, 250, 255),
        onSurface: Color.fromARGB(255, 30, 27, 75),
        error: Color.fromARGB(255, 190, 18, 60),
        onError: Color.fromARGB(255, 255, 255, 255),
      ),
      indicatorColor: const Color.fromARGB(255, 67, 56, 202),
    ),

    darkTheme: ThemeData(
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color.fromARGB(255, 129, 140, 248),         // Luminous indigo for dark mode
        onPrimary: Color.fromARGB(255, 15, 15, 35),          // Very dark text on bright primary
        secondary: Color.fromARGB(255, 99, 102, 241),        // Rich purple-blue
        onSecondary: Color.fromARGB(255, 248, 250, 255),     // Light text on secondary
        surface: Color.fromARGB(255, 15, 15, 35),            // Deep midnight surface
        onSurface: Color.fromARGB(255, 241, 245, 249),       // Bright text on dark surface
        error: Color.fromARGB(255, 248, 113, 113),           // Softer red for dark mode
        onError: Color.fromARGB(255, 15, 15, 35),            // Dark text on error

        // Additional properties for luxurious dark mode
        primaryContainer: Color.fromARGB(255, 30, 27, 75),   // Deep indigo container
        onPrimaryContainer: Color.fromARGB(255, 196, 181, 253), // Light lavender text
      ),
      indicatorColor: const Color.fromARGB(255, 129, 140, 248),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 15, 15, 35),
        foregroundColor: Color.fromARGB(255, 241, 245, 249),
      ),
    ),

    courseColors: const [
      Color.fromARGB(255, 15, 15, 35),     // Midnight Black
      Color.fromARGB(255, 30, 27, 75),     // Deep Indigo
      Color.fromARGB(255, 55, 48, 163),    // Royal Indigo
      Color.fromARGB(255, 67, 56, 202),    // Bright Indigo
      Color.fromARGB(255, 79, 70, 229),    // Electric Indigo
      Color.fromARGB(255, 99, 102, 241),   // Luminous Purple
      Color.fromARGB(255, 129, 140, 248),  // Periwinkle Blue
      Color.fromARGB(255, 165, 180, 252),  // Lavender Blue
      Color.fromARGB(255, 196, 181, 253),  // Soft Lavender
      Color.fromARGB(255, 221, 214, 254),  // Pale Lavender
      Color.fromARGB(255, 238, 242, 255),  // Whisper Blue
      Color.fromARGB(255, 219, 234, 254),  // Ice Blue
      Color.fromARGB(255, 191, 219, 254),  // Sky Blue
      Color.fromARGB(255, 147, 197, 253),  // Bright Sky
      Color.fromARGB(255, 96, 165, 250),   // Azure Blue
    ]
);

AppTheme sunset = AppTheme(
    name: 'Sunset',
    isPremium: true,
    lightTheme: ThemeData(
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 255, 251, 235),
        foregroundColor: Color.fromARGB(255, 120, 53, 15),
      ),
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: Color.fromARGB(255, 251, 146, 60),
        onPrimary: Color.fromARGB(255, 255, 255, 255),
        secondary: Color.fromARGB(255, 120, 53, 15),
        onSecondary: Color.fromARGB(255, 255, 251, 235),
        surface: Color.fromARGB(255, 255, 251, 235),
        onSurface: Color.fromARGB(255, 120, 53, 15),
        error: Color.fromARGB(255, 220, 38, 38),
        onError: Color.fromARGB(255, 255, 255, 255),
      ),
      indicatorColor: const Color.fromARGB(255, 251, 146, 60),
    ),

    darkTheme: ThemeData(
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color.fromARGB(255, 251, 146, 60),          // Golden sunset glow
        onPrimary: Color.fromARGB(255, 69, 26, 3),           // Deep amber text
        secondary: Color.fromARGB(255, 248, 113, 113),       // Coral pink
        onSecondary: Color.fromARGB(255, 69, 26, 3),         // Deep text on coral
        surface: Color.fromARGB(255, 69, 26, 3),             // Deep twilight
        onSurface: Color.fromARGB(255, 255, 251, 235),       // Warm light text
        error: Color.fromARGB(255, 248, 113, 113),           // Softer red for dark mode
        onError: Color.fromARGB(255, 69, 26, 3),             // Deep text on error

        // Additional properties for sunset luxury
        primaryContainer: Color.fromARGB(255, 120, 53, 15),  // Deep amber container
        onPrimaryContainer: Color.fromARGB(255, 254, 215, 170), // Peach text
      ),
      indicatorColor: const Color.fromARGB(255, 251, 146, 60),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 69, 26, 3),
        foregroundColor: Color.fromARGB(255, 255, 251, 235),
      ),
    ),

    courseColors: const [
      Color.fromARGB(255, 69, 26, 3),      // Deep Twilight
      Color.fromARGB(255, 120, 53, 15),    // Burnt Sienna
      Color.fromARGB(255, 194, 65, 12),    // Terracotta
      Color.fromARGB(255, 234, 88, 12),    // Burnt Orange
      Color.fromARGB(255, 251, 146, 60),   // Golden Hour
      Color.fromARGB(255, 252, 176, 64),   // Amber Glow
      Color.fromARGB(255, 254, 215, 170),  // Peach
      Color.fromARGB(255, 254, 240, 138),  // Golden Yellow
      Color.fromARGB(255, 255, 237, 213),  // Cream
      Color.fromARGB(255, 252, 231, 243),  // Blush Pink
      Color.fromARGB(255, 248, 113, 113),  // Coral Pink
      Color.fromARGB(255, 251, 113, 133),  // Rose Pink
      Color.fromARGB(255, 244, 114, 182),  // Magenta
      Color.fromARGB(255, 196, 181, 253),  // Lavender
      Color.fromARGB(255, 129, 140, 248),  // Violet Twilight
    ]
);

AppTheme oceanDepth = AppTheme(
    name: 'Ocean Depth',
    isPremium: true,
    lightTheme: ThemeData(
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 240, 249, 255),
        foregroundColor: Color.fromARGB(255, 12, 74, 110),
      ),
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: Color.fromARGB(255, 14, 116, 144),
        onPrimary: Color.fromARGB(255, 255, 255, 255),
        secondary: Color.fromARGB(255, 12, 74, 110),
        onSecondary: Color.fromARGB(255, 240, 249, 255),
        surface: Color.fromARGB(255, 240, 249, 255),
        onSurface: Color.fromARGB(255, 12, 74, 110),
        error: Color.fromARGB(255, 185, 28, 28),
        onError: Color.fromARGB(255, 255, 255, 255),
      ),
      indicatorColor: const Color.fromARGB(255, 14, 116, 144),
    ),

    darkTheme: ThemeData(
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color.fromARGB(255, 34, 211, 238),          // Luminous cyan for deep ocean glow
        onPrimary: Color.fromARGB(255, 8, 51, 68),           // Deep ocean text
        secondary: Color.fromARGB(255, 6, 182, 212),         // Teal depths
        onSecondary: Color.fromARGB(255, 240, 249, 255),     // Light foam text
        surface: Color.fromARGB(255, 8, 51, 68),             // Abyssal depths
        onSurface: Color.fromARGB(255, 236, 254, 255),       // Bioluminescent text
        error: Color.fromARGB(255, 248, 113, 113),           // Softer red for dark mode
        onError: Color.fromARGB(255, 8, 51, 68),             // Deep text on error

        // Additional properties for oceanic luxury
        primaryContainer: Color.fromARGB(255, 12, 74, 110),  // Deep sea container
        onPrimaryContainer: Color.fromARGB(255, 165, 243, 252), // Aqua foam text
      ),
      indicatorColor: const Color.fromARGB(255, 34, 211, 238),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 8, 51, 68),
        foregroundColor: Color.fromARGB(255, 236, 254, 255),
      ),
    ),

    courseColors: const [
      Color.fromARGB(255, 8, 51, 68),      // Abyssal Black
      Color.fromARGB(255, 12, 74, 110),    // Deep Ocean
      Color.fromARGB(255, 14, 116, 144),   // Mariana Trench
      Color.fromARGB(255, 21, 94, 117),    // Midnight Blue
      Color.fromARGB(255, 8, 145, 178),    // Deep Teal
      Color.fromARGB(255, 6, 182, 212),    // Ocean Current
      Color.fromARGB(255, 34, 211, 238),   // Tropical Waters
      Color.fromARGB(255, 103, 232, 249),  // Coral Reef
      Color.fromARGB(255, 165, 243, 252),  // Shallow Lagoon
      Color.fromARGB(255, 207, 250, 254),  // Sea Foam
      Color.fromARGB(255, 236, 254, 255),  // Ocean Mist
      Color.fromARGB(255, 240, 249, 255),  // Sea Glass
      Color.fromARGB(255, 219, 234, 254),  // Powder Blue
      Color.fromARGB(255, 186, 230, 253),  // Sky Blue
      Color.fromARGB(255, 125, 211, 252),  // Azure
    ]
);

AppTheme royalty = AppTheme(
    name: 'Royalty',
    isPremium: true,
    lightTheme: ThemeData(
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 254, 252, 232),
        foregroundColor: Color.fromARGB(255, 69, 26, 3),
      ),
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: Color.fromARGB(255, 147, 51, 234),
        onPrimary: Color.fromARGB(255, 255, 255, 255),
        secondary: Color.fromARGB(255, 217, 119, 6),
        onSecondary: Color.fromARGB(255, 255, 255, 255),
        surface: Color.fromARGB(255, 254, 252, 232),
        onSurface: Color.fromARGB(255, 69, 26, 3),
        error: Color.fromARGB(255, 185, 28, 28),
        onError: Color.fromARGB(255, 255, 255, 255),
      ),
      indicatorColor: const Color.fromARGB(255, 147, 51, 234),
    ),

    darkTheme: ThemeData(
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color.fromARGB(255, 217, 119, 6),           // Royal gold for dark mode
        onPrimary: Color.fromARGB(255, 44, 8, 49),           // Deep purple text
        secondary: Color.fromARGB(255, 147, 51, 234),        // Imperial purple
        onSecondary: Color.fromARGB(255, 254, 252, 232),     // Cream text on purple
        surface: Color.fromARGB(255, 44, 8, 49),             // Deep royal purple
        onSurface: Color.fromARGB(255, 254, 252, 232),       // Cream text
        error: Color.fromARGB(255, 248, 113, 113),           // Softer red for dark mode
        onError: Color.fromARGB(255, 44, 8, 49),             // Deep text on error

        // Additional properties for royal luxury
        primaryContainer: Color.fromARGB(255, 88, 28, 135),  // Deep purple container
        onPrimaryContainer: Color.fromARGB(255, 253, 224, 71), // Golden text
      ),
      indicatorColor: const Color.fromARGB(255, 217, 119, 6),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 44, 8, 49),
        foregroundColor: Color.fromARGB(255, 254, 252, 232),
      ),
    ),

    courseColors: const [
      Color.fromARGB(255, 44, 8, 49),      // Imperial Purple
      Color.fromARGB(255, 88, 28, 135),    // Royal Purple
      Color.fromARGB(255, 147, 51, 234),   // Amethyst
      Color.fromARGB(255, 168, 85, 247),   // Bright Purple
      Color.fromARGB(255, 196, 181, 253),  // Lavender
      Color.fromARGB(255, 221, 214, 254),  // Pale Lavender
      Color.fromARGB(255, 254, 252, 232),  // Ivory
      Color.fromARGB(255, 253, 224, 71),   // Royal Gold
      Color.fromARGB(255, 217, 119, 6),    // Amber Gold
      Color.fromARGB(255, 180, 83, 9),     // Deep Gold
      Color.fromARGB(255, 146, 64, 14),    // Bronze
      Color.fromARGB(255, 120, 53, 15),    // Burnt Umber
      Color.fromARGB(255, 194, 65, 12),    // Rust
      Color.fromARGB(255, 234, 88, 12),    // Copper
      Color.fromARGB(255, 251, 146, 60),   // Rose Gold
    ]
);


class ThemeManager extends ChangeNotifier{

    static final Map<String, AppTheme> _themes = {
      'basic' : basic,
      'focus' : focus,
      'calm' : cac,
      'carbon' : carbon,
      'midnight' : midnight,
      'sunset' : sunset,
      'oceanDepth' : oceanDepth,
      'royalty' : royalty,
    };

    static List<String> getAvailableThemes() {
      return _themes.keys.toList();
    }

    static AppTheme getTheme(String themeId) {
      return _themes[themeId] ?? _themes['basic']!;
    }
}

final currentThemeProvider = Provider<AppTheme>((ref) {
  final selectedThemeId = ref.watch(themeProvider);
  return ThemeManager.getTheme(selectedThemeId);
});

final themeProvider = StateNotifierProvider<ThemeNotifier, String>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<String> {
  ThemeNotifier() : super('basic') {
    _loadThemePreference();
  }

  void changeTheme(String themeName) {
    state = themeName;
    _saveThemePreference(themeName);
  }

  void _loadThemePreference() async {
    final savedTheme = hiveManager.box.get('selected_theme') ?? 'basic';
    state = savedTheme;
  }

  void _saveThemePreference(String theme) async {
    await hiveManager.box.put('selected_theme', theme);
  }
}

