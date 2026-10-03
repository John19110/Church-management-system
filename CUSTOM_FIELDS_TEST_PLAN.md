# Custom Fields Test Plan

**Application:** My Church (Church Management System)  
**Module:** Custom Fields  
**Scope basis:** Actual implementation in `Church.API`, `Church.BLL`, `Church.DAL`, and Flutter UI under `Church.Mobile/moble_flutter/lib/features/custom_field`  
**Last updated:** 2026-10-03

## Implementation summary (do not assume more)

| Area | Implemented behavior |
|---|---|
| Attachable entities | `Member`, `Classroom`, `Servant`, `Meeting`, `Church` (`CustomFieldEntityNames`) |
| Data types | `Text`, `LongText`, `Number`, `Decimal`, `Boolean`, `Date`, `DateTime`, `Json`, `SingleSelect`, `MultiSelect` |
| API base | `api/custom-fields` (`CustomFieldController`) |
| Definition CRUD | Create / Update / Activate / Deactivate / Permanent Delete |
| Values | Get entity fields + values; bulk upsert via `PUT api/custom-fields/values` |
| Definition managers | `SuperAdmin`, `Admin` |
| Value writers | `SuperAdmin`, `Admin`, `Servant` |
| Read definitions | Any authenticated user |
| Tenancy | `ChurchId` stamped on save; church-wide defs (`MeetingId` null) visible under meeting scope |
| Built-in fields | Provisioned from `EntityDefaultFieldTemplates`; critical fields cannot be deactivated/deleted |
| UI | Flutter admin screens + dynamic form/detail widgets; role gate `canManageCustomFields` |
| Platforms | Web + mobile Flutter client against the same API |

### Known gaps / non-features (do not write “pass” scenarios for these as if implemented)

1. `EntityExistsAsync` does **not** handle `Church` — saving values for `entityName=Church` fails existence check even though definitions for Church are supported.
2. No dedicated import/export of custom field definitions (member Excel import uses custom field values; that is covered under Integration).
3. No many-to-many relationship model for custom fields (EAV only).
4. Concurrent-edit conflict resolution is last-write-wins via upsert; no optimistic concurrency token.

---

## Role matrix

| Operation | SuperAdmin | Admin | Servant | Unauthenticated |
|---|---|---|---|---|
| Read definitions | Yes (policy: authenticated) | Yes | Yes | No |
| Create/Update/Activate/Deactivate/Delete definition | Yes | Yes | No (403 / UnauthorizedAccessException) | No |
| Read entity values | Yes | Yes | Yes | No |
| Write entity values | Yes | Yes | Yes | No |
| Write read-only field value | Yes (definition manager) | Yes | No (validation error) | No |

---

## A. Field creation

