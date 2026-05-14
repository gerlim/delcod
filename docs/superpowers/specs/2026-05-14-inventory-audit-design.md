# Design: Auditoria de Inventario de Bobinas

Data: 2026-05-14
Status: Design aprovado para planejamento

## 1. Objetivo

Transformar o DelCod em um aplicativo de auditoria de inventario de bobinas, preservando apenas a base tecnica existente:

- Flutter
- Supabase
- Vercel
- scanner Android
- build e testes
- auto-update do APK

O dominio funcional antigo de lista global de codigos deixa de ser o fluxo principal. O novo fluxo gira em torno de importar um inventario em XLSX pela Web, disponibilizar esse inventario no APK Android e registrar a auditoria das bobinas por codigo de barras.

## 2. Escopo Aprovado

### Incluido

- Importacao de inventario somente pela Web/Vercel.
- Importacao apenas em Excel `.xlsx`.
- Planilha unica contendo itens das duas empresas.
- Cada linha importada deve trazer a empresa do item.
- Campos de inventario:
  - empresa
  - codigo da bobina
  - descricao do item
  - codigo de barras
  - peso
  - armazem
- Uma auditoria ativa usada pelo APK.
- Historico de auditorias anteriores preservado para consulta.
- APK Android sem login e sem identificacao do auditor.
- Busca da bobina pelo codigo de barras.
- Entrada por scanner e por digitacao manual.
- Dados importados ficam somente leitura.
- Resultado da auditoria salvo em registros separados.
- Classificacao por status:
  - correto
  - incorreto
  - nao encontrado no banco
  - pendente, derivado de item importado ainda nao auditado
- Para incorreto:
  - marcar campos divergentes
  - observacao opcional
  - nao alterar o inventario importado
- Bloquear auditoria duplicada da mesma bobina na mesma auditoria.
- Exportacao Web em XLSX com abas:
  - Corretos
  - Incorretos
  - Nao encontrados no banco
  - Pendentes
- Revisao tecnica do APK para reduzir alertas de instalacao nociva quando possivel.

### Fora do Escopo Inicial

- Importacao por PDF.
- Login no APK.
- Identificacao nominal do auditor.
- Edicao do inventario importado durante a auditoria.
- Sobrescrever resultado de bobina ja auditada.
- Leitura por camera na Web.
- Substituir a base tecnica de deploy, Supabase ou auto-update.

## 3. Fluxo Web

A Web passa a ser a superficie administrativa.

1. Usuario acessa a versao Web hospedada na Vercel.
2. Usuario importa uma planilha `.xlsx` de inventario.
3. O app valida cabecalhos e linhas.
4. O app cria uma nova auditoria de inventario.
5. A nova auditoria pode ser marcada como ativa.
6. O app envia os itens para o Supabase.
7. A Web permite acompanhar o progresso da auditoria ativa.
8. A Web permite consultar auditorias anteriores.
9. A Web exporta o resultado em XLSX com abas separadas por status.

## 4. Fluxo Android

O APK passa a ser a superficie operacional de auditoria.

1. O app carrega a auditoria ativa do Supabase.
2. O usuario escaneia o codigo de barras da bobina ou digita manualmente.
3. O app procura o codigo de barras nos itens importados da auditoria ativa.
4. Se nao encontrar:
   - mostra status laranja
   - salva um registro `nao encontrado no banco`
5. Se encontrar e ainda nao tiver sido auditado:
   - mostra os dados importados em modo somente leitura
   - oferece acao verde `Correto`
   - oferece acao vermelha `Incorreto`
6. Se o usuario marcar correto:
   - salva resultado correto
7. Se o usuario marcar incorreto:
   - mostra selecao de campos divergentes
   - permite observacao opcional
   - salva resultado incorreto separado do item importado
8. Se a mesma bobina for escaneada novamente:
   - bloqueia novo registro
   - mostra aviso de que a bobina ja foi auditada

## 5. Modelo de Dados Proposto

### inventory_audits

Representa uma importacao/auditoria.

Campos sugeridos:

- id
- title
- status: active, archived
- imported_at
- item_count
- source_filename
- created_at
- updated_at

Regra: pode existir apenas uma auditoria ativa para o APK usar.

### inventory_items

Representa cada linha importada da planilha.

Campos sugeridos:

- id
- audit_id
- company_name
- bobbin_code
- item_description
- barcode
- weight
- warehouse
- row_number
- raw_payload
- created_at

Regras:

- `barcode` e a chave operacional de busca.
- `barcode` deve ser unico dentro de uma auditoria.
- Estes dados nao sao editados durante a auditoria.

### inventory_audit_results

Representa a decisao tomada durante a auditoria.

Campos sugeridos:

