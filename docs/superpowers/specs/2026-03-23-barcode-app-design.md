# Aplicativo de Leitura e Gestao de Codigos de Barras

Data: 2026-03-23
Status: Design aprovado para planejamento

## 1. Visao executiva

Este documento define a arquitetura e os processos da V1 de um aplicativo industrial para leitura e gestao de codigos de barras, com foco inicial em expedicao e estoque.

O produto sera construido com Flutter e priorizara:

- Operacao offline no Android para leitura por camera
- Operacao web no Chrome para coleta manual e exportacao
- Operacao desktop para gestao, usuarios, permissoes e auditoria
- Persistencia local com sincronizacao para o Supabase
- Seguranca forte, multiempresa e segregacao de funcao

O objetivo da V1 e entregar uma base confiavel para operacao em campo, com baixa dependencia de conectividade, rastreabilidade de alteracoes e capacidade de evolucao futura para:

- leitura de codigos em PDF
- catalogo de codigos ja lidos
- geracao de codigo de barras
- ampliacao de fluxos administrativos e de integracao

## 2. Escopo da V1

### Incluido

- Scanner por camera no Android
- Entrada manual de codigo no Chrome
- Painel desktop para gestao e auditoria
- Lista de leituras em tempo real
- Contador total por coleta
- Regra de duplicidade com aviso e confirmacao do usuario
- Exportacao em `.xlsx`
- Exportacao em `.pdf`
- Persistencia local offline-first
- Sincronizacao com Supabase
- Multiempresa
- Permissoes por papel
- Criacao de usuarios somente por admin
- Login por matricula

### Fora da V1

- Leitura de codigos a partir de PDF
- Scanner por camera no desktop
- Scanner por camera no Chrome
- Integracoes com ERP/WMS
- Geracao de codigo de barras
- Regras avancadas de analytics ou aprendizado sobre catalogo historico

## 3. Canais de uso por plataforma

### Android

Uso principal operacional.

- Login online inicial por dispositivo
- Scanner por camera
- Funcionamento offline
- Lista da coleta
- Sincronizacao posterior

### Chrome Web

Uso operacional complementar e administrativo leve.

- Login por matricula
- Entrada manual de codigo
- Consulta de coletas
- Exportacao
- Sem scanner por camera na V1

### Desktop Windows

Uso administrativo e de gestao.

- Gestao de usuarios
- Gestao de permissoes
- Acompanhamento de coletas
- Edicao e exclusao conforme papel
- Auditoria
- Sem scanner por camera na V1

## 4. Arquitetura recomendada

### Stack

- Flutter
- Riverpod
- MVVM
- Drift com SQLite/WASM
- Supabase Auth
- Supabase Postgres
- Supabase Row Level Security
- Supabase Edge Functions
- Vercel para hospedagem do frontend web/PWA
- `mobile_scanner` para scanner por camera
- `excel` para exportacao `.xlsx`
- `pdf` e `printing` para exportacao `.pdf`

### Justificativa tecnica

O sistema precisa suportar:

- operacao offline real
- auditoria
- multiplas empresas
- regras de permissao
- fila de sincronizacao
- consultas estruturadas

Por isso, a base recomendada e:

- Flutter para reaproveitamento entre Android, Web e Desktop
- Riverpod para atualizacao reativa e composicao limpa de estado
- Drift para modelagem local relacional com melhor aderencia a sync, auditoria e consultas
- Supabase como camada de autenticacao, persistencia em nuvem e seguranca

## 5. Arquitetura funcional

### 5.1 Superficies do sistema

- Android: leitura por camera
- Chrome: coleta manual
- Desktop: gestao e auditoria

### 5.2 Nucleo compartilhado

O nucleo sera compartilhado entre as plataformas, com adaptadores por ambiente.

Camadas:

1. App shell
2. ViewModels
3. Casos de uso
4. Repositorios
5. Banco local
6. Motor de sincronizacao
7. Adaptadores de plataforma

### 5.3 Modulos principais

#### Auth e sessao

- login por matricula
- controle de sessao
- cache local de identidade e permissoes
- revalidacao apos novo login online

#### Empresas e acessos

- cadastro de empresas
- vinculo de usuarios por empresa
- papel por empresa
- cargos globais para acessos ampliados

#### Coletas