| Test Case ID | Module | Category | Test Scenario | Preconditions | Test Steps | Test Data | Expected Result | Priority | Automation Status |
|---|---|---|---|---|---|---|---|---|---|
| CF-FC-001 | Custom Fields | Functional | Create Text field for Member | Authenticated Admin; ChurchId=1 | POST `definitions` with Text type | `displayName=Baptism Notes`, `entityName=Member`, `dataType=Text` | 201; `name` auto-generated (`baptism_notes`); `isActive=true`; `ChurchId` stamped | Critical | Automated |
| CF-FC-002 | Custom Fields | Functional | Create field for each supported data type | Admin; ChurchId=1 | Create one definition per enum value | Types: Text…MultiSelect (selects include options) | All succeed; stored `DataType` matches request | Critical | Automated |
| CF-FC-003 | Custom Fields | Functional | Create SingleSelect with options | Admin | POST with options list | Options: `A/Alpha`, `B/Beta` | Options persisted; unique per definition | Critical | Automated |
| CF-FC-004 | Custom Fields | Validation | SingleSelect without options rejected | Admin | POST SingleSelect with empty options | `dataType=SingleSelect`, `options=[]` | Validation error on `options` | Critical | Automated |
| CF-FC-005 | Custom Fields | Validation | MultiSelect without options rejected | Admin | POST MultiSelect with null options | `dataType=MultiSelect` | Validation error on `options` | High | Automated |
| CF-FC-006 | Custom Fields | Functional | Required vs optional flag | Admin | Create two fields | `isRequired=true` / `false` | Flags stored as requested | High | Automated |
| CF-FC-007 | Custom Fields | Validation | Invalid default value rejected | Admin | POST Number with non-numeric default | `defaultValue=abc` | Validation error on `defaultValue` | High | Automated |
| CF-FC-008 | Custom Fields | Functional | Valid default value accepted | Admin | POST Boolean with default | `defaultValue=true` | Definition created with default | Medium | Automated |
| CF-FC-009 | Custom Fields | Functional | ValidationRegex stored | Admin | POST Text with regex | `validationRegex=^[A-Z]{3}$` | Regex persisted on definition | Medium | Automated |
| CF-FC-010 | Custom Fields | Functional | Arabic + English display names | Admin | POST with both names | `displayName=Grade`, `displayNameAr=الصف` | Both stored; AR trimmed | Critical | Automated |
| CF-FC-011 | Custom Fields | Validation | Empty displayName rejected | Admin | POST blank displayName | `displayName="   "` | Validation error on `displayName` | Critical | Automated |
| CF-FC-012 | Custom Fields | Validation | Duplicate technical name rejected | Admin; field `notes_extra` exists | POST same `name` + entity | `name=notes_extra`, `entityName=Member` | Validation error: name already exists | Critical | Automated |
| CF-FC-013 | Custom Fields | Validation | Reserved built-in name rejected | Admin | POST `name=name1` for Member | `name=name1` | Validation error: reserved system field | Critical | Automated |
| CF-FC-014 | Custom Fields | Validation | Invalid technical name characters | Admin | POST explicit name | `name=1bad-name!` | Validation error: must start with letter; letters/numbers/underscore only | High | Automated |
| CF-FC-015 | Custom Fields | Validation | Name length > 128 rejected | Admin | POST name of 129 chars | `name=a` + 128 chars | Validation error max 128 | Medium | Automated |
| CF-FC-016 | Custom Fields | Validation | Unsupported entityName rejected | Admin | POST `entityName=Invoice` | — | Validation error entity not supported | Critical | Automated |
| CF-FC-017 | Custom Fields | Functional | Auto-name from Arabic-only displayName | Admin | POST with Arabic display only | `displayName=تاريخ المعمودية` | Name falls back to `field` (or unique `field_N`) because non-latin stripped | Medium | Automated |
| CF-FC-018 | Custom Fields | Functional | Create for Classroom / Servant / Meeting | Admin | POST one field per entity | Entity names from supported set | Each succeeds under tenant | High | Manual |
| CF-FC-019 | Custom Fields | Functional | DisplayPosition reorders sort | Admin; ≥2 active fields | Create with `displayPosition=1` | New field position 1 | New field `sortOrder` becomes first among active | Medium | Not Implemented |
| CF-FC-020 | Custom Fields | Validation | Null request body | Admin | POST with empty body | — | Validation: body required | High | Manual |

---

## B. Field management

