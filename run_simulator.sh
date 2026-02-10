#!/bin/bash

# FreedivingAI 시뮬레이터 실행 스크립트
# 사용법: ./run_simulator.sh

echo "🏊 FreedivingAI 시뮬레이터 실행 중..."
echo ""

# freediving_ai 디렉토리로 이동
cd freediving_ai || { echo "❌ freediving_ai 디렉토리를 찾을 수 없습니다."; exit 1; }

# Flutter 의존성 확인
echo "📦 의존성 확인 중..."
flutter pub get > /dev/null 2>&1

# 사용 가능한 디바이스 확인
echo ""
echo "📱 사용 가능한 시뮬레이터:"
flutter devices | grep iPhone

echo ""
echo "🚀 앱을 실행합니다..."
echo "   (시뮬레이터가 자동으로 열립니다)"
echo ""

# Flutter 앱 실행 (디바이스 자동 선택)
flutter run

echo ""
echo "✅ 완료!"
