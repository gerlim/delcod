# Inventory Audit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current barcode-list domain with an inventory audit flow that imports XLSX inventory on Web, audits bobbins on Android by barcode, preserves imported data as read-only, and exports audit results.

**Architecture:** Keep the existing Flutter, Riverpod, Supabase, Vercel, scanner, test, and APK auto-update foundation. Add a focused `inventory` feature with immutable imported items, separate audit results, Supabase-backed repositories, and platform-aware UI: Web for import/reporting and Android for scan/manual audit. Keep the existing app-update feature intact and retire the current readings page from the main route once the inventory flow is ready.

**Tech Stack:** Flutter, Dart, Riverpod, go_router, Supabase, excel, mobile_scanner, shared_preferences, Flutter tests, Supabase SQL migrations, Vercel build.

---

## File Structure

Create these focused inventory files:

- `lib/features/inventory/domain/inventory_audit.dart`: audit metadata and status.
- `lib/features/inventory/domain/inventory_item.dart`: immutable imported inventory item.
- `lib/features/inventory/domain/inventory_audit_result.dart`: scan result status, discrepancy fields, optional note.
- `lib/features/inventory/domain/inventory_import_models.dart`: parsed XLSX table, import validation, duplicate reports.
- `lib/features/inventory/data/inventory_remote_contract.dart`: Supabase table/column names.
- `lib/features/inventory/data/inventory_item_mapper.dart`: JSON mapping for Supabase rows.
- `lib/features/inventory/data/inventory_audit_result_mapper.dart`: JSON mapping for result rows.
- `lib/features/inventory/data/inventory_import_service.dart`: XLSX parsing and validation.
- `lib/features/inventory/data/inventory_repository.dart`: Supabase persistence and active audit queries.
- `lib/features/inventory/application/inventory_import_controller.dart`: Web import workflow.
- `lib/features/inventory/application/inventory_audit_controller.dart`: Android scan/manual audit workflow.
- `lib/features/inventory/application/inventory_export_builder.dart`: grouped export payload.
- `lib/features/inventory/presentation/inventory_home_page.dart`: platform-aware entry point.
- `lib/features/inventory/presentation/inventory_import_page.dart`: Web import/reporting view.
- `lib/features/inventory/presentation/inventory_scan_page.dart`: Android scan/manual audit view.
- `lib/features/inventory/presentation/inventory_item_card.dart`: read-only imported item display.
- `lib/features/inventory/presentation/discrepancy_form.dart`: incorrect-result field selection and optional note.
- `lib/features/inventory/presentation/audit_status_summary.dart`: counts for correct/incorrect/not found/pending.
- `lib/features/inventory/export/inventory_audit_xlsx_export_service.dart`: XLSX export with four sheets.

Modify these existing files:

- `lib/app/router/app_router.dart`: route `/` to `InventoryHomePage`.
- `lib/features/readings/presentation/readings_page.dart`: stop using as main route; leave source available until cleanup.
- `pubspec.yaml`: keep dependencies, add none unless needed after implementation proves a gap.
- `supabase/migrations/<timestamp>_add_inventory_audit.sql`: add new tables, indexes, RLS, and realtime if needed.
- `README.md`: update run/build notes for inventory audit and XLSX import.
- `scripts/vercel_build.sh`: keep existing behavior unless env handling needs update.
- `android/app/build.gradle` and `android/app/src/main/AndroidManifest.xml`: Android hardening review for APK warnings.

Tests to add:

- `test/unit/inventory/inventory_import_service_test.dart`
- `test/unit/inventory/inventory_repository_mapper_test.dart`
- `test/unit/inventory/inventory_audit_controller_test.dart`
- `test/unit/inventory/inventory_export_builder_test.dart`
- `test/unit/inventory/inventory_audit_xlsx_export_service_test.dart`
- `test/widget/inventory_import_page_test.dart`
- `test/widget/inventory_scan_page_test.dart`
- `test/widget/inventory_home_page_test.dart`

## Task 1: Add Inventory Domain Models

**Files:**
- Create: `lib/features/inventory/domain/inventory_audit.dart`
- Create: `lib/features/inventory/domain/inventory_item.dart`
- Create: `lib/features/inventory/domain/inventory_audit_result.dart`
- Test: `test/unit/inventory/inventory_domain_test.dart`

