# DelCod Reading Layers Design

**Date:** 2026-03-30  
**Status:** Approved for implementation

## Goal

Preparar o DelCod para suportar futuras camadas de leitura, como bobinas de papel e chapas de papel, sem mudar a interface atual. A mudanca deve ser estrutural: nenhum novo campo de classificacao sera exibido agora, e a UI atual permanece igual, inclusive a indicacao de origem da leitura. O pipeline interno passa a classificar a leitura, registrar o tipo identificado e reservar espaco para dados proprios por camada.

## Constraints

- Nenhuma mudanca visivel na UI nesta etapa.
- A lista global unica continua sendo o fluxo principal.
- Scanner, entrada manual e importacao devem passar pelo mesmo pipeline estrutural.
- Leituras antigas precisam continuar validas.
- A arquitetura deve suportar classificacao automatica e possiveis ambiguidades entre tipos.

## Recommended Approach

Adotar um modelo de leitura em duas partes:

1. Um registro base comum para todas as leituras.
2. Uma camada interna de classificacao por tipo, com payload especifico por camada.

Esse desenho prepara o app para crescimento incremental sem forcar multiplas tabelas ou fluxos especificos agora.

## Core Model

Cada leitura passa a conter, alem dos campos atuais:

- `codeType`: tipo identificado, por exemplo `paper_bobbin`, `paper_sheet` ou `unknown`
- `classificationStatus`: `identified`, `ambiguous` ou `unknown`
- `classificationCandidates`: lista ordenada, sem duplicatas, contendo apenas ids de tipo, por exemplo `["paper_bobbin", "paper_sheet"]`
- `detailsPayload`: objeto JSON ou `null`, com dados especificos do tipo quando houver parsing disponivel
- `metadataPayload`: objeto JSON ou `null`, com metadados adicionais capturados por importacao ou enriquecimento futuro
- `schemaVersion`: versao do formato estrutural da leitura

Defaults canonicos:

- `codeType = unknown`
- `classificationStatus = unknown`
- `classificationCandidates = []`
- `detailsPayload = null`
- `metadataPayload = null`
- `schemaVersion = 1`

Nesta fase, `detailsPayload` deve permanecer pequeno e serializavel em JSON plano para nao aumentar risco no cache local e na sincronizacao remota.

Combinacao canonica por status:

- `identified`
  - `codeType = <tipo identificado>`
  - `classificationCandidates = []`
  - `detailsPayload = objeto JSON ou null`
  - `metadataPayload = objeto JSON ou null`
- `ambiguous`
  - `codeType = unknown`
  - `classificationCandidates = lista ordenada e sem duplicatas, com 2 ou mais candidatos`
  - `detailsPayload = null`
  - `metadataPayload = objeto JSON ou null`
- `unknown`
  - `codeType = unknown`
  - `classificationCandidates = []`
  - `detailsPayload = null`
  - `metadataPayload = objeto JSON ou null`

## Classification Pipeline

Todas as entradas do app seguem o mesmo fluxo:

1. O app recebe um `code`
2. O `ReadingTypeClassifier` tenta classificar a leitura
3. O classificador consulta um registro interno de definicoes de tipo
4. O resultado volta com tipo, status, candidatos e payload
5. O resultado e empacotado em um contrato de persistencia comum
6. O repositorio salva a leitura normalmente

## Type Definitions

Cada tipo futuro tera uma definicao propria com responsabilidades claras:

- reconhecer se o codigo parece pertencer aquele tipo
- validar o padrao
- extrair metadados proprios quando possivel

Nesta etapa, a base ja nasce com definicoes para:

- `paper_bobbin`
- `paper_sheet` como stub estrutural
- `unknown`

## Ambiguity Handling

Como o mesmo codigo pode parecer valido para mais de um tipo:

- o app nao tenta resolver isso na UI nesta etapa
- leituras ambiguas sao salvas com `classificationStatus = ambiguous`
- os candidatos ficam registrados em `classificationCandidates`

Isso mantem o fluxo atual simples e preserva informacao suficiente para uma futura resolucao visual.

## Duplicate Rule

Nesta fase, a identidade da leitura continua sendo apenas o valor de `code`.

- duplicidade em leitura manual
- duplicidade em leitura por camera
- duplicidade em edicao
- duplicidade em importacao em lote

Todas continuam comparando somente `code`, sem considerar `codeType`.

Essa decisao mantem compatibilidade com o comportamento atual da lista global unica. Quando houver fluxos especificos por camada, essa regra podera evoluir para `code + codeType`, mas isso nao faz parte desta etapa.

## Compatibility Strategy

Leituras ja existentes continuam compativeis:

- quando os novos campos nao existirem, o app assume os defaults canonicos
- `schemaVersion` permite evolucao futura sem quebrar registros antigos

Essa compatibilidade vale para:

- registros ativos carregados do cache local
- fila pendente offline
- snapshots recebidos do Supabase

Registros antigos lidos do cache ou da fila devem ser reidratados com defaults, reenfileirados normalmente quando necessario e regravados ja no formato novo apos a proxima persistencia.

## Storage Changes

Tanto o armazenamento local quanto a tabela remota precisam suportar os novos campos estruturais. A sincronizacao continua com o mesmo comportamento offline-first, apenas levando junto os metadados novos.

Wire format canonico:

- `code_type`: string
- `classification_status`: string
- `classification_candidates`: array JSON
- `details_payload`: objeto JSON ou `null`
- `metadata_payload`: objeto JSON ou `null`
- `schema_version`: inteiro

## Impacted Areas

- `ReadingsController`: passa a classificar antes de salvar e tambem antes de editar
- `ReadingsRepository`: passa a persistir os novos campos por meio de um contrato estruturado de entrada, mantendo compatibilidade temporaria com a API atual ate o controller e as fakes migrarem
- `shared_readings`: ganha colunas estruturais
- scanner, entrada manual e importacao: passam a usar o mesmo pipeline de classificacao
- importacao: ganha suporte interno para mapear colunas extras em `metadataPayload`, sem expor isso na UI ainda
- reprocessamento: ganha um fluxo interno para recalcular classificacao preservando `metadataPayload`

## Non-Goals

- Exibir tipos na interface
- Criar filtros por camada
- Resolver ambiguidades manualmente
- Implementar regras completas de negocio para chapas de papel

## Testing Focus

- classificacao de leitura identificada
- classificacao desconhecida
- classificacao ambigua
- reclassificacao ao editar um codigo existente
- persistencia local e remota dos novos campos
- compatibilidade com leituras antigas e fila offline pendente
- importacao usando o mesmo pipeline estrutural
