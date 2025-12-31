## 1.0.2

* **NEW FEATURE**: Smart Tajweed Feedback
  * Implemented `TajweedFeedbackService` to analyze specific pronunciation errors.
  * Provides detailed feedback for common mistakes (e.g., "Qaf vs Kaf", "Sad vs Sin", missing Madd).
  * Replaces generic "approximate match" messages with actionable correction advice.

## 1.0.1

* **CRITICAL FIXES**:
  * Fixed Gemini Live API connection by updating to `gemini-2.0-flash-exp` model.
  * Resolved WebSocket disconnection and "stuck buffer" issues.
  * Fixed Verse marker rendering and skipping logic.

* **NEW FEATURES**:
  * **JSON Result Export**: Added `RecitationResult` model and `onRecitationComplete` callback for easy integration.
  * **English Localization**: Full English UI for Recitation Report and error messages.
  * **Full Quran Navigation**: Direct page jump (1-604) and Surah selector.

* **IMPROVEMENTS**:
  * Updated font to **IndoPak** for better readability.
  * Added `const` optimizations for performance.
  * Enhanced error logging for Gemini service.

* **BREAKING CHANGES**:
  * Constructor parameter: `RecitationScreen(initialPageNumber: ...)` (was `pageNumber`).
## 1.0.0

* Initial release of the Flutter Quran Tajweed Recitation Assistant.
* Features include:
  * Real-time Tajweed analysis using Gemini Live API.
  * Audio recording and playback.
  * Quran text display with highlighting.