- [ ] **Step 1: Write failing tests for domain invariants**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:barcode_app/features/inventory/domain/inventory_audit_result.dart';
import 'package:barcode_app/features/inventory/domain/inventory_item.dart';

void main() {
  test('inventory item normalizes barcode for lookup without mutating source fields', () {
    final item = InventoryItem(
      id: 'item-1',
      auditId: 'audit-1',
      companyName: 'Bora Embalagens',
      bobbinCode: ' BOB-001 ',
      itemDescription: 'Papel kraft',
      barcode: ' 789123 ',
      weight: '482,5',
      warehouse: '05',
      rowNumber: 2,
    );

    expect(item.lookupBarcode, '789123');
    expect(item.bobbinCode, ' BOB-001 ');
  });

  test('incorrect audit result can store discrepancy fields and optional note', () {
    final result = InventoryAuditResult.incorrect(
      id: 'result-1',
      auditId: 'audit-1',
      inventoryItemId: 'item-1',
      scannedBarcode: '789123',
      discrepancyFields: const {InventoryDiscrepancyField.weight},
      note: 'Peso na etiqueta esta diferente',
      scannedAt: DateTime.utc(2026, 5, 14),
    );

    expect(result.status, InventoryAuditResultStatus.incorrect);
    expect(result.discrepancyFields, contains(InventoryDiscrepancyField.weight));
    expect(result.note, 'Peso na etiqueta esta diferente');
  });
}
```

- [ ] **Step 2: Run tests to verify RED**

Run: `flutter test test/unit/inventory/inventory_domain_test.dart`

Expected: FAIL because inventory domain classes do not exist.

- [ ] **Step 3: Implement minimal domain models**

Create immutable Dart classes and enums:

- `InventoryAuditStatus.active`, `archived`
- `InventoryAuditResultStatus.correct`, `incorrect`, `notFound`
- `InventoryDiscrepancyField.company`, `bobbinCode`, `description`, `barcode`, `weight`, `warehouse`

- [ ] **Step 4: Run tests to verify GREEN**

Run: `flutter test test/unit/inventory/inventory_domain_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/inventory/domain test/unit/inventory/inventory_domain_test.dart
git commit -m "feat: add inventory audit domain models"
```

## Task 2: Add XLSX Inventory Import Parser

**Files:**
- Create: `lib/features/inventory/domain/inventory_import_models.dart`
- Create: `lib/features/inventory/data/inventory_import_service.dart`
- Test: `test/unit/inventory/inventory_import_service_test.dart`

- [ ] **Step 1: Write failing test for mixed-company XLSX import**

Use the `excel` package to create an in-memory workbook in the test. Include headers:

- `Empresa`
- `Codigo`
- `Descricao`
- `Codigo de Barras`
- `Peso`
- `Armazem`

Assert two rows import into two `InventoryItemDraft` entries with distinct companies.

- [ ] **Step 2: Run test to verify RED**

Run: `flutter test test/unit/inventory/inventory_import_service_test.dart`

Expected: FAIL because `InventoryImportService` does not exist.

- [ ] **Step 3: Implement parser with flexible header aliases**

Support aliases:

- empresa: `empresa`, `company`
- codigo: `codigo`, `codigo da bobina`, `código da bobina`, `bobbin code`
- descricao: `descricao`, `descrição`, `descricao do item`, `item_description`
- codigo_barras: `codigo de barras`, `código de barras`, `barcode`, `ean`
- peso: `peso`, `weight`
- armazem: `armazem`, `armazém`, `warehouse`

Preserve `weight` as text.

- [ ] **Step 4: Add failing test for duplicate barcode**

Assert duplicate barcodes in one file produce an import validation error and no activatable import.

- [ ] **Step 5: Implement duplicate validation**

Return an `InventoryImportValidation` object with `errors`, `warnings`, and parsed drafts.

- [ ] **Step 6: Run parser tests**

Run: `flutter test test/unit/inventory/inventory_import_service_test.dart`

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/inventory/domain/inventory_import_models.dart lib/features/inventory/data/inventory_import_service.dart test/unit/inventory/inventory_import_service_test.dart
git commit -m "feat: parse inventory xlsx imports"
```

## Task 3: Add Supabase Inventory Schema

**Files:**
- Create: `supabase/migrations/20260514120000_add_inventory_audit.sql`
- Create: `lib/features/inventory/data/inventory_remote_contract.dart`
- Test: `test/unit/inventory/inventory_remote_contract_test.dart`

