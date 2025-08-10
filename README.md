# Wiz - iOS Walkie Talkie App

A real-time voice communication iOS app built with SwiftUI, featuring push-to-talk functionality and background audio support.

<div align="center">
  <img src="https://github.com/user-attachments/assets/093c0fa0-cf8d-42ac-817c-9165d3949d58" width="300" alt="Demo 1">
  <img src="https://github.com/user-attachments/assets/c9729059-8164-4899-a5a7-665b5bca0e92" width="300" alt="Demo 2">
</div>

## Technical Stack

- **Frontend**: SwiftUI + UIKit
- **Real-time Audio**: LiveKit WebRTC
- **Animations**: Rive motion graphics
- **Backend**: Firebase + Google Cloud Functions
- **Networking**: gRPC protocol buffers
- **Authentication**: Google, Kakao, Facebook, Apple Sign-In

## Key Features

- Push-to-talk voice communication with visual feedback
- Background audio processing for uninterrupted calls
- Real-time friend system with presence indicators  
- Custom audio session management for iOS
- Smooth UI animations and haptic feedback
- Cross-platform notification system

## Architecture

- **MVVM pattern** with ObservableObject view models
- **Manager classes** for core functionality (Audio, LiveKit, Auth, Notifications)
- **Background task management** for iOS lifecycle handling
- **Custom collection view** implementation for friend grid
- **Protocol buffer** definitions for efficient data transmission
