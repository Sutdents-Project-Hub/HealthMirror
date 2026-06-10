# App README

## 模組簡介

`app/` 是 HealthMirror 的 Flutter 行動 App。原型支援在設定頁一鍵 random 生成健康資料、手動輸入、規則式風險判讀、未來自我提示、每週報告、小目標回饋，以及可選 AI 建議設定。

## 使用技術

- Flutter 3.41.9
- Dart 3.11.5
- `shared_preferences`：本機儲存健康資料、目標回饋與 AI 設定
- `http`：由 App 直接呼叫使用者設定的 AI API

## 資料夾結構

```text
lib/
├── main.dart
├── models/
│   └── health_models.dart
├── screens/
│   ├── dashboard_screen.dart
│   ├── data_screen.dart
│   ├── goals_screen.dart
│   ├── report_screen.dart
│   └── settings_screen.dart
├── services/
│   ├── ai_client.dart
│   ├── health_analyzer.dart
│   ├── health_mirror_controller.dart
│   └── local_store.dart
├── theme/
│   └── app_theme.dart
└── widgets/
```

## 本地開發流程

```bash
cd app
flutter pub get
flutter run
```

常用檢查：

```bash
flutter analyze
flutter test
```

## 環境變數

不需要 `.env`。AI 設定在 App 內填寫：

- `API URL`：OpenAI-compatible chat completions endpoint。
- `API Key`：若 API 需要 Bearer token，填入此欄。
- `模型名稱`：依 API 供應商設定。

## 建置 / 啟動方式

Android：

```bash
flutter build apk
```

iOS：

```bash
flutter build ios
```

啟動模擬器或連接裝置後：

```bash
flutter run
```

## 部署細節

此模組是行動 App，不透過 Coolify 部署。後續若要上架，需補齊正式圖示、bundle id、簽章、隱私權政策與 App Store / Google Play metadata。

## 常見問題

### 沒有 API Key 能不能展示？

可以。App 會先使用規則式分析產生健康分數、風險判讀、週報與小目標。AI 只作為加值建議。

### 展示時沒有穿戴裝置怎麼辦？

到設定頁按「一鍵 Random 生成資料」，App 會在本機建立 14 日睡眠、步數、活動分鐘、心率、HRV、久坐與就寢時間資料。

### 資料會送到後端嗎？

不會。本原型沒有後端。只有在設定頁啟用 AI 並填寫 API URL 後，App 才會直接把摘要資料送到該 URL。
