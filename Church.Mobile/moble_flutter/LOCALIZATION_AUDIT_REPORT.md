# Localization Audit Report

**Date:** 2026-05-24  
**Scope:** `SunDaySchools.Mobile/moble_flutter` — English (`en`) and Arabic (`ar`)  
**Goal:** 100% user-facing text coverage, RTL support, instant language switching

---

## Summary

The Flutter app uses a custom `AppLocalizations` class (`lib/core/l10n/app_localizations.dart`) with ~200+ translation keys in both English and Arabic. Language is switched via `localeProvider` and applied to `MaterialApp.locale` without requiring an app restart.

This audit identified and fixed hardcoded strings across auth screens, admin flows, attendance, members/servants, custom fields, unified forms, routing, validators, and error handling.

### Coverage status

| Area | Status |
|------|--------|
| Main / dashboard screens | Localized |
| Settings / profile | Localized |
| Auth (login, register) | Localized |
| Auth registration success copy | Localized |
| Super admin / admin screens | Localized |
| Classrooms / meetings | Localized |
| Members / servants | Localized |
| Attendance (take, history, view) | Localized |
| Custom fields (admin + entity values) | Localized |
| Unified entity forms | Localized |
| Form validation messages | Localized (EN/AR templates) |
| Error / snackbar messages | Localized via `userFriendlyMessage(error, l10n)` |
| Route missing-data screens | Localized |
| Bottom navigation | Localized (existing) |
| RTL layout | Automatic via Flutter `Locale('ar')` |

---

## Files Modified

### Core

| File | Changes |
|------|---------|
| `lib/core/l10n/app_localizations.dart` | Added getters: `entityChurch`, validation templates, auth-disabled flows, attendance extras, error strings, `forLocale()` helper |
| `lib/core/error/app_exception.dart` | `userFriendlyMessage(error, l10n)`; `UnauthorizedException` / `NetworkException` resolved via l10n |
| `lib/core/routing/app_router.dart` | `_MissingRouteDataScreen` uses `titleBuilder`; edit routes use localized titles |
| `lib/main.dart` | App title uses `AppLocalizations(locale).sundaySchool` |

### Auth

| File | Changes |
|------|---------|
| `lib/features/auth/screens/login_screen.dart` | Brand text, error messages |
| `lib/features/auth/screens/register_screen.dart` | Registration success message, errors |
| `lib/features/auth/screens/forgot_password_screen.dart` | Disabled-flow stub localized |
| `lib/features/auth/screens/otp_verification_screen.dart` | Disabled-flow stub localized |
| `lib/features/auth/screens/reset_password_screen.dart` | Disabled-flow stub localized |

### Admin / Super admin

| File | Changes |
|------|---------|
| `lib/features/super_admin/screens/super_admin_home_screen.dart` | Time hint, meeting summary, errors |
| `lib/features/super_admin/screens/super_admin_pending_admins_screen.dart` | Reject confirmation dialog |
| `lib/features/admin/screens/admin_pending_servants_screen.dart` | Reject confirmation dialog |

### Classrooms / Meetings

| File | Changes |
|------|---------|
| `lib/features/classroom/screens/classrooms_home_screen.dart` | Loading title, placeholders |
| `lib/features/classroom/screens/classroom_detail_screen.dart` | Display title fallback |
| `lib/features/meeting/screens/meeting_detail_screen.dart` | Empty name list placeholder |

### Members / Servants

| File | Changes |
|------|---------|
| `lib/features/member/screens/members_list_screen.dart` | Unknown name, missing ID message |
| `lib/features/member/screens/member_detail_screen.dart` | Invalid ID message |
| `lib/features/member/screens/member_edit_screen.dart` | Invalid ID message |
| `lib/features/servant/screens/servants_list_screen.dart` | Unknown name, missing ID message |

### Attendance

| File | Changes |
|------|---------|
| `lib/features/attendance/screens/attendance_history_screen.dart` | Title, empty state, session labels |
| `lib/features/attendance/screens/attendance_view_screen.dart` | Session title, member fallback, yes/no |
| `lib/features/attendance/screens/attendance_take_screen.dart` | Member fallback, localized errors |

### Custom fields / Unified forms

| File | Changes |
|------|---------|
| `lib/features/custom_field/utils/custom_field_validator.dart` | All validation via l10n templates |
| `lib/features/custom_field/widgets/dynamic_custom_field_widget.dart` | Validators, hints |
| `lib/features/custom_field/widgets/dynamic_custom_fields_form.dart` | Section title, load error |
| `lib/features/custom_field/widgets/custom_fields_detail_section.dart` | Section title, yes/no |
| `lib/features/custom_field/screens/entity_custom_fields_edit_screen.dart` | Title, save button, messages |
| `lib/features/unified_form/utils/unified_form_validator.dart` | All validation via l10n |
| `lib/features/unified_form/utils/unified_form_field_utils.dart` | `notAvailable` placeholder |
| `lib/features/unified_form/widgets/unified_form_field_widget.dart` | Passes l10n to validator |
| `lib/features/unified_form/widgets/unified_entity_form.dart` | Yes/no, not-available display |
| `lib/features/unified_form/widgets/unified_entity_detail_header.dart` | Localized title/initial |

