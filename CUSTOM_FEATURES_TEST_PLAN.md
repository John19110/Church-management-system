# Custom Features Test Plan

**Application:** My Church (Church Management System)  
**Module:** Custom Features (configurable mini-domains)  
**Scope basis:** Actual implementation in `CustomFeatureController`, `CustomEntityController`, `CustomFeatureManager`, DAL models under `Church.DAL/Models/CustomFeatures`, Flutter UI under `lib/features/custom_feature`  
**Last updated:** 2026-10-03

## Implementation summary (do not assume more)

| Area | Implemented behavior |
|---|---|
| Feature | Name, DisplayName, DisplayNameAr, IsActive; church-scoped; SuperAdmin creates church-wide (`MeetingId=null`); Admin stamps tenant `MeetingId` |
| Limits | Max 20 features/church; 15 entities/feature; 40 fields/entity; record JSON ≤ 64KB |
| Entity | Fields, Permissions, Records; plural display names |
| Field types | Text, LongText, Number, Decimal, Boolean, Date, Time, DateTime, Phone, Email, Url, Dropdown, MultiSelect, MemberReference, ServantReference, EntityReference, EntityMultiReference |
| Relationships | Single/multi refs to Member, Servant, or same-feature CustomEntity records (not true M:N join tables) |
| Views | Per-field flags `ShowOnList`, `ShowOnForm`, `ShowOnDetails` (UI-driven; no separate view config entity) |
| Permissions | Per-entity role matrix SuperAdmin/Admin/Servant with CanCreate/Read/Update/Delete |
| Default perms | SuperAdmin & Admin full CRUD; Servant read-only |
| Record API | Search, sort, paging (`page`, `pageSize` 1–100) |
| Delete | Feature/entity/field/record permanent delete; feature cascade removes children |
| UI platforms | Flutter List / Form / Details screens for records |

### Non-features / gaps

1. No separate List/Form/Details “view configuration” objects — only field visibility flags.
2. No many-to-many junction entity beyond `EntityMultiReference` id lists.
3. Deleting a parent custom record that is referenced uses FK `Restrict` on references — expect failure or blocked delete depending on repository path (verify CFE-REL-006).
4. No import/export of custom feature schemas or records.
5. Inactive feature/entity returns “Entity not found” for record ops (soft hide).

---

## Role matrix

| Operation | SuperAdmin | Admin | Servant (defaults) |
|---|---|---|---|
| Manage feature/entity/field/permissions metadata | Yes | Yes | No |
| Read features/entities | Yes | Yes | Yes (authenticated) |
| Read records | Yes | Yes | Yes (CanRead) |
| Create/Update/Delete records | Yes | Yes | No unless permissions updated |
| Update permissions | Yes | Yes | No |

---

## A. Feature configuration

| Test Case ID | Module | Category | Test Scenario | Preconditions | Test Steps | Test Data | Expected Result | Priority | Automation Status |
|---|---|---|---|---|---|---|---|---|---|
| CFE-FC-001 | Custom Features | Functional | Create feature | SuperAdmin Church1 | CreateFeature | `displayName=Bus Management`, `displayNameAr=إدارة الأتوبيس` | Active; `name=bus_management`; `MeetingId=null` | Critical | Automated |
| CFE-FC-002 | Custom Features | Functional | Update feature info / deactivate | Feature exists | UpdateFeature | New names; `isActive=false` | Updated; inactive | Critical | Automated |
| CFE-FC-003 | Custom Features | Functional | Re-enable feature | Inactive feature | Update `isActive=true` | — | Active again | High | Automated |
| CFE-FC-004 | Custom Features | Functional | Delete feature cascades | Feature with entity, field, record | DeleteFeature | — | Features/Entities/Records empty | Critical | Automated |
| CFE-FC-005 | Custom Features | Validation | Empty displayName rejected | Admin/SuperAdmin | CreateFeature | `displayName=" "` | Validation on displayName | Critical | Automated |
| CFE-FC-006 | Custom Features | Validation | Duplicate feature name rejected | Feature `inventory` exists | Create with same name | `name=inventory` | Validation name already exists | Critical | Automated |
| CFE-FC-007 | Custom Features | Validation | Invalid technical name | — | Create `name=1bad` | — | Validation name format | High | Automated |
| CFE-FC-008 | Custom Features | Validation | Max 20 features enforced | 20 features exist | Create 21st | — | Validation at most 20 | High | Automated |
| CFE-FC-009 | Custom Features | Functional | Multiple features same church | Church1 | Create two features | Transport, Inventory | Both listed for Church1 | Critical | Automated |
| CFE-FC-010 | Custom Features | Functional | GetFeatures hides inactive by default | One inactive | GetFeatures(false/true) | — | Filtered correctly | Medium | Automated |
| CFE-FC-011 | Custom Features | Security | Servant cannot create feature | Servant | CreateFeature | — | UnauthorizedAccessException | Critical | Automated |

