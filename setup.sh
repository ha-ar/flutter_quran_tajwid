#!/bin/bash

# Flutter Quran Tajweed - Setup Script
# This script helps set up the Flutter Quran Tajweed application

echo "==================================================="
echo "   Flutter Quran Tajweed - Setup Script"
echo "==================================================="
echo ""

# Step 1: Check Flutter
echo "1. Checking Flutter installation..."
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first."
    echo "   Visit: https://flutter.dev/docs/get-started/install"
    exit 1
fi
echo "✅ Flutter installed: $(flutter --version | head -n 1)"
echo ""

# Step 2: Get dependencies
echo "2. Installing dependencies..."
flutter pub get
echo "✅ Dependencies installed"
echo ""

# Step 3: Create fonts directory
echo "3. Creating fonts directory..."
mkdir -p assets/fonts
echo "✅ Fonts directory created at assets/fonts/"
echo ""

# Step 4: Check for fonts
echo "4. Checking for required fonts..."
FONTS_MISSING=false

if [ ! -f "assets/fonts/UthmanicHafs.ttf" ]; then
    echo "⚠️  UthmanicHafs.ttf not found"
    FONTS_MISSING=true
fi

if [ ! -f "assets/fonts/NotoNaskhArabic-Regular.ttf" ]; then
    echo "⚠️  NotoNaskhArabic-Regular.ttf not found"
    FONTS_MISSING=true
fi

if [ ! -f "assets/fonts/NotoNaskhArabic-Bold.ttf" ]; then
    echo "⚠️  NotoNaskhArabic-Bold.ttf not found"
    FONTS_MISSING=true
fi

if [ "$FONTS_MISSING" = true ]; then
    echo ""
    echo "📥 Fonts need to be downloaded manually:"
    echo ""
    echo "   1. Quranic Font (Uthmanic Hafs):"
    echo "      Download from: https://fonts.qurancomplex.gov.sa"
    echo "      Save as: assets/fonts/UthmanicHafs.ttf"
    echo ""
    echo "   2. Arabic UI Font (Noto Naskh Arabic):"
    echo "      Download from: https://fonts.google.com/noto/specimen/Noto+Naskh+Arabic"
    echo "      Save as: assets/fonts/NotoNaskhArabic-Regular.ttf"
    echo "      Save as: assets/fonts/NotoNaskhArabic-Bold.ttf"
    echo ""
    echo "   See FONTS_SETUP.md for more details"
    echo ""
fi

if [ -f "assets/fonts/UthmanicHafs.ttf" ] && [ -f "assets/fonts/NotoNaskhArabic-Regular.ttf" ] && [ -f "assets/fonts/NotoNaskhArabic-Bold.ttf" ]; then
    echo "✅ All fonts are present"
fi
echo ""

# Step 5: Check .env file
echo "5. Checking configuration..."
if [ ! -f ".env" ]; then
    echo "⚠️  .env file not found"
    echo "   Creating .env file..."
    cat > .env << EOF
GEMINI_API_KEY=your_api_key_here
EOF
    echo "   ℹ️  Please update .env with your Gemini API Key"
    echo "   Get it from: https://aistudio.google.com"
else
    echo "✅ .env file found"
fi
echo ""

# Step 6: Clean and prepare
echo "6. Cleaning and preparing..."
flutter clean
flutter pub get
echo "✅ Ready to run"
echo ""

# Step 7: Next steps
echo "==================================================="
echo "   Setup Complete! Next Steps:"
echo "==================================================="
echo ""
echo "1. Download fonts (if not already done)"
echo "2. Update .env with your Gemini API Key"
echo "3. Run the app:"
echo "   flutter run"
echo ""
echo "4. For iOS, run:"
echo "   cd ios && pod install && cd .."
echo "   flutter run"
echo ""
echo "==================================================="
