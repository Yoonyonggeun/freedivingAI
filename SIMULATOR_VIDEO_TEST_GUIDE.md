# 시뮬레이터에서 영상 분석 테스트 가이드

## 문제: 갤러리에서 영상 선택이 안 됨

업데이트된 코드에 디버깅 로그가 추가되었습니다. 이제 터미널에서 상세한 로그를 확인할 수 있습니다.

---

## 해결 방법

### 방법 1: 시뮬레이터에 영상 추가하기 (권장)

#### 단계 1: 테스트 영상 준비
수영 동작이 포함된 5-10초 영상을 준비합니다.

**테스트용 영상 다운로드 방법:**
1. YouTube에서 "freestyle swimming side view" 검색
2. 짧은 클립 다운로드 (또는 화면 녹화)
3. MP4 형식으로 저장

또는 간단한 테스트용으로:
```bash
# 샘플 비디오 생성 (테스트용)
# 실제 수영 영상이 없다면 이것으로 테스트 가능
ffmpeg -f lavfi -i testsrc=duration=5:size=1280x720:rate=30 \
  -f lavfi -i sine=frequency=1000:duration=5 \
  -pix_fmt yuv420p ~/Desktop/test_video.mp4
```

#### 단계 2: 시뮬레이터에 영상 추가

**방법 A: 드래그 앤 드롭 (가장 쉬움)**
```bash
# 1. 시뮬레이터 실행
flutter run

# 2. Finder에서 영상 파일 찾기
# 3. 시뮬레이터 창으로 드래그 앤 드롭
# 4. 시뮬레이터의 "사진" 앱에서 확인
```

**방법 B: 명령어 사용**
```bash
# 시뮬레이터에 영상 추가
xcrun simctl addmedia booted ~/Desktop/test_video.mp4

# 여러 개 추가
xcrun simctl addmedia booted ~/Desktop/*.mp4
```

**방법 C: Safari를 통해 다운로드**
1. 시뮬레이터에서 Safari 열기
2. 테스트 영상 URL 방문
3. 다운로드하여 사진 앱에 저장

#### 단계 3: 영상 확인
```bash
# 시뮬레이터의 "사진(Photos)" 앱을 열어서
# 영상이 정상적으로 추가되었는지 확인
```

#### 단계 4: 앱에서 테스트
```bash
# 1. 앱 재실행 (또는 이미 실행 중이면 계속 진행)
flutter run

# 2. Dynamic Training 메뉴
# 3. Discipline 선택 (DYN)
# 4. Category 선택 (Streamline)
# 5. "Choose from Gallery" 버튼 클릭
# 6. 추가한 영상 선택
# 7. 분석 시작
```

#### 단계 5: 로그 확인
터미널에서 다음과 같은 로그가 출력됩니다:
```
🎬 Starting video picker from gallery...
📱 Opening image picker...
✅ Video picker returned: /path/to/video.mp4
🎥 Video selected: /path/to/video.mp4
📊 Starting analysis...
```

---

### 방법 2: 녹화 기능 사용 (시뮬레이터 한계 있음)

시뮬레이터는 실제 카메라가 없어서 "Record Video" 버튼은 작동하지 않을 수 있습니다.
**실제 기기에서 테스트하는 것을 권장합니다.**

---

### 방법 3: 실제 기기에서 테스트 (최고 정확도)

```bash
# 1. iPhone/iPad를 Mac에 연결
# 2. 기기 확인
flutter devices

# 3. 실제 기기에서 실행
flutter run -d <device-id>

# 4. 앱에서 직접 녹화 또는 갤러리 선택
```

---

## 트러블슈팅

### 문제 1: "Choose from Gallery" 클릭 시 아무 반응 없음

**원인:**
- 시뮬레이터에 영상이 없음
- 권한 문제

**해결:**
```bash
# 1. 시뮬레이터 재시작
flutter clean
flutter run

# 2. 영상 다시 추가
xcrun simctl addmedia booted ~/Desktop/test_video.mp4

# 3. 시뮬레이터의 사진 앱에서 영상 확인
```

### 문제 2: 영상 선택 후 분석 시작 안 됨

**터미널 로그 확인:**
```
❌ Video selection cancelled or null
```

이 메시지가 나오면:
- 사용자가 취소함
- 또는 영상 경로가 null

**해결:**
```bash
# 앱 재실행
flutter run

# 영상 다시 추가
xcrun simctl addmedia booted ~/Desktop/test_video.mp4
```

### 문제 3: "Error picking video" 메시지

**터미널 로그 확인:**
```
❌ ERROR picking video: [에러 메시지]
Error type: [에러 타입]
```

**일반적인 에러:**

#### 에러: "PlatformException"
```bash
# image_picker 플러그인 문제
# 해결: 앱 재빌드
flutter clean
flutter pub get
flutter run
```

#### 에러: "Photo library access denied"
```bash
# 권한 거부됨
# 해결: 시뮬레이터 설정에서 권한 허용
# Settings > Privacy > Photos > Freediving AI > Allow
```