- [ ] **Step 1: Write failing contract test**

Assert table names and canonical columns match expected strings:

- `inventory_audits`
- `inventory_items`
- `inventory_audit_results`

- [ ] **Step 2: Run test to verify RED**

Run: `flutter test test/unit/inventory/inventory_remote_contract_test.dart`

Expected: FAIL because contract file does not exist.

- [ ] **Step 3: Add remote contract constants**

Create constants for all table names and column names used by repositories.

- [ ] **Step 4: Add SQL migration**

Migration should create:

- `inventory_audits`
- `inventory_items`
- `inventory_audit_results`

Constraints:

- `inventory_items (audit_id, barcode)` unique.
- `inventory_audit_results (audit_id, scanned_barcode)` unique.
- `inventory_audit_results.status` check in `correct`, `incorrect`, `not_found`.
- `inventory_audits.status` check in `active`, `archived`.

Indexes:

- active audit lookup
- item barcode lookup
- result status counts

RLS first version:

- allow anon/authenticated select/insert/update needed for current no-login APK and Web import model.
- document that this is operationally open and should be revisited if admin login is added.

- [ ] **Step 5: Run contract test**

Run: `flutter test test/unit/inventory/inventory_remote_contract_test.dart`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add supabase/migrations/20260514120000_add_inventory_audit.sql lib/features/inventory/data/inventory_remote_contract.dart test/unit/inventory/inventory_remote_contract_test.dart
git commit -m "feat: add inventory audit supabase schema"
```

## Task 4: Add Inventory JSON Mappers

**Files:**
- Create: `lib/features/inventory/data/inventory_item_mapper.dart`
- Create: `lib/features/inventory/data/inventory_audit_result_mapper.dart`
- Test: `test/unit/inventory/inventory_repository_mapper_test.dart`

- [ ] **Step 1: Write failing roundtrip tests**

Assert `InventoryItem` and `InventoryAuditResult` convert to/from Supabase row maps without losing fields.

- [ ] **Step 2: Run tests to verify RED**

Run: `flutter test test/unit/inventory/inventory_repository_mapper_test.dart`

Expected: FAIL because mappers do not exist.

- [ ] **Step 3: Implement mappers**

Map Dart enums to Supabase strings:

- `correct`
- `incorrect`
- `not_found`
- `active`
- `archived`

Store `discrepancy_fields` as JSON list of strings.

- [ ] **Step 4: Run mapper tests**

Run: `flutter test test/unit/inventory/inventory_repository_mapper_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/inventory/data/*_mapper.dart test/unit/inventory/inventory_repository_mapper_test.dart
git commit -m "feat: map inventory audit rows"
```

## Task 5: Add Inventory Repository

**Files:**
- Create: `lib/features/inventory/data/inventory_repository.dart`
- Test: `test/unit/inventory/inventory_repository_test.dart`

- [ ] **Step 1: Write failing repository tests against a fake data source**

Define an injectable data source interface so tests can avoid live Supabase. Assert:

- create audit archives previous active audits
- insert items for audit
- fetch active audit with item counts
- fetch item by barcode
- save result blocks duplicate scanned barcode
- list grouped results

- [ ] **Step 2: Run tests to verify RED**

Run: `flutter test test/unit/inventory/inventory_repository_test.dart`

Expected: FAIL because repository does not exist.

- [ ] **Step 3: Implement repository with injectable remote data source**

Default provider uses `SupabaseClientRegistry.tryRead()`.

Expose methods:

- `Future<InventoryAudit> createAuditFromImport(...)`
- `Future<InventoryAudit?> fetchActiveAudit()`
- `Future<List<InventoryItem>> fetchItems(String auditId)`
- `Future<InventoryItem?> findItemByBarcode(String auditId, String barcode)`
- `Future<InventoryAuditResult?> findResultByBarcode(String auditId, String barcode)`
- `Future<InventoryAuditResult> saveResult(...)`
- `Future<InventoryAuditSnapshot> fetchSnapshot(String auditId)`

- [ ] **Step 4: Run repository tests**

Run: `flutter test test/unit/inventory/inventory_repository_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/inventory/data/inventory_repository.dart test/unit/inventory/inventory_repository_test.dart
git commit -m "feat: add inventory audit repository"
```

## Task 6: Add Web Import Controller

**Files:**
- Create: `lib/features/inventory/application/inventory_import_controller.dart`
- Test: `test/unit/inventory/inventory_import_controller_test.dart`

- [ ] **Step 1: Write failing controller test**

Assert importing valid XLSX creates an audit and reports counts.

- [ ] **Step 2: Run test to verify RED**

Run: `flutter test test/unit/inventory/inventory_import_controller_test.dart`

Expected: FAIL because controller does not exist.

- [ ] **Step 3: Implement `AsyncNotifier` controller**

State should include:

- selected filename
- validation errors
- imported count
- active audit id
- loading/error status

- [ ] **Step 4: Add duplicate-barcode controller test**

Assert duplicate file does not call repository create.

- [ ] **Step 5: Run controller tests**

Run: `flutter test test/unit/inventory/inventory_import_controller_test.dart`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/inventory/application/inventory_import_controller.dart test/unit/inventory/inventory_import_controller_test.dart
git commit -m "feat: add inventory import controller"
```

## Task 7: Add Android Audit Controller

**Files:**
- Create: `lib/features/inventory/application/inventory_audit_controller.dart`
- Test: `test/unit/inventory/inventory_audit_controller_test.dart`

- [ ] **Step 1: Write failing test for found barcode flow**

Assert scanning an existing barcode returns a review state with immutable item details.

- [ ] **Step 2: Run test to verify RED**

Run: `flutter test test/unit/inventory/inventory_audit_controller_test.dart`

Expected: FAIL because controller does not exist.

- [ ] **Step 3: Implement scan/manual lookup state machine**

States:

- no active audit
- ready
- found pending decision
- already audited
- not found pending save
- saving
- saved
- error

- [ ] **Step 4: Add failing test for duplicate audit block**

Assert repository existing result causes `alreadyAudited` and does not save.

- [ ] **Step 5: Add failing test for not found result**

Assert unknown barcode can be saved once as `notFound`.

- [ ] **Step 6: Implement result save methods**

Methods:

- `lookupBarcode(String rawBarcode)`
- `markCorrect()`
- `markIncorrect(Set<InventoryDiscrepancyField> fields, String? note)`
- `markNotFound()`

- [ ] **Step 7: Run controller tests**

Run: `flutter test test/unit/inventory/inventory_audit_controller_test.dart`

Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/features/inventory/application/inventory_audit_controller.dart test/unit/inventory/inventory_audit_controller_test.dart
git commit -m "feat: add inventory audit controller"
```

## Task 8: Add Web Import and Reporting UI

**Files:**
- Create: `lib/features/inventory/presentation/inventory_import_page.dart`
- Create: `lib/features/inventory/presentation/audit_status_summary.dart`
- Test: `test/widget/inventory_import_page_test.dart`

- [ ] **Step 1: Write failing widget test for Web import page**

Assert it shows:

- import XLSX action
- active audit summary
- export action
- previous audits section

- [ ] **Step 2: Run test to verify RED**

Run: `flutter test test/widget/inventory_import_page_test.dart`

Expected: FAIL because page does not exist.

- [ ] **Step 3: Implement Web import page**

Use existing visual style from `ReadingsPage`: restrained operational layout, summary cards, no marketing hero.

- [ ] **Step 4: Add validation error widget test**

Assert duplicate barcode errors are visible.

- [ ] **Step 5: Run widget tests**

Run: `flutter test test/widget/inventory_import_page_test.dart`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/inventory/presentation/inventory_import_page.dart lib/features/inventory/presentation/audit_status_summary.dart test/widget/inventory_import_page_test.dart
git commit -m "feat: add inventory import web page"
```

## Task 9: Add Android Scan UI

**Files:**
- Create: `lib/features/inventory/presentation/inventory_scan_page.dart`
- Create: `lib/features/inventory/presentation/inventory_item_card.dart`
- Create: `lib/features/inventory/presentation/discrepancy_form.dart`
- Test: `test/widget/inventory_scan_page_test.dart`

- [ ] **Step 1: Write failing widget test for found item**

Assert scan page shows read-only fields:

- Empresa
- Codigo
- Descricao
- Codigo de barras
- Peso
- Armazem
- Correto button
- Incorreto button

- [ ] **Step 2: Run test to verify RED**

Run: `flutter test test/widget/inventory_scan_page_test.dart`

Expected: FAIL because page does not exist.

- [ ] **Step 3: Implement scan page layout**

Use scanner when `platformCapabilities.supportsCameraScanning` is true. Always include manual barcode entry as fallback.

- [ ] **Step 4: Add failing widget test for incorrect form**

Assert tapping `Incorreto` shows field checkboxes and optional note input.

- [ ] **Step 5: Implement discrepancy form**

Fields:

- Empresa
- Codigo
- Descricao
- Codigo de barras
- Peso
- Armazem

- [ ] **Step 6: Add duplicate-audit widget test**

Assert `Essa bobina ja foi auditada` is shown and action buttons are disabled.

- [ ] **Step 7: Run widget tests**

Run: `flutter test test/widget/inventory_scan_page_test.dart`

Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/features/inventory/presentation/inventory_scan_page.dart lib/features/inventory/presentation/inventory_item_card.dart lib/features/inventory/presentation/discrepancy_form.dart test/widget/inventory_scan_page_test.dart
git commit -m "feat: add inventory scan workflow"
```

## Task 10: Add Platform-Aware Home Route

**Files:**
- Create: `lib/features/inventory/presentation/inventory_home_page.dart`
- Modify: `lib/app/router/app_router.dart`
- Test: `test/widget/inventory_home_page_test.dart`
- Test: `test/widget/app_router_test.dart`
- Test: `test/widget/smoke_test.dart`

- [ ] **Step 1: Write failing home page tests**

Assert Web renders import/admin page and Android-capable override renders scan page.

- [ ] **Step 2: Run tests to verify RED**

Run: `flutter test test/widget/inventory_home_page_test.dart test/widget/app_router_test.dart test/widget/smoke_test.dart`

Expected: FAIL because home page is not routed.

- [ ] **Step 3: Implement inventory home page**

Route `/` to `InventoryHomePage`.

Use `platformCapabilitiesProvider`:

- camera scanning supported: scan workflow
- otherwise: Web import/reporting workflow

- [ ] **Step 4: Update existing router/smoke expectations**

Replace current readings-page text expectations with inventory audit shell expectations.

- [ ] **Step 5: Run route tests**

Run: `flutter test test/widget/inventory_home_page_test.dart test/widget/app_router_test.dart test/widget/smoke_test.dart`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/inventory/presentation/inventory_home_page.dart lib/app/router/app_router.dart test/widget/inventory_home_page_test.dart test/widget/app_router_test.dart test/widget/smoke_test.dart
git commit -m "feat: route app to inventory audit"
```

## Task 11: Add Audit Result XLSX Export

**Files:**
- Create: `lib/features/inventory/application/inventory_export_builder.dart`
- Create: `lib/features/inventory/export/inventory_audit_xlsx_export_service.dart`
- Modify: `lib/features/inventory/presentation/inventory_import_page.dart`
- Test: `test/unit/inventory/inventory_export_builder_test.dart`
- Test: `test/unit/inventory/inventory_audit_xlsx_export_service_test.dart`

- [ ] **Step 1: Write failing export builder test**

Assert snapshot groups rows into:

- correct
- incorrect
- not found
- pending

- [ ] **Step 2: Run builder test to verify RED**

Run: `flutter test test/unit/inventory/inventory_export_builder_test.dart`

Expected: FAIL.

- [ ] **Step 3: Implement export builder**

Keep grouping logic independent from the Excel package.

- [ ] **Step 4: Write failing XLSX service test**

Assert generated workbook contains four expected sheet names.

- [ ] **Step 5: Implement XLSX export service**

Use `excel` package and existing file download helper from `core/platform/file_download.dart`.

- [ ] **Step 6: Connect Web export action**

Add button to Web reporting UI.

- [ ] **Step 7: Run export tests**

Run: `flutter test test/unit/inventory/inventory_export_builder_test.dart test/unit/inventory/inventory_audit_xlsx_export_service_test.dart test/widget/inventory_import_page_test.dart`

Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/features/inventory/application/inventory_export_builder.dart lib/features/inventory/export/inventory_audit_xlsx_export_service.dart lib/features/inventory/presentation/inventory_import_page.dart test/unit/inventory/inventory_export_builder_test.dart test/unit/inventory/inventory_audit_xlsx_export_service_test.dart test/widget/inventory_import_page_test.dart
git commit -m "feat: export inventory audit results"
```

## Task 12: Preserve App Update and Harden Android Build

**Files:**
- Modify: `android/app/build.gradle`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `README.md`
- Test: `test/unit/app_update/app_update_repository_test.dart`
- Test: `test/unit/app_update/app_update_controller_test.dart`

- [ ] **Step 1: Inspect Android config**

Record current:

- applicationId
- minSdk
- targetSdk
- permissions
- signing config behavior

- [ ] **Step 2: Write/update tests only if app-update behavior changes**

If auto-update manifest logic is untouched, keep existing tests.

- [ ] **Step 3: Remove unnecessary permissions**

Keep camera and file install permissions required by scanner/update. Avoid adding storage permissions unless strictly needed.

- [ ] **Step 4: Verify release config**

Ensure docs explain signed release build and same signing key requirement.

- [ ] **Step 5: Run app-update tests**

Run: `flutter test test/unit/app_update/app_update_repository_test.dart test/unit/app_update/app_update_controller_test.dart`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add android/app/build.gradle android/app/src/main/AndroidManifest.xml README.md
git commit -m "chore: harden android release update setup"
```

## Task 13: Update Documentation

**Files:**
- Modify: `README.md`
- Create or Modify: `docs/manual/` only if user-facing manual is still desired

- [ ] **Step 1: Update README for new app behavior**

Document:

- Web imports XLSX.
- Android audits by scanner/manual barcode.
- Supabase env vars.
- Vercel deploy.
- APK auto-update.
- XLSX expected columns.

- [ ] **Step 2: Run markdown grep sanity check**

Run: `rg -n "lista global|lotes_bobina|readings|codigo antigo" README.md lib/features/inventory`

Expected: no misleading README instructions for old primary flow.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: update inventory audit usage"
```

## Task 14: Full Verification

**Files:**
- No source changes unless failures expose issues.

- [ ] **Step 1: Run full Flutter tests**

Run: `flutter test`

Expected: all tests pass.

- [ ] **Step 2: Run analyzer**

Run: `flutter analyze`

Expected: no errors.

- [ ] **Step 3: Build Web**

Run:

```powershell
flutter build web --release --dart-define=SUPABASE_URL=$env:SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY --dart-define=APP_ENV=production
```

Expected: build succeeds and emits `build/web`.

- [ ] **Step 4: Build Android APK**

Run:

```powershell
flutter build apk --release --dart-define=SUPABASE_URL=$env:SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY --dart-define=APP_ENV=production --dart-define=APP_UPDATE_MANIFEST_URL=https://gerlim.github.io/delcod/updates/version.json
```

Expected: release APK is generated.

- [ ] **Step 5: Prepare Android update bundle**

Run:

```powershell
dart run scripts/prepare_android_update.dart --base-url https://gerlim.github.io/delcod/updates/ --release-notes "Auditoria de inventario por bobina"
```

Expected: `build/app_update/DelCod-<versionCode>.apk` and `build/app_update/version.json`.

- [ ] **Step 6: Commit only if verification fixes were needed**

If no changes, do not commit.

## Task 15: Deploy

**Files:**
- No source changes expected.

- [ ] **Step 1: Confirm deployment credentials**

Verify local environment has access to:

- Vercel project
- GitHub remote/gh-pages for APK update
- Supabase project

- [ ] **Step 2: Apply Supabase migration**

Run one of:

```bash
supabase db push
```

or apply migration through the configured Supabase deployment process.

Expected: inventory tables exist in Supabase.

- [ ] **Step 3: Deploy Web to Vercel**

Use the existing Vercel project deployment flow.

Expected: Web import/reporting app is live.

- [ ] **Step 4: Publish APK update**

Run:

```powershell
dart run scripts/publish_android_update_to_github_pages.dart --release-notes "Auditoria de inventario por bobina"
```

Expected: `gh-pages` contains updated APK and `updates/version.json`.

- [ ] **Step 5: Smoke test production**

On Web:

- import sample XLSX
- verify active audit counts
- export results

On Android:

- install/update APK
- scan known barcode
- mark correct
- scan incorrect sample and mark discrepancy
- scan unknown barcode
- scan already audited barcode and verify block

- [ ] **Step 6: Final commit/tag only if deployment metadata changed**

Do not commit generated build artifacts unless the existing project workflow explicitly requires it.