---

## B. Custom entities and fields

| Test Case ID | Module | Category | Test Scenario | Preconditions | Test Steps | Test Data | Expected Result | Priority | Automation Status |
|---|---|---|---|---|---|---|---|---|---|
| CFE-EN-001 | Custom Features | Functional | Create entity with default permissions | Feature exists | CreateEntity | `displayName=Bus` | Plural default `Buss` or provided; 3 permission rows; Servant read-only | Critical | Automated |
| CFE-EN-002 | Custom Features | Functional | Update entity plural / active / sort | Entity exists | UpdateEntity | Plural AR/EN; sortOrder | Updated | High | Automated |
| CFE-EN-003 | Custom Features | Validation | Update without plural rejected | — | Update empty plural | — | Validation pluralDisplayName required | Medium | Automated |
| CFE-EN-004 | Custom Features | Functional | Delete entity | Entity with fields/records | DeleteEntity | — | Entity removed | High | Automated |
| CFE-EN-005 | Custom Features | Validation | Max 15 entities | 15 entities | Create 16th | — | Validation at most 15 | Medium | Automated |
| CFE-EN-006 | Custom Features | Functional | Create Text / Number / Email / Dropdown fields | Entity exists | CreateField each type | Dropdown needs options | All succeed | Critical | Automated |
| CFE-EN-007 | Custom Features | Validation | Dropdown without options rejected | — | CreateField Dropdown | No options | Validation options required | Critical | Automated |
| CFE-EN-008 | Custom Features | Functional | Required + unique flags | — | CreateField | `isRequired=true`, `isUnique=true` | Flags stored | Critical | Automated |
| CFE-EN-009 | Custom Features | Functional | Update field view flags | Field exists | UpdateField | `showOnList=false`, form/details true | Flags updated | High | Automated |
| CFE-EN-010 | Custom Features | Functional | Delete field | Field exists | DeleteField | — | Field removed | High | Automated |
| CFE-EN-011 | Custom Features | Validation | Duplicate field name rejected | Field `code` exists | CreateField same name | — | Validation name exists | Critical | Automated |
| CFE-EN-012 | Custom Features | Validation | Max 40 fields | 40 fields | Create 41st | — | Validation at most 40 | Medium | Not Implemented |
| CFE-EN-013 | Custom Features | Functional | Create record with required Text | Field required | CreateRecord | `code=A1` | Record created; values returned | Critical | Automated |
| CFE-EN-014 | Custom Features | Functional | Update record | Record exists | UpdateRecord | New values | UpdatedAt set; values changed | Critical | Automated |
| CFE-EN-015 | Custom Features | Functional | Delete record | Record exists | DeleteRecord | — | Record gone; GET returns null | Critical | Automated |
| CFE-EN-016 | Custom Features | Validation | Required field missing | Required Text | CreateRecord empty | — | Validation required | Critical | Automated |
| CFE-EN-017 | Custom Features | Validation | Unique field duplicate | Unique Text; value exists | Create second same value | — | Validation must be unique | Critical | Automated |
| CFE-EN-018 | Custom Features | Validation | Invalid Email / Number / Date | Typed fields | CreateRecord bad values | `email=x`, `number=x` | Type validation errors | High | Automated |
| CFE-EN-019 | Custom Features | Functional | Arabic text in record | Text field | CreateRecord | `الاسم` | Persisted and returned | Critical | Automated |
| CFE-EN-020 | Custom Features | Validation | Payload > 64KB rejected | Large LongText | CreateRecord huge string | — | Validation payload too large | High | Automated |
| CFE-EN-021 | Custom Features | Functional | Large volume paging | ≥50 records | GetRecords pageSize=20 | — | Total correct; page items ≤20 | Medium | Automated |

---

## C. Relationships

