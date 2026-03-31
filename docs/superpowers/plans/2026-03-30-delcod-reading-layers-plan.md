# DelCod Reading Layers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Preparar o DelCod para suportar futuras camadas de leitura sem alterar a interface atual, classificando leituras automaticamente e persistindo metadados estruturais.

**Architecture:** O app continuara operando com uma lista global unica, mas toda leitura passara por um classificador interno antes de ser persistida. O armazenamento local e remoto sera expandido para carregar tipo, status de classificacao, candidatos e payload especifico por camada.

**Tech Stack:** Flutter, Riverpod, SharedPreferences, Supabase, Dart unit and widget tests

---

### Task 1: Introduzir o modelo estrutural e a camada compativel do repositorio

**Files:**
- Create: `lib/features/readings/domain/reading_classification.dart`
- Create: `lib/features/readings/domain/classified_reading_input.dart`
- Modify: `lib/features/readings/data/readings_repository.dart`
- Test: `test/unit/readings/readings_repository_test.dart`

- [ ] **Step 1: Write the failing test**

Criar testes cobrindo uma leitura com tipo identificado, uma leitura ambigua e uma leitura com tipo desconhecido, esperando que o repositorio preserve os novos campos estruturais com o shape canonico por status.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/readings/readings_repository_test.dart`
Expected: FAIL because the repository model does not expose the new fields yet.

- [ ] **Step 3: Write minimal implementation**

Adicionar um modelo de classificacao comum e expandir `ReadingItem` para carregar:
- `codeType`
- `classificationStatus`
- `classificationCandidates`
- `detailsPayload`
- `schemaVersion`

Tambem criar o contrato de entrada estruturada usado para transportar o resultado do classificador ate o repositorio. Esse contrato entra primeiro como camada compativel: a API atual do repositorio continua compilando, com parametros estruturais opcionais e defaults, ate o controller e as fakes migrarem na tarefa seguinte.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/readings/readings_repository_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/readings/domain/reading_classification.dart lib/features/readings/domain/classified_reading_input.dart lib/features/readings/data/readings_repository.dart test/unit/readings/readings_repository_test.dart
git commit -m "feat: add structural reading classification model"
```

### Task 2: Adicionar o classificador de tipos

**Files:**
- Create: `lib/features/readings/domain/reading_type_definition.dart`
- Create: `lib/features/readings/domain/reading_type_classifier.dart`
- Test: `test/unit/readings/reading_type_classifier_test.dart`

- [ ] **Step 1: Write the failing test**

Cobrir:
- codigo identificado como `paper_bobbin`
- codigo ambiguo com multiplos candidatos
- codigo desconhecido

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/readings/reading_type_classifier_test.dart`
Expected: FAIL because no classifier exists.

- [ ] **Step 3: Write minimal implementation**

Criar definicoes de tipo com:
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

### Task 3: Encaixar a classificacao no fluxo atual

**Files:**
- Modify: `lib/features/readings/application/readings_controller.dart`
- Test: `test/unit/readings/readings_controller_test.dart`
- Test: `test/unit/readings/import_batch_commit_test.dart`

- [ ] **Step 1: Write the failing test**

Cobrir o fluxo de camera, entrada manual e importacao garantindo que a persistencia agora use o resultado do classificador. Cobrir tambem edicao de codigo reclassificando o registro antes de persistir.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/readings/readings_controller_test.dart`
Expected: FAIL because the controller still persists only raw codes.

Run: `flutter test test/unit/readings/import_batch_commit_test.dart`
Expected: FAIL because a importacao ainda nao usa o pipeline estrutural.

- [ ] **Step 3: Write minimal implementation**

Passar toda nova leitura pelo `ReadingTypeClassifier` antes de salvar, reclassificar tambem em `updateCode`, e manter a importacao em lote usando o mesmo pipeline sem alterar o comportamento visual da tela.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/readings/readings_controller_test.dart`
Expected: PASS

Run: `flutter test test/unit/readings/import_batch_commit_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/readings/application/readings_controller.dart test/unit/readings/readings_controller_test.dart test/unit/readings/import_batch_commit_test.dart
git commit -m "feat: classify readings before persistence"
```

### Task 4: Compatibilidade local e persistencia remota

**Files:**
- Create: `supabase/migrations/20260330xxxxxx_add_reading_layers.sql`
- Modify: `lib/features/readings/data/readings_repository.dart`
- Test: `test/unit/readings/readings_repository_test.dart`

- [ ] **Step 1: Write the failing test**

Cobrir serializacao e desserializacao de leituras antigas e novas, garantindo fallback para defaults canonicos tanto em registros ativos quanto na fila pendente.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/readings/readings_repository_test.dart`
Expected: FAIL because old and new shapes are not both supported yet.

- [ ] **Step 3: Write minimal implementation**

Adicionar migracao remota e fallback compativel no armazenamento local para leituras que ainda nao tenham os novos campos, incluindo leitura e regravacao segura da fila pendente offline.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/readings/readings_repository_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260330xxxxxx_add_reading_layers.sql lib/features/readings/data/readings_repository.dart test/unit/readings/readings_repository_test.dart
git commit -m "feat: persist reading layer metadata"
```

### Task 5: Verificacao final e entrega

**Files:**
- Modify: `docs/superpowers/specs/2026-03-30-delcod-reading-layers-design.md`
- Modify: `README.md` if needed

- [ ] **Step 1: Run targeted tests**

Run: `flutter test test/unit/readings`
Expected: PASS

- [ ] **Step 2: Run full verification**

Run: `flutter test`
Expected: PASS

Run: `flutter analyze`
Expected: PASS with no issues

Run: `flutter test test/widget/readings_page_test.dart test/widget/app_router_test.dart test/widget/smoke_test.dart`
Expected: PASS

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
