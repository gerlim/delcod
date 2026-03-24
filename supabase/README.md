# Supabase Setup

## Estrutura

- `migrations/`: esquema inicial, funções auxiliares e políticas RLS
- `functions/admin-create-user/`: função administrativa para criação segura de usuários

## Aplicação local

```bash
supabase start
supabase db reset
supabase functions serve admin-create-user --env-file ./supabase/.env.local
```

## Vincular ao projeto remoto

```bash
supabase login
supabase link --project-ref <seu-project-ref>
supabase db push
supabase functions deploy admin-create-user
supabase secrets set SUPABASE_URL=https://seu-projeto.supabase.co SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
```

## Variáveis do servidor

Crie `supabase/.env.local` para desenvolvimento local da Edge Function:

```env
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
```

`SUPABASE_SERVICE_ROLE_KEY` é somente do servidor. Nunca use essa chave no Flutter Web.