| Test Case ID | Module | Category | Test Scenario | Preconditions | Test Steps | Test Data | Expected Result | Priority | Automation Status |
|---|---|---|---|---|---|---|---|---|---|
| CF-FM-001 | Custom Fields | Functional | Update display names | Admin; definition exists | PUT `definitions/{id}` | New EN/AR names | Names updated; `updatedAt` set | Critical | Automated |
| CF-FM-002 | Custom Fields | Functional | Toggle required / hidden / readOnly | Admin | PUT flags | `isRequired`, `isHidden`, `isReadOnly` | Flags updated | High | Automated |
| CF-FM-003 | Custom Fields | Functional | Deactivate then activate | Admin; non-critical field | POST deactivate → activate | — | `isActive` false then true | Critical | Automated |
| CF-FM-004 | Custom Fields | Functional | Permanent delete user field removes values | Admin; field has saved values | DELETE definition | Field id with values | Definition gone; values removed first | Critical | Automated |
| CF-FM-005 | Custom Fields | Validation | Cannot deactivate critical field (`name1`) | Provisioned Member defaults | POST deactivate on `name1` | — | Validation error cannot deactivate | Critical | Automated |
| CF-FM-006 | Custom Fields | Validation | Cannot delete critical field | Provisioned defaults | DELETE `name1` | — | Validation error cannot delete | Critical | Automated |
| CF-FM-007 | Custom Fields | Functional | Built-in non-critical delete tombstones | Provisioned `gender` | DELETE | — | Row remains with `IsPermanentlyDeleted=true`; not re-provisioned | High | Automated |
| CF-FM-008 | Custom Fields | Validation | Incompatible data type change blocked | Field has Number values `"42"` | PUT `dataType=Boolean` | — | Validation: cannot change; check endpoint reports invalid counts | Critical | Automated |
| CF-FM-009 | Custom Fields | Functional | Compatible type change allowed | Field Text values | Check then PUT to LongText | — | `CanChange=true`; update succeeds | High | Automated |
| CF-FM-010 | Custom Fields | Functional | Sync select options (add/update/remove) | SingleSelect exists | PUT options payload | Keep one, add one, omit one | Options match payload | High | Manual |
| CF-FM-011 | Custom Fields | Validation | Built-in data type change blocked | Built-in field | PUT different dataType | — | Validation: system field types cannot change | High | Automated |
| CF-FM-012 | Custom Fields | Functional | Inactive definitions excluded by default | One inactive field | GET `definitions/Member` | `includeInactive=false` | Inactive omitted | High | Automated |
| CF-FM-013 | Custom Fields | Functional | includeInactive returns inactive | Same as above | GET with `includeInactive=true` | — | Inactive included | Medium | Automated |
| CF-FM-014 | Custom Fields | Functional | Get definition by id | Definition exists | GET `definitions/{id}` | — | 200 with DTO | Medium | Manual |
| CF-FM-015 | Custom Fields | Functional | Get missing definition | — | GET `definitions/999999` | — | 404 | Medium | Manual |

---

## C. Data handling

| Test Case ID | Module | Category | Test Scenario | Preconditions | Test Steps | Test Data | Expected Result | Priority | Automation Status |
|---|---|---|---|---|---|---|---|---|---|
| CF-DH-001 | Custom Fields | Functional | Save Text value for Member | Admin; Member id=10; Text field | PUT `values` | Value `"Hello"` | Upserted; GET entity returns value | Critical | Automated |
| CF-DH-002 | Custom Fields | Functional | Update existing value | Value already saved | PUT new value | `"Hello2"` | Same row updated | Critical | Automated |
| CF-DH-003 | Custom Fields | Functional | Clear optional value (null/empty) | Optional field has value | PUT empty string | `value=""` | Stored as null; GET shows empty | High | Automated |
| CF-DH-004 | Custom Fields | Validation | Required field missing rejected | Required field; no prior value | PUT without that field id | Other fields only | Validation: `{DisplayName} is required` | Critical | Automated |
| CF-DH-005 | Custom Fields | Validation | Invalid Number rejected | Number field | PUT `value=12.5` | — | Validation invalid Number | High | Automated |
| CF-DH-006 | Custom Fields | Validation | Invalid Boolean rejected | Boolean field | PUT `value=yes` | — | Validation invalid Boolean | High | Automated |
| CF-DH-007 | Custom Fields | Functional | Boolean normalizes 1/0 | Boolean field | PUT `1` then `0` | — | Stored `true` / `false` | Medium | Automated |
| CF-DH-008 | Custom Fields | Validation | Regex mismatch rejected | Field regex `^[A-Z]{3}$` | PUT `abc` | — | Invalid format | High | Automated |
| CF-DH-009 | Custom Fields | Functional | SingleSelect option value accepted | Options A,B | PUT `A` | — | Saved | High | Automated |
| CF-DH-010 | Custom Fields | Validation | SingleSelect unknown option rejected | Options A,B | PUT `Z` | — | Invalid SingleSelect | High | Automated |
| CF-DH-011 | Custom Fields | Functional | MultiSelect JSON / CSV accepted | Options A,B | PUT `["A","B"]` or `A,B` | — | Normalized JSON array string | High | Automated |
| CF-DH-012 | Custom Fields | Functional | Arabic / Unicode persistence | Text field | PUT `ملاحظات الاختبار 🙏` | — | Round-trip identical | Critical | Automated |
| CF-DH-013 | Custom Fields | Validation | EntityId <= 0 rejected | — | PUT `entityId=0` | — | Validation EntityId must be > 0 | High | Automated |
| CF-DH-014 | Custom Fields | Validation | Unknown definition id rejected | — | PUT unknown definitionId | — | Validation Unknown field definition | High | Automated |
| CF-DH-015 | Custom Fields | Validation | Missing entity instance 404 | — | PUT for Member 999999 | — | NotFoundException / 404 | High | Automated |
| CF-DH-016 | Custom Fields | Validation | Servant cannot write read-only field | Servant; readOnly field | PUT value | — | Validation Field is read-only | Critical | Automated |
| CF-DH-017 | Custom Fields | Functional | Admin can write read-only field | Admin; readOnly field | PUT value | — | Succeeds (definition manager bypass) | High | Automated |
| CF-DH-018 | Custom Fields | Functional | Date / DateTime / Decimal / Json happy paths | Fields of each type | PUT valid samples | `2020-01-01`, ISO datetime, `12.5`, `{"a":1}` | All saved | High | Automated |
| CF-DH-019 | Custom Fields | Functional | Persistence across new DbContext (restart simulation) | Value saved | Dispose context; reopen same SQLite file / connection | — | Value still readable | Medium | Automated |
| CF-DH-020 | Custom Fields | Validation | Church entity value save gap | Church definition exists | PUT `entityName=Church`, `entityId=1` | — | **Actual:** NotFound / entity not found (`EntityExistsAsync` missing Church). Documented bug CF-BUG-001 | Critical | Automated |

