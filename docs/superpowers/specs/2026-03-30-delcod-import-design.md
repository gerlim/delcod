# DelCod Importacao de Leituras

**Objetivo**

Adicionar importacao de leituras de codigos de barras ao DelCod, mantendo a tela principal como centro da operacao. O app deve continuar exportando em PDF e XLSX e passar a aceitar arquivos `XLSX` e `CSV` tanto no Android quanto no Web.

**Fluxo**

1. O usuario toca em `Importar arquivo`.
2. O app abre o seletor de arquivos e aceita `XLSX` ou `CSV`.
3. O app le o arquivo e monta uma previa das linhas.
4. O usuario escolhe qual coluna contem os codigos.
5. O usuario confirma se a primeira linha e cabecalho quando necessario.
6. O app analisa o lote completo e mostra um resumo:
   - total lido
   - coluna usada
   - novos
   - duplicados
7. O usuario escolhe:
   - `Importar somente os novos`
   - `Importar tudo mesmo assim`
   - `Cancelar`
8. O app grava os itens escolhidos localmente e sincroniza com o Supabase quando houver internet.

**Escopo**

- Importacao em Android e Web
- Arquivos `CSV` e `XLSX`
- Escolha explicita da coluna pelo usuario
- Arquivos com ou sem cabecalho
- Confirmacao por lote antes de gravar
- Reaproveitar a logica atual de duplicidade e sincronizacao

**Fora de Escopo**

- Importar metadados extras por empresa
- Mapeamento de multiplas colunas
- Regras de negocio diferentes por empresa
- Novo modulo ou nova tela dedicada

**Arquitetura**

- `ImportPicker`: escolhe o arquivo em Android e Web
- `ImportParser`: converte `CSV` e `XLSX` em uma estrutura comum de tabela
- `ImportPreviewModel`: guarda colunas, previa, cabecalho, coluna selecionada e resumo do lote
- `ImportController`: coordena leitura, selecao de coluna e confirmacao final
- `ReadingsController`: recebe uma nova operacao de importacao em lote
- `ReadingItem`: itens importados usam `source = import`

**Regras**

- A coluna escolhida e a unica fonte dos codigos nesta versao
- Valores vazios da coluna escolhida sao ignorados
- O `XLSX` usa somente a primeira planilha nesta versao
- O `CSV` aceita delimitador `;` ou `,`, com deteccao automatica
- A confirmacao de cabecalho acontece antes da escolha da coluna
- Duplicados sao calculados comparando com a lista ativa atual e com o proprio lote
- Quando o mesmo codigo aparece repetido no arquivo:
  - a primeira ocorrencia entra como nova se ainda nao existir na lista
  - todas as ocorrencias seguintes contam como duplicadas
- O resumo do lote aparece antes de qualquer gravacao
- `Importar somente os novos` ignora os duplicados do arquivo
- `Importar tudo mesmo assim` grava novos e duplicados

**Erros e Limites**

- Arquivo vazio: mostrar erro e nao abrir o resumo
- Arquivo invalido ou corrompido: mostrar erro amigavel e encerrar o fluxo
- Nenhuma coluna utilizavel: mostrar erro e nao permitir importar
- Lote com 100% duplicados: permitir continuar, mas mostrar isso claramente no resumo
- Exportacao no Android e demais plataformas app: abrir compartilhamento/salvar via fluxo nativo do dispositivo

**UI**

- O botao `Importar arquivo` entra em `Acoes da lista`
- O fluxo de importacao ocorre em modal/dialogo
- A tela principal continua sendo o centro da operacao
- A linguagem da interface permanece curta e operacional
