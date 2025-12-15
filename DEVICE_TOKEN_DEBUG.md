# Device Token Registration Debugging Guide

## Issue
Device token is not being registered after login.

## Root Causes to Check

### 1. **Authentication Token Missing** (Most Common)
The device registration requires an auth token from SessionManager, but it may not be saved properly.

**Check:**
- Login successfully and verify token is saved
- In FCM service logs, check if auth token is found: `[DEBUG] Auth TOKEN: ...` should show the token, not `NULL`
- If it shows `NULL`, the token was never saved to SharedPreferences

**Solution if found:**
```dart
// In login_screen.dart, verify this is called:
await _sessionManager.saveToken(token);
```

---

### 2. **FCM Token Not Available**
The app may not have obtained a Firebase Cloud Messaging token yet.

**Check:**
- Logs should show: `[DEBUG] FCM TOKEN: ...` with an actual token value
- If it shows `NULL`, Firebase initialization may have failed

**Solution if found:**
- Ensure Firebase is initialized in main.dart before FcmService.init()
- Check that FCM permissions are granted on the device

---

### 3. **FCM Permissions Not Granted**
Even with valid tokens, if permissions are denied, the device won't be registered.

**Check logs for:**
```
[INFO] Platform: android  (or ios/web)
```

If you don't see this log, the permission request may have failed.

**Solution if found:**
- Grant notification permissions on device settings
- Call `FcmService.instance.init()` which requests permissions

---

### 4. **API Endpoint Failure**
The /api/notification-device endpoint may be rejecting the request.

**Check logs for:**
```
[ERROR] Unable to register notification device: 
```

Common reasons:
- Invalid request body format
- Auth token expired
- Backend validation failure

---

## How to Debug

### Option A: Use the Debug Screen (Recommended)
1. Add this route to your main.dart routes:
```dart
"/debug/device-token": (context) => const DeviceTokenDebugScreen(),
```

2. Navigate to `/debug/device-token` after login
3. Tap "Run Debug Test" and check the logs

---

### Option B: Check Logs in Terminal
1. Run the app in debug mode: `flutter run`
2. After login, look for logs starting with `[DEBUG]`, `[INFO]`, `[ERROR]`, `[SUCCESS]`
3. Key things to find:

**If you see:**
```
[DEBUG] FCM TOKEN: <actual-token>
[DEBUG] Auth TOKEN: <actual-token>
[INFO] Registering notification device
[SUCCESS] Device registration response
```
✅ Everything is working!

**If you see:**
```
[DEBUG] FCM TOKEN: <actual-token>
[DEBUG] Auth TOKEN: NULL
```
❌ Auth token not saved. Check login flow.

**If you see:**
```
[DEBUG] FCM TOKEN: NULL
```
❌ FCM not initialized. Check Firebase setup.

---

## Files Modified with Enhanced Logging

1. **lib/services/notification_service.dart** - Added detailed logging in `registerDevice()`
2. **lib/services/fcm_service.dart** - Enhanced logging in `_sendTokenToBackend()` and `ensureDeviceRegistered()`
3. **lib/screens/debug/device_token_debug_screen.dart** - New debug UI screen
4. **lib/services/notification_service_debug.dart** - Debug version with test method

---

## Quick Checklist

- [ ] Is the app showing `[INFO] ensureDeviceRegistered() called` after login?
- [ ] Does auth token show as found (not NULL)?
- [ ] Does FCM token show as found (not NULL)?
- [ ] Do you see `[SUCCESS] Device registration response`?
- [ ] Check backend API logs for any rejection messages
- [ ] Verify `/api/notification-device` endpoint exists and is correctly mapped
- [ ] Check that the request body format matches backend expectations

---

## Advanced: Check with curl
After getting an auth token from login, test the endpoint directly:

```bash
curl -X POST https://your-api.com/api/notification-device \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "token": "firebase_device_token_here",
    "platform": "android",
    "app_version": "1.0.0"
  }'
```

This tells you if the backend endpoint is working correctly.