| Test Case ID | Module | Category | Test Scenario | Preconditions | Test Steps | Test Data | Expected Result | Priority | Automation Status |
|---|---|---|---|---|---|---|---|---|---|
| CFE-REL-001 | Custom Features | Functional | MemberReference in-tenant | Member id=10 Church1 | CreateRecord `{member:10}` | — | Value 10 + `memberLabel` | Critical | Automated |
| CFE-REL-002 | Custom Features | Security | MemberReference cross-tenant rejected | Member id=20 Church2 | CreateRecord `{member:20}` | — | Validation referenced member not found | Critical | Automated |
| CFE-REL-003 | Custom Features | Functional | ServantReference in-tenant | Servant seeded Church1 | CreateRecord | — | Succeeds with label | High | Automated |
| CFE-REL-004 | Custom Features | Functional | EntityReference same feature | Two entities; target record exists | CreateField targetEntityId; CreateRecord | Target record id | Reference stored | Critical | Automated |
| CFE-REL-005 | Custom Features | Validation | EntityReference other feature rejected | Target in feature B | CreateField from feature A | — | Validation same feature required | Critical | Automated |
| CFE-REL-006 | Custom Features | Validation | EntityMultiReference accepts list | Multi ref field | CreateRecord `[id1,id2]` | — | Both refs stored | High | Automated |
| CFE-REL-007 | Custom Features | Validation | Single ref rejects multiple ids | MemberReference | CreateRecord `[10,11]` | — | Validation accepts one value | High | Automated |
| CFE-REL-008 | Custom Features | Validation | Invalid / missing target record | EntityReference | CreateRecord unknown id | — | Validation not found | High | Automated |
| CFE-REL-009 | Custom Features | Functional | Delete parent record with dependents | Record A referenced by B | Delete A | — | **Actual:** `DeleteRecordAsync` removes incoming refs then deletes parent (no orphan refs) | High | Automated |
| CFE-REL-010 | Custom Features | Validation | targetEntityId on non-ref field rejected | Text field create | Set targetEntityId | — | Validation only entity refs may set target | Medium | Automated |

---

## D. Views (List / Form / Details)

| Test Case ID | Module | Category | Test Scenario | Preconditions | Test Steps | Test Data | Expected Result | Priority | Automation Status |
|---|---|---|---|---|---|---|---|---|---|
| CFE-VW-001 | Custom Features | Functional | List shows ShowOnList columns only | Mixed flags | Open record list UI / inspect column helper | — | Only `showOnList=true` columns | High | Manual |
| CFE-VW-002 | Custom Features | Functional | List empty state | No records | Open list | — | Empty UI; API total=0 | Medium | Manual |
| CFE-VW-003 | Custom Features | Functional | List search / sort / paging | Many records | GET records `search`, `sort`, `page` | — | Filtered/sorted page returned | High | Automated |
| CFE-VW-004 | Custom Features | Functional | Form shows ShowOnForm fields | Mixed flags | Open create form | — | Only form fields; required still validated server-side if `ShowOnForm\|\|IsRequired` | High | Manual |
| CFE-VW-005 | Custom Features | Functional | Form validation required | Required field | Submit empty | — | Client + server errors | High | Manual |
| CFE-VW-006 | Custom Features | Functional | Details shows ShowOnDetails + labels | Record with MemberRef | Open details | — | Details fields + memberLabel | High | Manual |
| CFE-VW-007 | Custom Features | Functional | Changing view flags reflected in UI | Field showOnList toggled | Refresh list | — | Column appears/disappears | Medium | Manual |

---

## E. Feature permissions

| Test Case ID | Module | Category | Test Scenario | Preconditions | Test Steps | Test Data | Expected Result | Priority | Automation Status |
|---|---|---|---|---|---|---|---|---|---|
| CFE-PERM-001 | Custom Features | Security | Default Servant cannot create records | Fresh entity | Servant CreateRecord | — | UnauthorizedAccessException | Critical | Automated |
| CFE-PERM-002 | Custom Features | Security | Grant Servant CanCreate | Admin updates permissions | Servant CreateRecord | CanCreate=true | Succeeds | Critical | Automated |
| CFE-PERM-003 | Custom Features | Security | Deny Servant CanRead | Permissions CanRead=false | Servant GetRecords | — | Unauthorized | Critical | Automated |
| CFE-PERM-004 | Custom Features | Security | Deny update/delete | CanUpdate/Delete false | Servant update/delete | — | Unauthorized | High | Automated |
| CFE-PERM-005 | Custom Features | Security | Direct API bypass attempt with Servant JWT | Metadata endpoints | POST feature / PUT permissions | — | 403 ManageMetadata | Critical | Manual |
| CFE-PERM-006 | Custom Features | Security | Manipulated entityId from other church | Church2 entity id | Church1 GetRecords | — | Not found (tenant filter) | Critical | Automated |
| CFE-PERM-007 | Custom Features | Functional | Get/Update permissions as Admin | Entity exists | GET/PUT permissions | Role matrix | Persisted for SuperAdmin/Admin/Servant only | High | Automated |
| CFE-PERM-008 | Custom Features | Security | Inactive feature blocks record ops | Feature isActive=false | CreateRecord | — | NotFoundException Entity not found | High | Automated |

---

## F. Multi-tenancy

