#!/bin/bash

# BrainSAIT Enterprise Mobile App Startup Script
# This script helps you get the app running quickly

echo "🧠 BrainSAIT Enterprise Mobile App - برينسايت المؤسسي 🧠"
echo "=================================================="
echo ""

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo "🔍 Checking prerequisites..."

# Check Node.js
if command_exists node; then
    NODE_VERSION=$(node --version)
    echo "✅ Node.js: $NODE_VERSION"
else
    echo "❌ Node.js not found. Please install Node.js 18+ from https://nodejs.org"
    exit 1
fi

# Check npm
if command_exists npm; then
    NPM_VERSION=$(npm --version)
    echo "✅ npm: $NPM_VERSION"
else
    echo "❌ npm not found. Please install npm"
    exit 1
fi

# Check Expo CLI
if command_exists expo; then
    EXPO_VERSION=$(expo --version)
    echo "✅ Expo CLI: $EXPO_VERSION"
else
    echo "⚠️  Expo CLI not found. Installing globally..."
    npm install -g @expo/cli
fi

# Check for dependencies
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
else
    echo "✅ Dependencies already installed"
fi

echo ""
echo "🚀 Starting options:"
echo "1. Start development server (all platforms)"
echo "2. Start for iOS simulator"
echo "3. Start for Android emulator"
echo "4. Start for web browser"
echo "5. Type check only"
echo "6. Clean and restart"
echo ""

read -p "Choose an option (1-6): " choice

case $choice in
    1)
        echo "🚀 Starting development server for all platforms..."
        npm start
        ;;
    2)
        echo "📱 Starting for iOS simulator..."
        if command_exists xcodebuild; then
            npm run ios
        else
            echo "❌ Xcode not found. Please install Xcode from the App Store for iOS development."
        fi
        ;;
    3)
        echo "🤖 Starting for Android emulator..."
        if command_exists adb; then
            npm run android
        else
            echo "❌ Android SDK not found. Please install Android Studio for Android development."
        fi
        ;;
    4)
        echo "🌐 Starting for web browser..."
        npm run web
        ;;
    5)
        echo "🔍 Running TypeScript type check..."
        npm run type-check
        ;;
    6)
        echo "🧹 Cleaning and restarting..."
        npm run clean
        npm install
        npm start
        ;;
    *)
        echo "Invalid choice. Starting development server..."
        npm start
        ;;
esac