# AI Image Enhancer

A Flutter mobile application that uses AI to enhance, generate, and modify images.

## Features

- **AI Image Enhancement**: Upscale and improve image quality
- **AI Image Generation**: Generate new images from text prompts using Together AI
- **Remove Watermarks**: Clean watermarks from images
- **Remove Background**: Extract subjects from backgrounds
- **Image Editing**: Edit images before and after AI processing
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
│    ├── image_generation_screen.dart
│    ├── image_editor_screen.dart
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

## Key Features

### Image Generation with Together AI

The app integrates with Together AI's image generation API to create images from text prompts:

- **Text-to-Image Generation**: Create images from descriptive prompts
- **Reference Image Support**: Use an existing image as reference for generation
- **Quality Control**: Adjust steps parameter for quality vs. speed
- **Resolution Options**: Multiple resolution options (1024×768, 768×1024, etc.)
- **Model**: Uses "black-forest-labs/FLUX.1-schnell-Free" model

### Image Editing

The app includes comprehensive image editing capabilities:

- **Pre-Enhancement Editing**: Edit images before applying AI enhancement
- **Post-Enhancement Editing**: Further refine AI-generated or enhanced images
- **Editing Tools**: Crop, rotate, add filters, text, and drawings

## Dependencies

- **dio**: For API calls
- **file_picker**: For selecting local images
- **flutter_spinkit**: Loading animations
- **shared_preferences**: For tracking free usage
- **image**: Image processing utilities
- **gallery_saver_plus**: Save enhanced images
- **fluttertoast**: User feedback messages
- **flutter_bloc**: State management
- **cached_network_image**: Efficient image loading
- **flutter_dotenv**: Environment variable management
- **image_editor_plus**: Comprehensive image editing functionality

## Together AI API Integration

The app uses Together AI's image generation API:

```
Endpoint: https://api.together.xyz/v1/images/generations
Method: POST
Headers:
  - Authorization: Bearer YOUR_API_KEY
  - Content-Type: application/json
Body:
  {
    "model": "black-forest-labs/FLUX.1-schnell-Free",
    "prompt": "Your descriptive prompt here",
    "width": 1024,
    "height": 768,
    "steps": 28,
    "n": 1,
    "response_format": "url",
    "image_url": "Optional reference image URL"
  }
```

## Future Improvements

- Backend integration with authentication
- Subscription management with payment gateway
- More AI enhancement options
- Social sharing features
- Cloud storage for enhanced images
- Support for more AI models

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [KIE AI](https://kie.ai) for image enhancement API
- [Together AI](https://together.ai) for image generation API
- Flutter team for the amazing framework