| Test Case ID | Module | Category | Test Scenario | Preconditions | Test Steps | Test Data | Expected Result | Priority | Automation Status |
|---|---|---|---|---|---|---|---|---|---|
| CFE-MT-001 | Custom Features | Security | Church A cannot read Church B feature | Feature in Church1 | Switch tenant to Church2; GetById | — | null; list empty | Critical | Automated |
| CFE-MT-002 | Custom Features | Security | Church A cannot read Church B records | Record in Church1 | Church2 GetRecord | — | Not found | Critical | Automated |
| CFE-MT-003 | Custom Features | Security | Cross-tenant entity reference blocked | See CFE-REL-002 | — | — | Validation failure | Critical | Automated |
| CFE-MT-004 | Custom Features | Security | Cross-feature entity target blocked | See CFE-REL-005 | — | — | Validation failure | Critical | Automated |
| CFE-MT-005 | Custom Features | Functional | Admin-created feature is meeting-scoped | Admin with MeetingId=1 | CreateFeature | — | `MeetingId=1` | High | Automated |
| CFE-MT-006 | Custom Features | Security | DB query filters fail-closed without ChurchId | Clear tenant ChurchId | Query CustomFeatures | — | Empty (IgnoreQueryFilters still sees rows) | High | Manual |

---

## G. Integration / edge / security

| Test Case ID | Module | Category | Test Scenario | Preconditions | Test Steps | Test Data | Expected Result | Priority | Automation Status |
|---|---|---|---|---|---|---|---|---|---|
| CFE-INT-001 | Custom Features | Integration | Features hub visible for Admin only | Flutter | Open settings customization | — | Servant gated (`features_hub_screen`) | High | Automated (Flutter) |
| CFE-INT-002 | Custom Features | Integration | Enabled features section on dashboard/nav | Active features | Navigate app | — | Features appear for users with read access | Medium | Manual |
| CFE-INT-003 | Custom Features | Integration | Auth required on all controllers | No JWT | Call GET features | — | 401 | Critical | Manual |
| CFE-EDGE-001 | Custom Features | Validation | Null body on POST | Admin | POST empty body | — | Validation body required | High | Manual |
| CFE-EDGE-002 | Custom Features | Validation | Invalid ids | — | GET entity/record 0 or random | — | 404 | Medium | Manual |
| CFE-EDGE-003 | Custom Features | Security | SQL injection in Text scalar | Text field | CreateRecord with SQL string | — | Stored as JSON text; no execution | High | Automated |
| CFE-EDGE-004 | Custom Features | Validation | pageSize > 100 clamped | Many records | GetRecords pageSize=500 | — | Effective pageSize=20 default clamp | Medium | Automated |
| CFE-EDGE-005 | Custom Features | Functional | Regex validation on record field | Field with regex | Bad value | — | Invalid format | High | Automated |
| CFE-EDGE-006 | Custom Features | Functional | Incomplete feature (no entities) usable | Feature only | List entities | — | Empty list; no crash | Low | Automated |

---

## Sample data bank

```json
{
  "feature": { "displayName": "Bus Management", "displayNameAr": "إدارة الأتوبيس" },
  "entity": { "displayName": "Bus", "pluralDisplayName": "Buses", "pluralDisplayNameAr": "الأتوبيسات" },
  "fields": [
    { "displayName": "Number", "fieldType": "Text", "isRequired": true, "isUnique": true, "isSearchable": true },
    { "displayName": "Capacity", "fieldType": "Number", "isRequired": true },
    { "displayName": "Status", "fieldType": "Dropdown", "options": [
      { "value": "active", "displayText": "Active", "displayTextAr": "نشط" },
      { "value": "maintenance", "displayText": "Maintenance" }
    ]},
    { "displayName": "Driver", "fieldType": "ServantReference", "isRequired": false },
    { "displayName": "Riders", "fieldType": "EntityMultiReference", "targetEntityId": "<MemberProxyEntityId>" }
  ],
  "record": { "number": "01", "capacity": 14, "status": "active" }
}
```

## API quick reference

### `api/custom-features`
| Method | Path | Policy |
|---|---|---|
| GET | `/` | Authenticated |
| GET | `/{id}` | Authenticated |
| POST | `/` | ManageMetadata |
| PUT | `/{id}` | ManageMetadata |
| DELETE | `/{id}` | ManageMetadata |
| GET | `/{featureId}/entities` | Authenticated |
| POST | `/{featureId}/entities` | ManageMetadata |

### `api/custom-entities`
| Method | Path | Policy |
|---|---|---|
| GET/PUT/DELETE | `/{id}` | GET auth; mutating ManageMetadata |
| POST | `/{entityId}/fields` | ManageMetadata |
| PUT/DELETE | `/fields/{id}` | ManageMetadata |
| GET/PUT | `/{entityId}/permissions` | ManageMetadata |
| GET/POST | `/{entityId}/records` | UseRecords |
| GET/PUT/DELETE | `/{entityId}/records/{recordId}` | UseRecords |