---

## D. Permissions and multi-tenancy

| Test Case ID | Module | Category | Test Scenario | Preconditions | Test Steps | Test Data | Expected Result | Priority | Automation Status |
|---|---|---|---|---|---|---|---|---|---|
| CF-SEC-001 | Custom Fields | Security | Servant cannot create definition | Servant role | Call `CreateDefinitionAsync` / POST | Any valid dto | UnauthorizedAccessException / 403 | Critical | Automated |
| CF-SEC-002 | Custom Fields | Security | Servant cannot delete definition | Servant | DELETE | — | Unauthorized / 403 | Critical | Automated |
| CF-SEC-003 | Custom Fields | Security | Unauthenticated cannot write values | `IsAuthenticated=false` | Save values | — | UnauthorizedAccessException | Critical | Automated |
| CF-SEC-004 | Custom Fields | Security | Church A cannot read Church B definition | Def created in Church 1 | Switch tenant ChurchId=2; GetById | — | null / not found (query filter) | Critical | Automated |
| CF-SEC-005 | Custom Fields | Security | Church A cannot save values using Church B definition id | Cross-tenant def id | As Church 2, PUT values with Church1 definitionId | — | Unknown field definition (filtered out of definitions list) | Critical | Automated |
| CF-SEC-006 | Custom Fields | Security | Manipulated Member id from other church | Church1 user | PUT values for Member belonging to Church2 | MemberId=20 Church2 | EntityExists fails under tenant filter → 404 | Critical | Automated |
| CF-SEC-007 | Custom Fields | Security | Meeting-scoped Admin field visibility | Admin MeetingId=1 creates field | SuperAdmin church-wide MeetingId null creates another | Meeting-scoped caller | Sees church-wide + own meeting fields; not other meeting | High | Manual |
| CF-SEC-008 | Custom Fields | Security | API policy ManageDefinitions role gate | Call API with Servant JWT | POST definition | — | 403 | Critical | Manual |
| CF-SEC-009 | Custom Fields | Security | API policy WriteValues role gate | JWT without Servant/Admin/SuperAdmin | PUT values | — | 403 | High | Manual |
| CF-SEC-010 | Custom Fields | Security | SQL injection in Text value stored as data | Text field | PUT `'; DROP TABLE CustomFieldValues;--` | — | Stored as plain text; no SQL execution; schema intact | High | Automated |

---

## E. Integration

