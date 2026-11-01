#!/bin/bash
set -e

echo "=== Setting up Flutter SDK ==="
if [ ! -d "_flutter" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable _flutter
fi

export PATH="$PATH:`pwd`/_flutter/bin"

echo "=== Flutter Version ==="
flutter --version

echo "=== Compiling Flutter Web Application ==="
flutter build web --release

echo "=== Ensuring Vercel SPA Config in build/web ==="
cp vercel.json build/web/vercel.json 2>/dev/null || true

echo "=== Deployment Ready ==="

