# DelCod

Aplicativo Flutter para leitura e gestao de lotes de bobina com sincronizacao em tempo real.

## Stack

- Flutter
- Supabase
- Drift
- mobile_scanner

## Plataformas

- Android: leitura por camera e update do APK por manifesto remoto
- Web/Chrome: entrada manual

## Funcionalidades

- Lista global unica
- Funcionamento offline com sincronizacao posterior
- Aviso de duplicidade com confirmacao
- Importacao em CSV/XLSX
- Exportacao em PDF e Excel
- Alocacao de armazem e empresa derivada

## Variaveis por `--dart-define`

Nenhum segredo e versionado. Configure:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `APP_ENV` opcional
- `APP_UPDATE_MANIFEST_URL` opcional

Se `APP_UPDATE_MANIFEST_URL` nao for informado, o update automatico do APK fica desabilitado.

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
flutter build apk --release --dart-define=SUPABASE_URL=SEU_URL --dart-define=SUPABASE_ANON_KEY=SUA_KEY --dart-define=APP_ENV=production --dart-define=APP_UPDATE_MANIFEST_URL=https://seu-host/version.json
```

## Publicacao do update Android

Para que o APK seja tratado como atualizacao pelo Android:

- mantenha o mesmo `applicationId`
- mantenha a mesma chave de assinatura
- publique o APK com nome versionado, por exemplo `DelCod-2.apk`
- publique ou atualize o `version.json`
- use `apkUrl` com a mesma origem de `APP_UPDATE_MANIFEST_URL`

Exemplo de `version.json`:

```json
{
  "versionName": "1.0.1",
  "versionCode": 2,
  "apkUrl": "https://updates.delcod.app/DelCod-2.apk",
  "releaseNotes": "Melhorias na leitura e importacao.",
  "mandatory": false
}
```

## Licenca

MIT. Veja [LICENSE](LICENSE).