---

## Hardcoded Strings Removed (representative)

| Before | After (key) |
|--------|-------------|
| `"Church"` | `churchBrand` |
| `'Registration successful. Please sign in.'` | `registrationSuccessfulPleaseSignIn` |
| Auth registration success | `registrationSuccessfulPleaseSignIn` |
| `'Back to login'` | `backToLogin` |
| `'Visible Classrooms'` | `visibleClassrooms` |
| `'Servants: X • Members: Y'` | `meetingServantsMembersSummary` |
| `'HH:mm'` | `timeFormatHint` |
| `'Attendance history • …'` | `attendanceHistoryTitle()` |
| `'No attendance sessions yet.'` | `noAttendanceSessionsYet` |
| `'Member #N'` | `memberNumberLabel(N)` |
| `'Yes'` / `'No'` | `yes` / `no` |
| `'Unknown'` | `unknownName` |
| `'—'` / `'-'` | `notAvailable` |
| `'{name} is required'` (validators) | `fieldIsRequired(name)` |
| Route titles (`'Edit meeting'`, etc.) | `editMeeting`, `editChurch`, etc. |
| `'Additional fields'` | `additionalFields` |
| `'This will reject {name}.'` | `rejectUserConfirm(name)` |
| Session/network error strings | `sessionExpiredPleaseSignIn`, `networkErrorTryAgain`, etc. |

---

## Missing Translations Found & Fixed

All identified user-facing strings now have both `en` and `ar` entries in `app_localizations.dart`. Key additions in this pass:

- Auth disabled flow messages (`passwordResetDisabled`, `phoneVerificationDisabled`)
- Validation templates (`fieldIsRequired`, `fieldMustBeNumber`, etc.)
- Attendance extras (`noAttendanceSessionsYet`, `sessionNumber`, `recordsCountLabel`)
- API/ID errors (`invalidMemberId`, `memberIdMissingFromApi`, `servantIdMissingFromApi`)
- Routing titles (`editMeeting`, `editChurch`, `classroomDetails`, `customFieldValues`)
- Custom field UI (`additionalFields`, `saveAdditionalFields`, `failedToLoadCustomFields`)
- Error fallbacks (`genericErrorTryAgain`, `somethingWentWrongTryAgain`, `serverErrorTryLater`)

---

## Localization Issues Fixed

1. **Validators** — `CustomFieldValidator` and `UnifiedFormValidator` now accept `AppLocalizations` and produce localized messages.
2. **Error handling** — `userFriendlyMessage(error, l10n)` localizes session expiry, network errors, and technical exceptions.
3. **Route guards** — Missing route data screens use localized titles from context.
4. **Instant switching** — `localeProvider` updates `MaterialApp.locale`; all `AppLocalizations.of(context)` widgets rebuild automatically.
5. **RTL** — Arabic locale triggers Flutter's built-in RTL mirroring (text direction, layout). No manual restart required.
6. **Placeholders** — Boolean and empty-value displays use `yes`/`no`/`notAvailable` instead of English literals.

---

## Remaining Notes (non-blocking)

| Item | Notes |
|------|-------|
| Language toggle label `EN` / `AR` | Intentional ISO codes on dashboard/profile toggles; shows target language |
| Auth registration success screens | Localized registration completion message |
| Repository `throw Exception('...')` strings | Shown via `userFriendlyMessage()` which sanitizes technical text; could be migrated to typed exceptions with l10n keys in a follow-up |
| `AttendanceStatus.label` in model | Unused; screens use localized `_statusLabel()` |
| API error bodies from server | Displayed as returned (typically English from backend); client-side fallbacks are localized |
| Date/time display | Uses API strings / `TimeOfDay.format(context)` — respects locale for time picker |

---

## RTL Verification

- `MaterialApp` sets `locale` from `localeProvider` (`en` / `ar`).
- Flutter automatically applies `TextDirection.rtl` for Arabic.
- `Alignment.centerRight` in commented login code is inactive.
- Icons (`chevron_right`) mirror under RTL via framework defaults.
- Numbers in summaries use Western digits (standard for Arabic UI in many apps); dates come from API.

---

## Testing Checklist

- [ ] Toggle EN ↔ AR on login — brand, fields, buttons update without restart
- [ ] Register flow — validation messages in both languages
- [ ] Super admin home — meeting dialog, list subtitles
- [ ] Classrooms home — loading title, age/member labels
- [ ] Attendance take/history/view — session labels, yes/no chips
- [ ] Members/servants lists — unknown name, missing ID snackbar
- [ ] Custom fields edit — section title, save, validation
- [ ] Pending admin/servant reject dialogs
- [ ] Invalid route data screens (navigate with bad IDs)
- [ ] RTL: verify back chevrons, form alignment, dialog button order in Arabic

---

## Analyzer

`dart analyze lib` — no errors; pre-existing warnings only (deprecated `DropdownButtonFormField.value`, unused parameters).
