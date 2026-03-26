# Especificação V2 Simplificada

## Objetivo

Entregar um aplicativo simples para leitura e gestão de códigos de barras com uma única lista global.

## Escopo

- Abrir direto na operação, sem login.
- Android com leitura por câmera.
- Chrome/Web com entrada manual.
- Lista única global compartilhada entre dispositivos.
- Persistir no Supabase.
- Funcionar offline com sincronização posterior.
- Atualizar em tempo real quando houver internet.
- Avisar em caso de código duplicado e pedir confirmação.
- Permitir editar, excluir, selecionar itens específicos, selecionar todos e limpar tudo.
- Exportar para PDF e XLSX.

## Fora de Escopo

- Empresas.
- Permissões.
- Usuários.
- Área administrativa.
- Auditoria.
- Coletas/lotes.
- Aplicativo Windows.

## Fluxo Principal

1. O app abre na tela principal.
2. O usuário lê pela câmera no Android ou digita no Web.
3. O código entra na lista global.
4. Se houver duplicidade, o app pede confirmação.
5. A lista pode ser editada, excluída, selecionada e exportada.
6. Alterações locais continuam funcionando offline.
7. Quando houver internet, as mudanças sobem para o Supabase.
8. Alterações remotas são refletidas em tempo real.

## Arquitetura

- Flutter + Riverpod para interface e estado.
- Tela única principal.
- Repositório local para cache offline.
- Repositório remoto com Supabase para persistência global.
- Motor de sincronização para fila pendente e atualização em tempo real.

## Dados

Tabela remota e modelo local de leituras:

- `id`
- `code`
- `updated_at`
- `deleted_at`
- `source`
- `device_id`

Campos internos existem para sincronização. A interface do usuário mostra apenas o código.

## Regras

- Duplicado: avisar e deixar confirmar.
- Exportação: itens selecionados ou todos.
- Limpar tudo: exige confirmação.
- Lista exibida apenas com itens ativos.
- Resolução de conflito: última atualização vence.

## UI

- Cabeçalho com nome do app, status online/offline e total de itens.
- Área de ações com leitura, entrada manual, exportação e limpeza.
- Lista moderna, clara e operacional.
- Mobile com ação de scanner em destaque.
- Web com foco em digitação e conferência.
