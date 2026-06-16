# Zen Reminder

Zen Reminder is a native macOS background app scaffold for voice-created reminders.

It runs as an accessory app with no normal application window. Press the global shortcut to open a small bottom-center listening pill with audio waves and an aurora-style glass gradient, speak a reminder, press the shortcut again, and the app transcribes the audio, extracts the reminder intent, stores it locally, and schedules a native macOS notification.

## Requirements

- macOS 14 or newer
- Xcode 15 or newer
- Microphone and speech recognition permissions

## Open

Open `ZenReminder.xcodeproj` in Xcode and run the `ZenReminder` scheme.

The app is configured as `LSUIElement`, so it does not appear in the Dock and does not create a main window. The only persistent UI is the menu bar item.

## Shortcut

Default shortcut: `Control + Option + Space`

Press once to start listening, press again to finish and schedule the reminder.

## Models

Models are intentionally not bundled in the app. On first bootstrap, the app downloads them into:

`~/Library/Application Support/ZenReminder/Models`

Default model assets:

- Speech-to-text: `ggml-base.en.bin` from `ggerganov/whisper.cpp`
- Intent understanding: `qwen2.5-0.5b-instruct-q4_k_m.gguf` from `Qwen/Qwen2.5-0.5B-Instruct-GGUF`

The scaffold currently uses native on-device `Speech` transcription so the user flow works before a Whisper runtime is linked. `ModelBootstrapper`, `ModelCatalog`, and the `SpeechTranscriber` protocol are isolated so a Whisper runtime can be dropped in without changing app flow.

The intent parser is local and deterministic for the scaffold. The downloaded Qwen GGUF asset is bootstrapped and ready for a llama.cpp-backed `IntentUnderstandingModel` implementation.

## Current Architecture

- `AppDelegate`: app lifecycle, background mode, orchestration
- `StatusMenuController`: menu bar item and settings surface
- `HotKeyController`: global native Carbon hotkey registration
- `AudioCaptureController`: microphone capture to a temporary WAV file
- `NativeSpeechTranscriber`: on-device macOS speech transcription
- `ReminderIntentParser`: local reminder extraction
- `ReminderStore`: JSON reminder persistence
- `ReminderScheduler`: native `UNUserNotificationCenter` delivery
- `ListeningOverlayController`: transient bottom-center pill UI
- `ModelBootstrapper`: first-run model download into Application Support
