class AppConstants {
  // API Endpoints
  static const String kieAiEndpoint = 'https://api.kie.ai/image-enhance';

  // App Settings
  static const int freeCreditsPerDay = 2;

  // SharedPreferences Keys
  static const String dailyCountKey = 'daily_count';
  static const String lastDateKey = 'last_date';

  // Gallery
  static const String galleryFolderName = 'AI Enhancer';

  // Features
  static const List<String> features = [
    'AI Image Enhancement',
    'AI Image Generation',
    'Remove Image Watermark',
    'Remove Image Background',
  ];

  // Error Messages
  static const String networkErrorMessage =
      'Network error. Please check your internet connection.';
  static const String invalidImageErrorMessage =
      'Invalid image format. Please select a JPG or PNG image.';
  static const String apiErrorMessage =
      'Error processing image. Please try again later.';
  static const String creditLimitMessage =
      'You\'ve used all free credits for today. Upgrade to continue.';
}
