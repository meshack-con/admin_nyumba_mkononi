#!/bin/bash
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:$(pwd)/flutter/bin"
flutter config --enable-web
flutter pub get
flutter build web --release --dart-define=API_BASE_URL=https://nyumba-mkononi-backend.onrender.com
