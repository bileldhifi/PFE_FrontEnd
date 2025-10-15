# Authentication Setup Guide

## ✅ What's Been Implemented

The authentication system has been fully implemented to connect with your Spring Boot backend. Here's what's ready:

### 🔧 Backend Integration
- **API Client**: Configured for `http://localhost:8089/app-backend`
- **Token Management**: Automatic Bearer token handling
- **Error Handling**: Proper error messages and status codes
- **Secure Storage**: Tokens stored in Flutter Secure Storage

### 📱 Flutter Implementation
- **Auth Repository**: Complete CRUD operations for auth
- **Auth Controller**: Riverpod state management
- **DTOs**: Matching your backend exactly
- **UI Integration**: Login, Register, Forgot Password screens

## 🚀 How to Run

### 1. Start Your Backend
Make sure your Spring Boot backend is running on:
```
http://localhost:8089/app-backend
```

### 2. Generate Code
Run the code generation script:
```bash
./generate_code.sh
```

Or manually:
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### 3. Run Flutter App
```bash
flutter run
```

## 🔄 Authentication Flow

```
App Start → Splash Screen → Check Auth Status
    ↓
Not Authenticated → Login Screen → Login → Save Token → Home
    ↓
Authenticated → Home Screen (token auto-added to requests)
```

## 📋 API Endpoints Used

- `POST /auth/login` - Login with email/password
- `POST /auth/register` - Register new user
- `POST /auth/forgot-password` - Send reset email
- `POST /auth/reset-password` - Reset password with token
- `GET /users/me` - Get current user profile

## 🧪 Testing

1. **Register**: Create a new account
2. **Login**: Use valid credentials
3. **Navigation**: Should automatically navigate to home
4. **Persistence**: Close and reopen app - should stay logged in
5. **Logout**: Clear token and return to login

## 🐛 Troubleshooting

### Code Generation Errors
If you see Freezed errors:
```bash
# Clean and regenerate
find lib -name "*.freezed.dart" -delete
find lib -name "*.g.dart" -delete
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Connection Errors
- Ensure backend is running on port 8089
- Check if backend has CORS enabled (for web)
- Verify the base URL in `lib/core/network/api_client.dart`

### Authentication Errors
- Check if user exists in backend database
- Verify password encoding matches backend
- Check backend logs for detailed error messages

## 📁 Key Files

- `lib/core/network/api_client.dart` - HTTP client configuration
- `lib/auth/data/repo/auth_repository.dart` - API calls
- `lib/auth/presentation/controllers/auth_controller.dart` - State management
- `lib/auth/data/dtos/` - Request/Response models

## 🔐 Security Features

- ✅ JWT token storage in secure storage
- ✅ Automatic token refresh handling
- ✅ 401 error handling with auto-logout
- ✅ HTTPS support (when backend uses HTTPS)
- ✅ Input validation and sanitization
