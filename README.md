# DelCod Inventario

Aplicativo Flutter para auditoria de inventario de bobinas por codigo de barras.

O fluxo principal e:

1. importar no Web/Vercel uma planilha XLSX com o estoque das duas empresas;
2. auditar pelo Android, usando camera ou digitacao manual do codigo de barras;
3. marcar cada bobina como correta, incorreta ou nao encontrada no banco;
4. exportar o resultado em XLSX separado por status.

## Stack

- Flutter
- Supabase
- Drift para recursos locais legados
- mobile_scanner
- Vercel para hospedagem Web

## Campos da planilha XLSX

A importacao aceita somente `.xlsx`. A planilha pode ter as duas empresas juntas, desde que cada linha informe a empresa.

Colunas esperadas:

- `Empresa`
- `Codigo`
- `Descricao`
- `Codigo de Barras`
- `Peso`
- `Armazem`

Os dados importados sao somente leitura. A auditoria grava um resultado separado, sem alterar a linha original do estoque.

## Status da auditoria

- `Correto`: a bobina foi encontrada e todas as informacoes conferem.
- `Incorreto`: a bobina foi encontrada, mas algum campo diverge. O app registra os campos divergentes e uma observacao opcional.
- `Nao encontrado`: o codigo de barras escaneado nao existe no estoque importado.
- `Pendente`: item importado que ainda nao foi auditado.

O mesmo codigo de barras nao pode ser auditado duas vezes na auditoria ativa.

## Variaveis por `--dart-define`

Nenhum segredo e versionado. Configure:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `APP_ENV` opcional
- `APP_UPDATE_MANIFEST_URL` opcional

Se `APP_UPDATE_MANIFEST_URL` nao for informado, o update automatico do APK fica desabilitado.

## Banco de dados

As tabelas de inventario ficam nas migrations do Supabase:

```powershell
supabase db push
```

A migration cria:

- `inventory_audits`
- `inventory_items`
- `inventory_audit_results`

## Rodar localmente

```powershell
flutter pub get
flutter run -d chrome --dart-define=SUPABASE_URL=SEU_URL --dart-define=SUPABASE_ANON_KEY=SUA_KEY --dart-define=APP_ENV=development
```

## Build Web

```powershell
flutter build web --dart-define=SUPABASE_URL=SEU_URL --dart-define=SUPABASE_ANON_KEY=SUA_KEY --dart-define=APP_ENV=production
```

O Vercel deve executar o build acima e publicar `build/web`.

## Build Android

```powershell
flutter build apk --release --dart-define=SUPABASE_URL=SEU_URL --dart-define=SUPABASE_ANON_KEY=SUA_KEY --dart-define=APP_ENV=production --dart-define=APP_UPDATE_MANIFEST_URL=https://seu-host/version.json
```

Para evitar que o Android trate cada APK como um app diferente, mantenha sempre:

- o mesmo `applicationId`: `com.gerlim.delcod`;
- a mesma chave de assinatura;
- `versionCode` maior que o APK instalado.

Crie `android/key.properties` no ambiente de build para assinar release:

```properties
storePassword=SENHA_DA_STORE
keyPassword=SENHA_DA_KEY
keyAlias=SEU_ALIAS
storeFile=C:/caminho/para/upload-keystore.jks
```

Sem esse arquivo, o build local usa assinatura debug apenas como fallback de desenvolvimento.

## Preparar pacote de update Android

Depois de gerar o APK release, rode:

```powershell
dart run scripts/prepare_android_update.dart --base-url https://updates.seu-host/ --release-notes "Atualizacao do inventario"
```

Isso cria em `build/app_update/`:

- `DelCod-<versionCode>.apk`
- `version.json`

Os dois arquivos devem ser publicados no mesmo host e na mesma pasta.

## Reduzir avisos de APK nocivo

Para uso fora da Play Store, o Android pode exibir avisos por instalacao manual. O projeto foi ajustado para favorecer um APK consistente, mas alguns avisos dependem do canal de distribuicao.

Recomendacoes:

- assinar todas as versoes com a mesma chave release;
- hospedar `version.json` e APK em HTTPS;
- manter nome, pacote e versionamento consistentes;
- evitar distribuir APK debug;
- preferir Google Play Internal Testing quando quiser a menor friccao de instalacao.

### Transicao para assinatura release

O canal automatico atual ainda aponta para o APK `1.1.0+6`, assinado com a mesma chave debug das instalacoes antigas para manter compatibilidade de update.

A build corrigida com chave release fixa e `1.1.2+8` fica publicada separadamente para reinstalacao manual:

- `https://gerlim.github.io/delcod/manual/DelCod-release-1.1.2-8.apk`

Quem estiver usando a build antiga precisa desinstalar o app uma vez e instalar essa build release. Depois disso, proximas atualizacoes podem usar a mesma chave release no canal automatico.

## Publicar update no GitHub Pages

Para usar um host gratuito no proprio GitHub:

```powershell
dart run scripts/publish_android_update_to_github_pages.dart --release-notes "Atualizacao do inventario"
```

O script:

- gera `build/app_update/DelCod-<versionCode>.apk`;
- gera `build/app_update/version.json`;
- monta o site em `build/github_pages_site/`;
- publica tudo na branch `gh-pages`.

URL final esperada:

- site: `https://gerlim.github.io/delcod/`
- manifesto: `https://gerlim.github.io/delcod/updates/version.json`

## Licenca

MIT. Veja [LICENSE](LICENSE).