### 문제 4: 영상 선택 UI가 이상함

**iOS 버전 문제일 수 있습니다.**

```bash
# 시뮬레이터 확인
xcrun simctl list devices

# iOS 15 이상 시뮬레이터 사용 권장
```

---

## 실제 테스트 시나리오

### 시나리오 1: 간단한 테스트 (권장)

```bash
# 1. 테스트 영상 생성
cd ~/Desktop
# 간단한 5초 테스트 영상 (실제 수영 영상이 없을 때)

# 2. 시뮬레이터에 추가
xcrun simctl addmedia booted ~/Desktop/test_video.mp4

# 3. 앱 실행
cd freediving_ai
flutter run

# 4. 앱에서 테스트
# - Dynamic Training
# - DYN > Streamline
# - Choose from Gallery
# - test_video.mp4 선택
# - 분석 시작

# 5. 결과 확인
# - Overall Score 표시
# - Category Scores 표시
# - Strengths/Improvements 표시
```

### 시나리오 2: 실제 수영 영상 테스트

```bash
# 1. YouTube에서 수영 영상 다운로드
# "freestyle swimming side view"

# 2. 영상을 ~/Desktop에 저장
# swimming_test.mp4

# 3. 시뮬레이터에 추가
xcrun simctl addmedia booted ~/Desktop/swimming_test.mp4

# 4. 앱에서 분석
# - Choose from Gallery
# - swimming_test.mp4 선택
# - 5-10초 대기
# - 결과 확인

# 5. V2 데이터 확인 (터미널 로그)
# 분석 중에 V2 메트릭 데이터가 출력됨
```

---

## 예상 결과

### 성공 케이스

**터미널 로그:**
```
🎬 Starting video picker from gallery...
📱 Opening image picker...
✅ Video picker returned: /path/to/video.mp4
🎥 Video selected: /path/to/video.mp4
📊 Starting analysis...

Analyzing your technique...
[분석 진행 로그...]

=== V2 DATA ===
Version: 2.0
Confidence: 0.75
[메트릭 데이터...]
```

**앱 UI:**
```
✅ Analysis Result Screen 표시
✅ Overall Score: 65-85
✅ Category Scores 표시
✅ Strengths 리스트
✅ Improvements 리스트
```

### 실패 케이스

**케이스 1: 영상 선택 취소**
```
🎬 Starting video picker from gallery...
📱 Opening image picker...
✅ Video picker returned: null (user cancelled)
❌ Video selection cancelled or null
```
→ 정상 동작 (사용자가 취소함)

**케이스 2: 에러 발생**
```
🎬 Starting video picker from gallery...
📱 Opening image picker...
❌ ERROR picking video: [에러 메시지]
Error type: PlatformException
```
→ 앱 재빌드 필요

---

## 시뮬레이터 제한사항

### 작동하는 것 ✅
- ✅ 갤러리에서 영상 선택
- ✅ 영상 분석
- ✅ 결과 표시
- ✅ V2 메트릭 계산

### 작동하지 않는 것 ❌
- ❌ 카메라 녹화 (실제 카메라 없음)
- ❌ 일부 영상 포맷 (codec 문제)
- ❌ 매우 큰 영상 파일 (메모리 제한)

### 권장사항
- **시뮬레이터**: 기본 기능 테스트, UI 확인용
- **실제 기기**: 최종 테스트, 실제 녹화 및 분석 정확도 확인

---

## 빠른 테스트 체크리스트

### 준비
- [ ] 테스트 영상 준비 (5-10초, MP4)
- [ ] 시뮬레이터 실행 중

### 영상 추가
- [ ] 드래그 앤 드롭 또는 `xcrun simctl addmedia` 사용
- [ ] 시뮬레이터 "사진" 앱에서 영상 확인

### 앱 테스트
- [ ] `flutter run` 실행
- [ ] Dynamic Training 메뉴 진입
- [ ] Discipline & Category 선택
- [ ] "Choose from Gallery" 클릭
- [ ] 영상 선택
- [ ] 분석 시작 확인

### 결과 확인
- [ ] 터미널 로그 확인 (🎬 → 📱 → ✅ → 🎥 → 📊)
- [ ] 앱 UI에서 결과 표시 확인
- [ ] Overall Score 확인
- [ ] V2 데이터 확인 (선택사항)

---

## 다음 단계

1. **기본 테스트 완료** ✅
   - 시뮬레이터에서 갤러리 선택 작동 확인
   - 분석 완료 확인

2. **실제 기기 테스트**
   - iPhone/iPad 연결
   - 실제 수영 녹화
   - 분석 정확도 검증

3. **V2 메트릭 확인**
   - 터미널 로그에서 V2 데이터 확인
   - 정규화 작동 확인
   - 신뢰도 점수 확인

4. **프로덕션 배포**
   - 모든 테스트 통과
   - 실제 사용자 테스트
   - 점진적 롤아웃

---

**문제가 계속되면:**
- 터미널 로그 전체 복사
- 에러 메시지 확인
- 시뮬레이터 버전 확인
- 앱 재빌드 시도
