# Delcod

Aplicativo Flutter para leitura e gestao simples de codigos de barras.

## Escopo atual

- Android com leitura por camera
- Web/Chrome com entrada manual
- Lista global unica com sincronizacao em tempo real
- Operacao offline com sincronizacao posterior
- Exportacao para PDF e XLSX

## Execucao local

```powershell
flutter run -d chrome --dart-define=SUPABASE_URL=SEU_URL --dart-define=SUPABASE_ANON_KEY=SUA_KEY
```

## Build Android

```powershell
flutter build apk --release --dart-define=SUPABASE_URL=SEU_URL --dart-define=SUPABASE_ANON_KEY=SUA_KEY
```