| Test Case ID | Module | Category | Test Scenario | Preconditions | Test Steps | Test Data | Expected Result | Priority | Automation Status |
|---|---|---|---|---|---|---|---|---|---|
| CF-INT-001 | Custom Fields | Integration | Member form shows custom fields | Active Member custom fields | Open member create/edit (Flutter) | — | Dynamic fields render by type | High | Manual |
| CF-INT-002 | Custom Fields | Integration | Member detail shows values | Saved values | Open member details | — | `custom_fields_detail_section` shows values | High | Manual |
| CF-INT-003 | Custom Fields | Integration | Member Excel template includes custom columns | Active Member custom fields | Download Excel template | — | Custom columns present (see `MemberExcelServiceTests`) | High | Automated |
| CF-INT-004 | Custom Fields | Integration | Classroom / Servant / Meeting forms | Admin | Open each entity form | — | Custom fields section present when definitions exist | Medium | Manual |
| CF-INT-005 | Custom Fields | Integration | Settings hub role visibility | Servant vs Admin | Open Customization hub | — | Servant cannot open definition management screens | High | Automated (Flutter `settings_ia_test`) |
| CF-INT-006 | Custom Fields | Integration | Default field provisioning on first GET | Fresh tenant | GET definitions/Member | — | Built-in templates provisioned with tenant ChurchId | Critical | Automated |
| CF-INT-007 | Custom Fields | Integration | Web and mobile use same endpoints | Both clients | Trace repository calls | — | Both hit `api/custom-fields/*` | Medium | Manual |

---

## F. Edge cases and security (additional)

| Test Case ID | Module | Category | Test Scenario | Preconditions | Test Steps | Test Data | Expected Result | Priority | Automation Status |
|---|---|---|---|---|---|---|---|---|---|
| CF-EDGE-001 | Custom Fields | Validation | Malformed check-type-change query | Admin | GET check-type-change `newDataType=Nope` | — | Validation invalid data type | Medium | Manual |
| CF-EDGE-002 | Custom Fields | Security | Large Text payload near 8000 chars | Text field | PUT 8000-char string | — | Saves if ≤8000; DB max length enforced | Medium | Not Implemented |
| CF-EDGE-003 | Custom Fields | Functional | Concurrent upserts last write wins | Two writers | Parallel PUT different values | — | Final value is one of the writes; no crash | Medium | Not Implemented |
| CF-EDGE-004 | Custom Fields | Validation | Invalid Json type rejected | Json field | PUT `not-json` | — | Validation invalid Json | High | Automated |
| CF-EDGE-005 | Custom Fields | Functional | Deactivated field excluded from entity GET | Field deactivated; value existed | GET entity fields | — | Definition omitted from active defs; value not returned in filtered list | High | Automated |

---

## Identified bugs

### CF-BUG-001 — Church entity values not writable
- **Where:** `CustomFieldRepository.EntityExistsAsync` switch omits `CustomFieldEntityNames.Church`
- **Steps:** Create Church custom field definition; `PUT /api/custom-fields/values` with `entityName=Church`, `entityId=<valid church id>`
- **Expected:** Entity exists; values upsert
- **Actual:** `NotFoundException` / “Church with id X was not found”
- **Status:** Open (covered by CF-DH-020)

---

## Sample data bank

```json
{
  "text": "Baptism certificate note",
  "textAr": "ملاحظة شهادة المعمودية",
  "number": "42",
  "decimal": "12.50",
  "boolean": "true",
  "date": "2015-06-15",
  "dateTime": "2015-06-15T10:30:00",
  "json": "{\"level\":\"A\"}",
  "singleSelect": "A",
  "multiSelect": "[\"A\",\"B\"]",
  "options": [
    { "value": "A", "displayText": "Alpha", "sortOrder": 1 },
    { "value": "B", "displayText": "Beta", "sortOrder": 2 }
  ]
}
```

## API quick reference

| Method | Path | Policy |
|---|---|---|
| GET | `/api/custom-fields/definitions/{id}` | ReadDefinitions |
| GET | `/api/custom-fields/definitions/{entityName}` | ReadDefinitions |
| POST | `/api/custom-fields/definitions` | ManageDefinitions |
| PUT | `/api/custom-fields/definitions/{id}` | ManageDefinitions |
| POST | `/api/custom-fields/definitions/{id}/deactivate` | ManageDefinitions |
| POST | `/api/custom-fields/definitions/{id}/activate` | ManageDefinitions |
| DELETE | `/api/custom-fields/definitions/{id}` | ManageDefinitions |
| GET | `/api/custom-fields/definitions/{id}/check-type-change` | ManageDefinitions |
| GET | `/api/custom-fields/entities/{entityName}/{entityId}` | ReadDefinitions |
| PUT | `/api/custom-fields/values` | WriteValues |
