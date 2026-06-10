# HealthMirror 未來自我投射鏡

## 專案簡介

HealthMirror 是依「未來自我投射鏡 - AI 智慧健康預警與行為介入系統」作品說明書製作的 Flutter App 原型。系統把睡眠、步數、活動分鐘、心率、HRV、久坐與作息資料轉成健康趨勢分數、未來自我提示、每週報告與可執行小目標。

本專題定位為健康促進與生活型態管理輔助，不做疾病診斷，也不取代醫師建議。

## 功能列表

- 鏡面/平板式總覽：健康趨勢分數、未來自我提示、今日指標、風險判讀。
- 穿戴資料輸入：可在設定頁一鍵 random 生成 14 日模擬資料，也可手動填寫今日資料。
- 規則式分析：辨識連續睡眠不足、活動量下降、久坐過長、晚睡頻率增加與恢復狀態偏緊繃。
- 每週健康報告：顯示睡眠達標天數、平均步數、久坐中斷目標、原型驗證指標。
- 小目標管理：提供 1 至 3 個低門檻目標，記錄提醒接受、完成狀態與使用者回饋。
- AI 設定：在 App 設定 API URL、API Key 與模型名稱，由 App 直接呼叫 OpenAI-compatible API。

## 技術架構

- App：Flutter 3.41.9、Dart 3.11.5。
- 本機儲存：`shared_preferences`。
- AI 呼叫：`http`，由 App 直接呼叫使用者設定的 API URL。
- 分析方式：原型先用可解釋規則，未來可替換為機器學習模型。
- 後端：本專題目前不需要後端。

## 專案結構

```text
.
├── AGENTS.md
├── README.md
└── app/
    ├── README.md
    ├── lib/
    │   ├── main.dart
    │   ├── models/
    │   ├── screens/
    │   ├── services/
    │   ├── theme/
    │   └── widgets/
    └── test/
```

## 本地測試教學

```bash
cd app
flutter pub get
flutter analyze
flutter test
flutter run
```

## 環境變數

目前沒有必要環境變數。AI API URL、API Key 與模型名稱由 App 設定頁輸入並儲存在本機。

## Coolify 部署教學

本專題是 Flutter 行動 App 原型，不需要 Coolify 部署。若未來新增 Web 或後端模組，需在對應模組 README 補上 Coolify 設定流程。

## 前端 / 後端詳細文件連結

- App 詳細文件：[app/README.md](app/README.md)
- 後端：目前未建立後端模組。
