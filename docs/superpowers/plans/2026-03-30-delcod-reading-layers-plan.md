# DelCod Reading Layers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Preparar o DelCod para suportar futuras camadas de leitura sem alterar a interface atual, classificando leituras automaticamente e persistindo metadados estruturais.

**Architecture:** O app continuará operando com uma lista global única, mas toda leitura passará por um classificador interno antes de ser persistida. O armazenamento local e remoto será expandido para carregar tipo, status de classificação, candidatos e payload específico por camada.

**Tech Stack:** Flutter, Riverpod, SharedPreferences, Supabase, Dart unit/widget tests

---

### Task 1: Introduzir o modelo estrutural de leitura

**Files:**
- Create: `lib/features/readings/domain/reading_classification.dart`
- Modify: `lib/features/readings/data/readings_repository.dart`
- Test: `test/unit/readings/readings_repository_test.dart`

- [ ] **Step 1: Write the failing test**

Criar testes cobrindo uma leitura com tipo identificado e uma leitura com tipo desconhecido, esperando que o repositório preserve os novos campos estruturais.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/readings/readings_repository_test.dart`
Expected: FAIL because the repository model does not expose the new fields yet.

- [ ] **Step 3: Write minimal implementation**

Adicionar um modelo de classificação comum e expandir `ReadingItem` para carregar:
- `readingType`
- `classificationStatus`
- `classificationCandidates`
- `detailsPayload`
- `schemaVersion`

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/readings/readings_repository_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/readings/domain/reading_classification.dart lib/features/readings/data/readings_repository.dart test/unit/readings/readings_repository_test.dart
git commit -m "feat: add structural reading classification model"
```

### Task 2: Adicionar o classificador de tipos

**Files:**
- Create: `lib/features/readings/domain/reading_type_definition.dart`
- Create: `lib/features/readings/domain/reading_type_classifier.dart`
- Test: `test/unit/readings/reading_type_classifier_test.dart`

- [ ] **Step 1: Write the failing test**

Cobrir:
- código identificado como `paper_bobbin`
- código ambíguo com múltiplos candidatos
- código desconhecido

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/readings/reading_type_classifier_test.dart`
Expected: FAIL because no classifier exists.

- [ ] **Step 3: Write minimal implementation**

Criar definições de tipo com:
- `paper_bobbin`
- `paper_sheet` como stub
- `unknown`

E implementar um classificador que produza tipo, status, candidatos e payload.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/readings/reading_type_classifier_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/readings/domain/reading_type_definition.dart lib/features/readings/domain/reading_type_classifier.dart test/unit/readings/reading_type_classifier_test.dart
git commit -m "feat: add reading type classifier"
```

### Task 3: Encaixar a classificação no fluxo atual

**Files:**
- Modify: `lib/features/readings/application/readings_controller.dart`
- Modify: `lib/features/import/data/reading_import_service.dart`
- Test: `test/unit/readings/readings_controller_test.dart`

- [ ] **Step 1: Write the failing test**

Cobrir o fluxo de câmera/manual/importação garantindo que a persistência agora use o resultado do classificador.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/readings/readings_controller_test.dart`
Expected: FAIL because the controller still persists only raw codes.

- [ ] **Step 3: Write minimal implementation**

Passar toda nova leitura pelo `ReadingTypeClassifier` antes de salvar, sem alterar o comportamento visual da tela.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/readings/readings_controller_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/readings/application/readings_controller.dart lib/features/import/data/reading_import_service.dart test/unit/readings/readings_controller_test.dart
git commit -m "feat: classify readings before persistence"
```

### Task 4: Expandir o esquema remoto e compatibilidade local

**Files:**
- Create: `supabase/migrations/20260330xxxxxx_add_reading_layers.sql`
- Modify: `lib/features/readings/data/readings_repository.dart`
- Test: `test/unit/readings/readings_repository_test.dart`

- [ ] **Step 1: Write the failing test**

Cobrir serialização e desserialização de leituras antigas e novas, garantindo fallback para `unknown`.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/readings/readings_repository_test.dart`
Expected: FAIL because old/new shapes are not both supported yet.

- [ ] **Step 3: Write minimal implementation**

Adicionar migração remota e fallback compatível no armazenamento local para leituras que ainda não tenham os novos campos.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/readings/readings_repository_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260330xxxxxx_add_reading_layers.sql lib/features/readings/data/readings_repository.dart test/unit/readings/readings_repository_test.dart
git commit -m "feat: persist reading layer metadata"
```

### Task 5: Verificação final e entrega

**Files:**
- Modify: `docs/superpowers/specs/2026-03-30-delcod-reading-layers-design.md`
- Modify: `README.md` if needed

- [ ] **Step 1: Run targeted tests**

Run: `flutter test test/unit/readings`
Expected: PASS

- [ ] **Step 2: Run full verification**

Run: `flutter analyze`
Expected: PASS with no issues

- [ ] **Step 3: Build web and Android**

Run: `flutter build web --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
Expected: PASS

Run: `flutter build apk --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add .
git commit -m "feat: prepare reading layers foundation"
```
