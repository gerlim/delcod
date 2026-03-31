# DelCod Reading Layers Design

**Date:** 2026-03-30  
**Status:** Approved for implementation

## Goal

Preparar o DelCod para suportar futuras camadas de leitura, como bobinas de papel e chapas de papel, sem mudar a interface atual. A mudança deve ser estrutural: o app continua exibindo apenas o código, mas o pipeline interno passa a classificar a leitura, registrar o tipo identificado e reservar espaço para dados próprios por camada.

## Constraints

- Nenhuma mudança visível na UI nesta etapa.
- A lista global única continua sendo o fluxo principal.
- Scanner, entrada manual e importação devem passar pelo mesmo pipeline estrutural.
- Leituras antigas precisam continuar válidas.
- A arquitetura deve suportar classificação automática e possíveis ambiguidades entre tipos.

## Recommended Approach

Adotar um modelo de leitura em duas partes:

1. Um registro base comum para todas as leituras.
2. Uma camada interna de classificação por tipo, com payload específico por camada.

Esse desenho prepara o app para crescimento incremental sem forçar múltiplas tabelas ou fluxos específicos agora.

## Core Model

Cada leitura passa a conter, além dos campos atuais:

- `readingType`: tipo identificado, por exemplo `paper_bobbin`, `paper_sheet` ou `unknown`
- `classificationStatus`: `identified`, `ambiguous` ou `unknown`
- `classificationCandidates`: lista curta de candidatos quando houver ambiguidade
- `detailsPayload`: JSON com dados específicos do tipo, quando houver parsing disponível
- `schemaVersion`: versão do formato estrutural da leitura

## Classification Pipeline

Todas as entradas do app seguem o mesmo fluxo:

1. O app recebe um `code`
2. O `ReadingTypeClassifier` tenta classificar a leitura
3. O classificador consulta um registro interno de definições de tipo
4. O resultado volta com tipo, status, candidatos e payload
5. O repositório salva a leitura normalmente

## Type Definitions

Cada tipo futuro terá uma definição própria com responsabilidades claras:

- reconhecer se o código parece pertencer àquele tipo
- validar o padrão
- extrair metadados próprios quando possível

Nesta etapa, a base já nasce com definições para:

- `paper_bobbin`
- `paper_sheet` como stub estrutural
- `unknown`

## Ambiguity Handling

Como o mesmo código pode parecer válido para mais de um tipo:

- o app não tenta resolver isso na UI nesta etapa
- leituras ambíguas são salvas com `classificationStatus = ambiguous`
- os candidatos ficam registrados em `classificationCandidates`

Isso mantém o fluxo atual simples e preserva informação suficiente para uma futura resolução visual.

## Compatibility Strategy

Leituras já existentes continuam compatíveis:

- quando os novos campos não existirem, o app assume `unknown`
- o payload pode permanecer nulo
- `schemaVersion` permite evolução futura sem quebrar registros antigos

## Storage Changes

Tanto o armazenamento local quanto a tabela remota precisam suportar os novos campos estruturais. A sincronização continua com o mesmo comportamento offline-first, apenas levando junto os metadados novos.

## Impacted Areas

- `ReadingsController`: passa a classificar antes de salvar
- `ReadingsRepository`: passa a persistir os novos campos
- `shared_readings`: ganha colunas estruturais
- scanner, entrada manual e importação: passam a usar o mesmo pipeline de classificação

## Non-Goals

- Exibir tipos na interface
- Criar filtros por camada
- Resolver ambiguidades manualmente
- Implementar regras completas de negócio para chapas de papel

## Testing Focus

- classificação de leitura identificada
- classificação desconhecida
- classificação ambígua
- persistência local e remota dos novos campos
- compatibilidade com leituras antigas
- importação usando o mesmo pipeline estrutural
