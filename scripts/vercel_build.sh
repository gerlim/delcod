#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.24.5}"
FLUTTER_ROOT="${FLUTTER_ROOT:-$HOME/flutter-sdk}"

if [[ -z "${SUPABASE_URL:-}" ]]; then
  echo "SUPABASE_URL is required for the Vercel build." >&2
  exit 1
fi

if [[ -z "${SUPABASE_ANON_KEY:-}" ]]; then
  echo "SUPABASE_ANON_KEY is required for the Vercel build." >&2
  exit 1
fi

if [[ ! -x "$FLUTTER_ROOT/bin/flutter" ]]; then
  git clone \
    --branch "$FLUTTER_VERSION" \
    --depth 1 \
    https://github.com/flutter/flutter.git \
    "$FLUTTER_ROOT"
fi

export PATH="$FLUTTER_ROOT/bin:$PATH"

flutter --version
flutter config --enable-web
flutter pub get
flutter build web \
  --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=APP_ENV="${APP_ENV:-production}"
