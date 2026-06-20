# ChatIOS

iOS frontend for a realtime private chat application.

The project is built with SwiftUI and integrates with a FastAPI backend through REST API and WebSocket.  
Backend repository: https://github.com/RomanSinenko/chat

## What This Project Demonstrates

- SwiftUI application structure
- REST API integration
- WebSocket connection for realtime events
- Authorization through bearer token
- Chat list screen
- Private chat screen
- Message history loading
- User search by username
- Opening or creating private chats
- Unread message counters
- Draft storage per chat
- Scroll position handling in chat
- Loading and error states

## Tech Stack

- Swift
- SwiftUI
- URLSession
- URLSessionWebSocketTask
- Combine
- REST API
- WebSocket
- JSON decoding
- Xcode

## Main Screens

- Start screen with temporary phone login
- Chats list
- New message / user search
- Private chat screen

## Backend Integration

The app works with a local backend service:

```text
http://127.0.0.1:8000
