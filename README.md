# FreqTalk: Tactical Walkie-Talkie

A production-ready cross-platform walkie-talkie app for Android and Windows.

## Features
- **Online Mode**: Global communication via WebRTC and a Socket.io signaling server.
- **Offline Mode (Android)**: Direct P2P communication via Wi-Fi Direct.
- **Offline Mode (Windows/Local)**: High-speed UDP Multicast for local network communication.
- **Real Walkie-Talkie Experience**: Half-duplex PTT, haptic feedback, and low-latency audio.

## Project Structure
- `lib/main.dart`: Entry point.
- `lib/services/`: Core logic for Audio, WebRTC, P2P, and UDP.
- `lib/ui/`: Tactical Glassmorphism UI components.
- `server/`: Node.js signaling server.

## Setup Instructions

### 1. Flutter App
1. Ensure you have Flutter installed.
2. Run `flutter pub get` in the root directory.
3. **Android**: Connect a device and run `flutter run`.
4. **Windows**: Run `flutter run -d windows`.

### 2. Signaling Server (For Online Mode)
1. Navigate to the `server/` directory.
2. Run `npm install`.
3. Run `node server.js`.
4. **Note**: Update `serverUrl` in `lib/services/webrtc_service.dart` with your server's IP address.

## How to Test
1. **Online**: Open the app on two devices, set the same frequency, and press PTT.
2. **Offline**: 
   - On Android: Enable Wi-Fi (no internet needed) and use the P2P discovery.
   - On Windows/Local: Ensure both are on the same Wi-Fi/LAN, set the same frequency, and talk.

## Permissions
The app requires:
- Microphone access.
- Location (for Wi-Fi Direct on Android).
- Nearby Devices (Android 13+).
- Network access.