- id
- audit_id
- inventory_item_id, nulo quando nao encontrado
- scanned_barcode
- status: correct, incorrect, not_found
- discrepancy_fields, lista de campos divergentes
- note, opcional
- device_id, tecnico e anonimo
- scanned_at
- created_at

Regras:

- Uma bobina encontrada so pode ter um resultado por auditoria.
- Um codigo nao encontrado tambem deve ser bloqueado apos o primeiro registro na mesma auditoria.
- Resultado nao altera o item importado.

## 6. Estados e Cores

- Verde: item encontrado e confirmado como correto.
- Vermelho: item encontrado, mas possui divergencia registrada.
- Laranja: codigo de barras escaneado nao existe no inventario importado.
- Neutro/pendente: item importado ainda nao auditado.

## 7. Importacao XLSX

A primeira versao deve aceitar cabecalhos flexiveis, mas com campos canonicos internos:

- empresa
- codigo
- descricao
- codigo_barras
- peso
- armazem

Quando a planilha real for fornecida, o mapeamento deve ser ajustado aos nomes exatos das colunas.

Validacoes minimas:

- codigo de barras obrigatorio
- empresa obrigatoria
- codigo de barras duplicado dentro da mesma importacao deve bloquear ou exigir correcao antes de ativar a auditoria
- linhas vazias devem ser ignoradas
- peso deve ser preservado como texto/decimal sem perder formatacao significativa

## 8. Exportacao XLSX

A exportacao Web deve gerar um arquivo com quatro abas:

### Corretos

Itens auditados como corretos, com dados importados e data/hora da auditoria.

### Incorretos

Itens auditados como incorretos, com dados importados, campos divergentes e observacao opcional.

### Nao encontrados no banco

Codigos de barras escaneados que nao existiam na auditoria ativa.

### Pendentes

Itens importados que ainda nao possuem resultado de auditoria.

## 9. Supabase e Sincronizacao

O Supabase continua sendo a fonte central para Web e APK.

O APK pode manter cache local para funcionamento com conexao instavel, mas a auditoria deve sincronizar com o Supabase. A decisao de offline completo deve ser tratada no plano de implementacao conforme o risco, porque bloqueio de duplicidade depende de estado compartilhado.

## 10. APK e Avisos de Seguranca

Nao e possivel garantir a ausencia total de avisos enquanto o app for distribuido por APK fora da Play Store. A atualizacao deve incluir endurecimento do build Android:

- revisar `applicationId`, nome e icone
- usar build release assinado
- manter a mesma chave de assinatura entre versoes
- revisar permissoes do AndroidManifest
- manter apenas permissoes necessarias
- avaliar atualizacao de `targetSdk` e dependencias Android
- hospedar APK e manifesto em HTTPS
- manter auto-update, mas revisar mensagens e fluxo para reduzir suspeita do Play Protect

Publicacao via Google Play, mesmo em canal interno/fechado, deve ser considerada no futuro se os avisos continuarem afetando a operacao.

## 11. Testes Esperados

- Importa XLSX com empresas misturadas.
- Rejeita codigo de barras duplicado na mesma auditoria.
- Cria auditoria e itens imutaveis.
- Scanner encontra item pelo codigo de barras.
- Entrada manual usa a mesma busca do scanner.
- Resultado correto e salvo sem alterar item importado.
- Resultado incorreto salva campos divergentes e observacao opcional.
- Codigo nao encontrado gera registro laranja.
- Bobina ja auditada e bloqueada em novo scan.
- Exportacao XLSX gera quatro abas esperadas.
- Historico de auditorias antigas permanece consultavel.
- APK nao exige login nem identificacao.

## 12. Riscos

- O formato real da planilha ainda nao foi fornecido; o parser deve ser flexivel e ajustavel.
- Sem login, nao ha rastreabilidade nominal de quem auditou.
- Sem sobrescrita, erros de toque podem exigir uma rotina futura de correcao administrativa.
- Offline completo pode criar conflito se dois celulares auditarem a mesma bobina ao mesmo tempo.
- Auto-update por APK fora da Play Store pode continuar gerando avisos de seguranca em alguns aparelhos.

## 13. Decisoes Aprovadas

- Abordagem escolhida: novo modulo de inventario preservando a base tecnica.
- Layout escolhido para o scan: dados importados e divergencia no mesmo painel.
- Importacao: apenas Web.
- Formato: apenas XLSX.
- Empresa: vem em coluna da planilha.
- Inventario: planilha unica com as duas empresas.
- Chave de busca: codigo de barras.
- APK: sem login e sem identificacao.
- Observacao em divergencia: opcional.
- Auditoria duplicada: bloqueada.
- Historico: mantido.