- criar coleta
- abrir coleta
- registrar leituras
- fechar coleta
- exportar coleta

#### Leituras

- leitura por camera no Android
- entrada manual no Web/Desktop conforme permissao
- regra de duplicidade
- lista visual em tempo real
- historico de alteracoes

#### Sincronizacao

- gravacao local imediata
- fila local de eventos
- sincronizacao assicrona
- retentativas
- reconciliacao de estado

#### Administracao

- criacao de usuario
- definicao de papeis
- liberacao de acesso multiempresa
- bloqueio de acesso
- consulta de auditoria

## 6. Modelo de permissao

O modelo de seguranca tera duas camadas:

### 6.1 Cargo global

Usado para controlar privilegios amplos, especialmente em ambiente multiempresa.

Exemplos:

- admin global
- gestor global

### 6.2 Papel por empresa

Define o que o usuario pode fazer dentro de cada empresa.

Papeis aprovados:

- Leitor
- Operador
- Gestor
- Admin

### 6.3 Capacidades por papel

#### Leitor

- pode ler codigo
- pode visualizar coletas permitidas
- nao pode editar ou excluir leitura

#### Operador

- pode ler codigo
- pode editar leitura
- pode excluir leitura

#### Gestor

- pode exportar
- pode fechar coleta
- pode visualizar coletas da equipe
- pode acompanhar auditoria operacional

#### Admin

- possui todas as capacidades anteriores
- cria usuarios
- altera papeis
- libera acesso multiempresa
- bloqueia acessos

### 6.4 Regra organizacional

Um usuario pode ter acesso a varias empresas, mas isso nao ocorre por padrao.

- cargos altos podem receber acesso a varias empresas
- leitores entram apenas nas empresas explicitamente liberadas pelo admin
- o acesso real deve ser aplicado no banco com RLS, nao apenas escondendo botoes no cliente

## 7. Login por matricula

O login do usuario no app sera por matricula numerica e senha.

### Decisao funcional

- o usuario nao usara email como identidade operacional
- a matricula sera o identificador visivel no fluxo de login

### Decisao tecnica

O Supabase Auth exige identidade de autenticacao baseada em email, phone ou provedor externo. Para manter login por matricula sem expor email ao usuario final, a arquitetura adotara:

- `auth.users` como identidade tecnica
- `profiles` como identidade operacional do app
- associacao da matricula numerica ao usuario tecnico

Essa abordagem preserva:

- login operacional por matricula
- compatibilidade com o Supabase
- controle administrativo centralizado

## 8. Estrutura de dados recomendada

### Tabelas de dominio

#### companies

- id
- nome
- status
- criado_em

#### profiles

- id
- matricula
- nome
- status
- ultimo_login

#### global_roles

- user_id
- cargo_global

#### company_memberships

- user_id
- company_id
- role
- status

#### collections

- id
- company_id
- titulo
- status
- criado_por
- aberto_em
- fechado_em

#### readings

- id
- collection_id
- codigo
- tipo
- origem
- criado_por
- criado_em
- duplicado_confirmado
- sincronizado_em

#### audit_logs

- id
- actor_id
- company_id
- acao
- alvo_tipo
- alvo_id
- antes
- depois
- dispositivo
- criado_em

### Estruturas locais

#### sync_queue

- id
- entidade
- operacao
- payload
- tentativas
- status
- ultimo_erro
- criado_em

#### device_session

- usuario atual
- empresa ativa
- permissoes em cache
- token de sessao valido

## 9. Fluxos operacionais

### 9.1 Fluxo principal de leitura

1. Usuario faz login online ao menos uma vez no dispositivo
2. App baixa sessao, empresas permitidas e permissoes
3. Usuario abre ou seleciona uma coleta
4. Usuario le codigo pela camera no Android
5. ViewModel valida sessao, papel e coleta aberta
6. Regra de duplicidade verifica se o codigo ja existe na coleta
7. Se houver duplicidade, o sistema avisa e o usuario decide continuar ou cancelar
8. A leitura e gravada imediatamente no banco local
9. A lista visual atualiza instantaneamente
10. Um evento e adicionado na fila local de sincronizacao
11. Quando houver conectividade, o app envia as alteracoes ao Supabase
12. O servidor confirma a gravacao e registra auditoria

### 9.2 Fluxo de coleta manual no Chrome

