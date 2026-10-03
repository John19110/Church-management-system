# Test Coverage Report — Custom Fields & Custom Features

**Date:** 2026-10-03  
**Scope:** Custom Fields + Custom Features modules in My Church  
**Artifacts:**
- `CUSTOM_FIELDS_TEST_PLAN.md`
- `CUSTOM_FEATURES_TEST_PLAN.md`
- `Church.Tests/CustomFieldValidatorTests.cs` (new)
- `Church.Tests/CustomFieldManagerTests.cs` (new)
- `Church.Tests/CustomFeatureManagerTests.cs` (extended)
- Existing: `MemberExcelServiceTests.cs`, Flutter `settings_ia_test.dart`, `custom_feature_labels_test.dart`

---

## 1. Execution status (authoritative)

| Run | Result |
|---|---|
| `dotnet build Church.Tests` | **Succeeded** |
| `dotnet test` filter CustomField/CustomFeature | **Could not execute assertions** |

**Blocker (diagnosed):** Windows 11 **Smart App Control** inbox App Control policy `VerifiedAndReputableDesktop`  
Policy ID `{0283ac0f-fff1-49ae-ada1-8a933130cad6}` (Enforce).

- Code Integrity Event **3077**: `testhost.exe` blocked loading unsigned `Church.DAL.dll` (“Enterprise signing level requirements”).
- Registry: `VerifiedAndReputablePolicyState = 1` (Enforce).
- `Church.DAL.dll` has **no** `Zone.Identifier` ADS — `Unblock-File` cannot fix this.
- All local `Church.*.dll` outputs are **NotSigned**; NuGet/test-host assemblies are Microsoft/xUnit-signed and load.
- This is **not** a Church.Tests / Church.DAL project-reference or MOTW issue. No repository code change can satisfy SAC for unsigned local Debug builds without changing the OS policy.

Per project rules: **no scenario is marked Passed** because no test completed its assertions successfully in this environment.

**To run locally after allowing the policy (or on CI without WDAC):**

```powershell
dotnet test Church.Tests\Church.Tests.csproj --filter "FullyQualifiedName~CustomField|FullyQualifiedName~CustomFeature"
```

---

## 2. What the implementation actually covers

### Custom Fields — implemented

| Capability | Location |
|---|---|
| Definition CRUD + activate/deactivate/delete | `CustomFieldController`, `CustomFieldManager` |
| EAV values upsert | `PUT api/custom-fields/values` |
| Types Text…MultiSelect | `CustomFieldDataType` + `CustomFieldValidator` |
| Entities Member/Classroom/Servant/Meeting/Church | `CustomFieldEntityNames` |
| Roles: manage = Admin/SuperAdmin; write values = +Servant | `CustomFieldPolicies` |
| Tenant filters + SaveChanges ChurchId stamp | `ProgramContext` |
| Built-in provisioning / critical locks | `EntityDefaultFieldTemplates` |
| Flutter admin + dynamic form/detail | `lib/features/custom_field` |

### Custom Features — implemented

| Capability | Location |
|---|---|
| Feature/entity/field/permission/record lifecycle | `CustomFeatureManager` + controllers |
| Limits 20/15/40 + 64KB JSON | Manager constants + `CustomEntityRecordValidator` |
| Refs: Member/Servant/Entity(+multi) same-feature | Manager + `CustomEntityRecordReference` |
| View flags ShowOnList/Form/Details | Field model + Flutter screens |
| Default Servant read-only; overridable | `DefaultPermissions` / `UpdatePermissionsAsync` |
| SuperAdmin church-wide vs Admin meeting-scoped | `ResolveCreatedMeetingId` |
| Flutter List/Form/Details | `record_*_screen.dart` |

---

## 3. Scenario coverage summary

| Module | Scenarios in plan | Targeted by new/extended automated tests | Manual / UI / API-host | Not implemented automation |
|---|---:|---:|---:|---:|
| Custom Fields | ~70 | ~35 Critical/High manager+validator cases | ~25 | ~10 |
| Custom Features | ~75 | ~25 (8 pre-existing + ~17 new) | ~35 | ~15 |

Automation Status in the plan files means **test code exists or is designated**, not that a green run was observed here.

### Highest-priority automated mappings

| Plan IDs | Test method (class) |
|---|---|
| CF-FC-001..016 (subset) | `CustomFieldManagerTests` create/validation |
| CF-DH-* type/regex/select | `CustomFieldValidatorTests` + save tests |
| CF-SEC-001..006, CF-DH-020 | tenant/role/Church gap tests |
| CF-FM-* deactivate/delete/type-change | manager lifecycle tests |
| CFE-FC/EN/REL/PERM/MT subset | `CustomFeatureManagerTests` existing + new |

---

## 4. Missing coverage / risks

| Risk | Severity | Notes |
|---|---|---|
| **CF-BUG-001** Church value save broken | Critical | `EntityExistsAsync` omits `Church` — automated regression asserted as current failure mode |
| No ASP.NET integration tests for policy 401/403 | High | Manager tests cover UnauthorizedAccessException; HTTP policies need `WebApplicationFactory` |
| Meeting-scoped vs church-wide field visibility | High | Manual CF-SEC-007 |
| Flutter List/Form/Details view flags | Medium | Manual CFE-VW-* |
| Concurrent upserts / large 8000-char values | Medium | Not automated |
| Max 40 fields stress | Low | Limit code exists; no loop test (slow) |
| UpdatePermissions omitting roles zeros them | Medium | Documented; tests now send full matrix |
| WDAC blocks local test execution | Process | CI or policy exception required |

---

## 5. Identified bugs (not fixed — out of scope)

### CF-BUG-001 — Church custom field values cannot be saved
- **File:** `Church.DAL/Repository/Implementations/CustomFieldRepository.cs` → `EntityExistsAsync`
- **Expected:** `entityName=Church` resolves via `db.Churches`
- **Actual:** falls through to `false` → `NotFoundException`
- **Test:** `CustomFieldManagerTests.Church_entity_value_save_is_broken_EntityExists_gap`

### CFE-NOTE-001 — Deleting a referenced custom record
- **Actual (implemented):** repository deletes incoming `CustomEntityRecordReference` rows, then deletes the record (clears dependents’ links rather than blocking delete).
- Plan case CFE-REL-009 updated to match.

---

## 6. Proposed future enhancements (not implemented)

1. Fix `EntityExistsAsync` for `Church`.
2. Add `WebApplicationFactory` API tests for auth policies and JSON enum contracts.
3. Add Flutter widget/integration tests for record List/Form/Details column flags.
4. Optimistic concurrency or audit trail for custom field value writes.
5. Explicit import/export for custom feature schemas.

---

## 7. Deliverables checklist

| Deliverable | Status |
|---|---|
| `CUSTOM_FIELDS_TEST_PLAN.md` | Done |
| `CUSTOM_FEATURES_TEST_PLAN.md` | Done |
| `TEST_COVERAGE_REPORT.md` | Done |
| Automated tests in `Church.Tests` | Done (compile OK) |
| Tests executed green | **Blocked by WDAC on this host** |
