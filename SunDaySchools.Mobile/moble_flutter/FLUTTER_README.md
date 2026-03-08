# Sunday School Management System — Flutter Mobile App

This Flutter application is located in `SunDaySchools.Mobile/moble_flutter` and provides a
mobile interface for managing children, servants, and attendance sessions via the ASP.NET
Web API backend included in this repository.

---

## How to Run

### Prerequisites
- Flutter SDK ≥ 3.0 (<https://docs.flutter.dev/get-started/install>)
- An emulator/physical device
- The ASP.NET backend running (see below for base URL configuration)

### Steps

```bash
cd SunDaySchools.Mobile/moble_flutter

# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run
```

---

## How to Configure the API Base URL

Open `lib/core/constants/app_constants.dart` and change the `baseUrl` constant:

```dart
static const String baseUrl = 'http://10.0.2.2:5000';
```

| Target             | Example URL                  |
|--------------------|------------------------------|
| Android emulator   | `http://10.0.2.2:<port>`     |
| iOS simulator      | `http://localhost:<port>`    |
| Physical device    | `http://<your-machine-ip>:<port>` |

> **Note**: `10.0.2.2` is the loopback address for the host machine when using
> the Android emulator. Replace `5000` with the actual port your backend listens on.

---

## Architecture Overview

```
lib/
├── core/
│   ├── api/          # Dio HTTP client with JWT interceptor
│   ├── constants/    # AppConstants (base URL, endpoint paths)
│   ├── error/        # AppException, DioException mapping
│   ├── routing/      # GoRouter configuration
│   ├── storage/      # flutter_secure_storage JWT wrapper
│   └── theme/        # Material 3 theme (Poppins, soft blues)
├── features/
│   ├── auth/         # Login & Register screens, AuthRepository
│   ├── dashboard/    # Home screen with quick-access cards
│   ├── children/     # List, Detail, Add, Edit screens + ChildrenRepository
│   ├── servants/     # List, Detail, Add, Edit screens + ServantsRepository
│   └── attendance/   # Take Attendance, View Session screens + AttendanceRepository
└── shared/
    └── widgets/      # Reusable widgets (AppTextField, AppDateField, snackbars, dialogs)
```

### State Management
[flutter_riverpod](https://riverpod.dev/) — `Provider`, `FutureProvider`, `StateProvider`.

### Navigation
[go_router](https://pub.dev/packages/go_router) with redirect guard (token-based auth check).

### HTTP
[dio](https://pub.dev/packages/dio) — `_AuthInterceptor` injects `Authorization: Bearer <token>`
on every request. `401` responses are mapped to `UnauthorizedException`.

### Storage
[flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) — JWT token is stored
under the key `jwt_token`.

---

## Integration Assumptions

1. **Login / Register** — The API returns the raw JWT string in the response body (not wrapped
   in a JSON object). The app reads `response.data as String`.

2. **Register** uses `multipart/form-data`. Fields: `Name`, `PhoneNumber`, `Password`,
   `ConfirmPassword`.

3. **Servant create/update** also uses `multipart/form-data`, including an optional `Image` file.

4. **Attendance records** use integer enum values: Present=1, Absent=2, Late=3, Excused=4.

5. Route casing follows the backend exactly:
   - `Api/Account/...` (capital A, capital A)
   - `api/Children/...` (lowercase a, capital C)
   - `api/servant/...` (lowercase a, lowercase s)
   - `api/AttendanceSession/...` (lowercase a, capital A, capital S)

6. All authenticated endpoints require `Authorization: Bearer <token>` — handled automatically
   by the Dio interceptor after login.
