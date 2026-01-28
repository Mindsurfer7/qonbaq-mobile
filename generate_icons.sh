#!/bin/bash

# Скрипт для генерации иконок приложения из SVG файла
# Требует ImageMagick (convert)

SVG_FILE="assets/images/logo.svg"
TEMP_DIR="temp_icons"

# Создаем временную директорию
mkdir -p "$TEMP_DIR"

echo "Генерация иконок из $SVG_FILE..."

# Функция для генерации PNG из SVG
generate_icon() {
    local size=$1
    local output=$2
    echo "Генерация $output (${size}x${size})..."
    magick -background none -density 300 "$SVG_FILE" -resize "${size}x${size}" "$output"
}

# Android иконки
echo "Генерация Android иконок..."
generate_icon 48 "android/app/src/main/res/mipmap-mdpi/ic_launcher.png"
generate_icon 72 "android/app/src/main/res/mipmap-hdpi/ic_launcher.png"
generate_icon 96 "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png"
generate_icon 144 "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png"
generate_icon 192 "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"

# iOS иконки
echo "Генерация iOS иконок..."
generate_icon 20 "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png"
generate_icon 40 "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png"
generate_icon 60 "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png"
generate_icon 29 "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png"
generate_icon 58 "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png"
generate_icon 87 "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png"
generate_icon 40 "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png"
generate_icon 80 "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png"
generate_icon 120 "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png"
generate_icon 120 "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png"
generate_icon 180 "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png"
generate_icon 76 "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png"
generate_icon 152 "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png"
generate_icon 167 "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png"
generate_icon 1024 "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png"

# macOS иконки
echo "Генерация macOS иконок..."
generate_icon 16 "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png"
generate_icon 32 "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png"
generate_icon 64 "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png"
generate_icon 128 "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png"
generate_icon 256 "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png"
generate_icon 512 "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png"
generate_icon 1024 "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png"

# Web иконки
echo "Генерация Web иконок..."
generate_icon 32 "web/favicon.png"
generate_icon 192 "web/icons/Icon-192.png"
generate_icon 512 "web/icons/Icon-512.png"
# Maskable иконки - те же размеры, но с padding для безопасной зоны
generate_icon 192 "$TEMP_DIR/icon-192-temp.png"
magick "$TEMP_DIR/icon-192-temp.png" -gravity center -background white -extent 192x192 "web/icons/Icon-maskable-192.png"
generate_icon 512 "$TEMP_DIR/icon-512-temp.png"
magick "$TEMP_DIR/icon-512-temp.png" -gravity center -background white -extent 512x512 "web/icons/Icon-maskable-512.png"

# Удаляем временную директорию
rm -rf "$TEMP_DIR"

echo "Генерация иконок завершена!"
