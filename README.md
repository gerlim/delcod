# DelCod

Aplicativo Flutter para leitura e gestão de códigos de barras com sincronização em tempo real.

## Stack

- Flutter
- Supabase
- Drift
- mobile_scanner

## Plataformas

- Android: leitura por câmera
- Web/Chrome: entrada manual

## Funcionalidades

- Lista global única
- Funcionamento offline com sincronização posterior
- Aviso de duplicidade com confirmação
- Exportação em PDF e XLSX

## Variáveis obrigatórias

Nenhum segredo é versionado. Configure em `--dart-define`:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `APP_ENV` opcional

## Rodar localmente

```powershell
flutter pub get
flutter run -d chrome --dart-define=SUPABASE_URL=SEU_URL --dart-define=SUPABASE_ANON_KEY=SUA_KEY --dart-define=APP_ENV=development
```

## Build web

```powershell
flutter build web --dart-define=SUPABASE_URL=SEU_URL --dart-define=SUPABASE_ANON_KEY=SUA_KEY --dart-define=APP_ENV=production
```

## Build Android

```powershell
flutter build apk --release --dart-define=SUPABASE_URL=SEU_URL --dart-define=SUPABASE_ANON_KEY=SUA_KEY --dart-define=APP_ENV=production
```

## Licença

MIT. Veja [LICENSE](LICENSE).
