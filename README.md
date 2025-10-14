# AI Image Enhancer

A Flutter mobile application that uses AI to enhance, generate, and modify images.

## Features

- **AI Image Enhancement**: Upscale and improve image quality
- **AI Image Generation**: Generate new images based on input
- **Remove Watermarks**: Clean watermarks from images
- **Remove Background**: Extract subjects from backgrounds
- **Before/After Comparison**: Compare original and enhanced images
- **Free Credit System**: 2 free uses per day
- **Local Storage**: Save enhanced images to gallery

## Screenshots

(Screenshots will be added after the app is built)

## Getting Started

### Prerequisites

- Flutter (stable channel)
- Dart SDK
- Android Studio / Xcode for mobile deployment

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/ai_image_enhancer.git
```

2. Navigate to the project directory:
```bash
cd ai_image_enhancer
```

3. Create a `.env` file in the root directory with your API keys:
```
KIE_AI_API_KEY=your_api_key_here
TOGETHER_AI_API_KEY=your_api_key_here
```

4. Install dependencies:
```bash
flutter pub get
```

5. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── core/
│    ├── theme/
│    │    └── app_theme.dart
│    ├── utils/
│    │    └── image_utils.dart
│    └── constants.dart
├── services/
│    └── ai_service.dart
├── providers/
│    └── credit_provider.dart
├── screens/
│    ├── splash_screen.dart
│    ├── home_screen.dart
│    ├── preview_screen.dart
│    └── result_screen.dart
├── widgets/
│    ├── image_card.dart
│    ├── loading_overlay.dart
│    └── upgrade_dialog.dart
└── main.dart
```

## Architecture

The app follows a clean architecture approach with:

- **BLoC Pattern**: For state management (credit system)
- **Service Layer**: For API interactions
- **UI Layer**: Screens and widgets
- **Utils**: Helper functions and constants

## Dependencies

- **dio**: For API calls
- **file_picker**: For selecting local images
- **flutter_spinkit**: Loading animations
- **shared_preferences**: For tracking free usage
- **image**: Image processing utilities
- **gallery_saver**: Save enhanced images
- **fluttertoast**: User feedback messages
- **flutter_bloc**: State management
- **cached_network_image**: Efficient image loading
- **flutter_dotenv**: Environment variable management

## Future Improvements

- Backend integration with authentication
- Subscription management with payment gateway
- More AI enhancement options
- Social sharing features
- Cloud storage for enhanced images

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [KIE AI](https://kie.ai) for image enhancement API
- [Together AI](https://together.ai) for image generation API
- Flutter team for the amazing framework