1. Usuario autorizado faz login
2. Seleciona a empresa e a coleta permitida
3. Digita o codigo manualmente
4. O mesmo fluxo de validacao e duplicidade e aplicado
5. A leitura entra no banco local/web e sincroniza quando possivel

### 9.3 Fluxo administrativo

1. Admin acessa o painel
2. Cria um usuario
3. Define matricula, nome, empresa(s) e papel(is)
4. Se necessario, concede cargo global
5. O sistema passa a liberar as empresas e funcoes correspondentes

### 9.4 Fluxo de exportacao

1. Usuario com permissao acessa uma coleta
2. Seleciona exportar
3. O app gera `.xlsx` ou `.pdf`
4. O arquivo e baixado no navegador ou salvo localmente no ambiente suportado

## 10. Estrategia offline-first

### Regras

- toda leitura valida e gravada primeiro no banco local
- a sincronizacao nunca deve bloquear a operacao de leitura
- o sistema deve sobreviver a perda de internet
- o dispositivo precisa ter feito login online ao menos uma vez

### Beneficios

- continuidade operacional em expedicao e estoque
- melhor experiencia em ambientes com sinal instavel
- menor risco de perda de leitura durante operacao

### Cuidados

- cache de permissao precisa expirar ou ser revalidado periodicamente
- conflitos devem ser tratados com regras simples
- auditoria deve registrar origem da alteracao e dispositivo

## 11. Seguranca

### Controles principais

- login online inicial obrigatorio por dispositivo
- sessao local somente apos autenticacao valida
- RLS por empresa e papel
- criacao de usuarios somente por admin
- Edge Function para operacoes administrativas sensiveis
- cliente nunca recebe chave privilegiada do Supabase
- auditoria de criacao, edicao, exclusao e fechamento de coleta

### Principios

- minimo privilegio
- segregacao de funcao
- isolamento entre empresas
- rastreabilidade

## 12. Regras de negocio aprovadas

- o fluxo principal da V1 e camera no Android
- Chrome sera usado para coleta manual e consulta
- Desktop sera usado para gestao
- duplicidade deve avisar e deixar o usuario decidir
- login operacional sera por matricula numerica
- o sistema sera multiempresa
- usuarios podem acessar varias empresas apenas com liberacao do admin
- leitores so entram por permissao direta do admin
- somente admin cria novos usuarios

## 13. Roadmap recomendado

### Fase 1

- fundacao do projeto Flutter
- autenticacao
- empresas, usuarios e papeis
- banco local e sincronizacao base

### Fase 2

- coletas
- leitura por camera no Android
- lista em tempo real
- regra de duplicidade

### Fase 3

- coleta manual no Chrome
- exportacao `.xlsx`
- exportacao `.pdf`
- auditoria

### Fase 4

- painel desktop
- administracao multiempresa
- refinamentos de seguranca

### Fase futura

- leitura de PDF
- catalogo de codigos
- geracao de codigo de barras
- integracoes corporativas

## 14. Riscos e mitigacoes

### Risco: comportamento diferente por plataforma

Mitigacao:

- manter scanner por camera apenas no Android na V1
- usar adaptadores especificos por plataforma

### Risco: conflitos de sincronizacao

Mitigacao:

- gravacao local com fila
- regras simples de reconciliacao
- auditoria detalhada

### Risco: permissao local desatualizada

Mitigacao:

- login online inicial obrigatorio
- revalidacao periodica
- refresh de contexto ao voltar a ficar online

## 15. Referencias tecnicas verificadas

- `mobile_scanner` possui suporte documentado para Android e web, com implementacao web baseada em ZXing: https://pub.dev/packages/mobile_scanner
- Drift documenta suporte web com `WasmDatabase.open` e persistencia via navegador: https://drift.simonbinder.eu/platforms/web/
- Supabase documenta autenticacao baseada em `email` ou `phone` para metodos com senha, alem de outras identidades: https://supabase.com/docs/guides/auth/users
- Criacao administrativa de usuario no Supabase deve ocorrer no servidor e nao no navegador: https://supabase.com/docs/reference/javascript/auth-admin-createuser

## 16. Aprovacao de design

O design aprovado nesta data estabelece a base para o planejamento de implementacao da V1.

Proximo passo recomendado:

- converter este design em um plano de execucao por fases e entregas tecnicas
