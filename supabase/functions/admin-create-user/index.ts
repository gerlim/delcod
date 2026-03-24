import { createClient } from 'npm:@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';

type MembershipInput = {
  company_id: string;
  role: 'reader' | 'operator' | 'manager' | 'admin';
};

type AdminCreateUserRequest = {
  matricula: string;
  nome: string;
  memberships: MembershipInput[];
  global_role?: 'admin_global' | 'gestor_global' | null;
  temporary_password?: string;
};

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

if (!supabaseUrl || !serviceRoleKey) {
  throw new Error('SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY são obrigatórias.');
}

const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
  auth: {
    persistSession: false,
    autoRefreshToken: false,
  },
});

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authorization = request.headers.get('Authorization');
    if (!authorization?.startsWith('Bearer ')) {
      return jsonResponse({ error: 'Token de autorização ausente.' }, 401);
    }

    const token = authorization.replace('Bearer ', '');
    const {
      data: { user: requester },
      error: requesterError,
    } = await supabaseAdmin.auth.getUser(token);

    if (requesterError || !requester) {
      return jsonResponse({ error: 'Não foi possível validar o usuário solicitante.' }, 401);
    }

    const payload = (await request.json()) as AdminCreateUserRequest;
    const parsed = validatePayload(payload);

    const requesterAccess = await loadRequesterAccess(requester.id);
    if (!requesterAccess.isAllowed) {
      return jsonResponse({ error: 'Somente administradores podem criar usuários.' }, 403);
    }

    if (!requesterAccess.isGlobalAdmin) {
      const unauthorizedCompany = parsed.memberships.find(
        (membership) => !requesterAccess.adminCompanyIds.includes(membership.company_id),
      );

      if (unauthorizedCompany) {
        return jsonResponse(
          { error: 'O solicitante não possui administração para todas as empresas informadas.' },
          403,
        );
      }

      if (parsed.global_role) {
        return jsonResponse(
          { error: 'Somente admin global pode definir cargo global.' },
          403,
        );
      }
    }

    const primaryCompany = await loadCompany(parsed.memberships[0].company_id);
    const temporaryPassword = parsed.temporary_password || generateTemporaryPassword();
    const technicalEmail = `${primaryCompany.code}.${parsed.matricula}@local.barcode-app`;

    const { data: authUser, error: createUserError } =
      await supabaseAdmin.auth.admin.createUser({
        email: technicalEmail,
        password: temporaryPassword,
        email_confirm: true,
        user_metadata: {
          nome: parsed.nome,
          matricula: parsed.matricula,
        },
      });

    if (createUserError || !authUser.user) {
      return jsonResponse(
        { error: createUserError?.message ?? 'Não foi possível criar usuário no Auth.' },
        400,
      );
    }

    try {
      const userId = authUser.user.id;

      const { error: profileError } = await supabaseAdmin.from('profiles').insert({
        id: userId,
        matricula: parsed.matricula,
        nome: parsed.nome,
        status: 'active',
        cargo_global: parsed.global_role ?? null,
      });

      if (profileError) {
        throw profileError;
      }

      const membershipsToInsert = parsed.memberships.map((membership) => ({
        user_id: userId,
        company_id: membership.company_id,
        role: membership.role,
        status: 'active',
        granted_by: requester.id,
      }));

      const { error: membershipError } = await supabaseAdmin
        .from('company_memberships')
        .insert(membershipsToInsert);

      if (membershipError) {
        throw membershipError;
      }

      const { error: auditError } = await supabaseAdmin.from('audit_logs').insert({
        actor_id: requester.id,
        company_id: primaryCompany.id,
        target_table: 'profiles',
        target_id: userId,
        action: 'create_user',
        origin: 'edge_function',
        payload: {
          matricula: parsed.matricula,
          nome: parsed.nome,
          memberships: parsed.memberships,
          global_role: parsed.global_role ?? null,
        },
      });

      if (auditError) {
        throw auditError;
      }

      return jsonResponse(
        {
          user_id: userId,
          technical_email: technicalEmail,
          temporary_password: temporaryPassword,
        },
        201,
      );
    } catch (error) {
      await supabaseAdmin.auth.admin.deleteUser(authUser.user.id);
      throw error;
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Erro interno.';
    return jsonResponse({ error: message }, 500);
  }
});

function validatePayload(payload: AdminCreateUserRequest) {
  const matricula = payload.matricula?.trim();
  const nome = payload.nome?.trim();
  const memberships = payload.memberships ?? [];

  if (!matricula) {
    throw new Error('Matrícula é obrigatória.');
  }

  if (!nome) {
    throw new Error('Nome é obrigatório.');
  }

  if (!memberships.length) {
    throw new Error('Ao menos uma empresa deve ser vinculada ao usuário.');
  }

  const allowedRoles = new Set(['reader', 'operator', 'manager', 'admin']);
  const companyIds = new Set<string>();

  for (const membership of memberships) {
    if (!membership.company_id) {
      throw new Error('company_id é obrigatório em memberships.');
    }

    if (!allowedRoles.has(membership.role)) {
      throw new Error(`Papel inválido em memberships: ${membership.role}`);
    }

    if (companyIds.has(membership.company_id)) {
      throw new Error('Empresas duplicadas não são permitidas em memberships.');
    }

    companyIds.add(membership.company_id);
  }

  return {
    matricula,
    nome,
    memberships,
    global_role: payload.global_role ?? null,
    temporary_password: payload.temporary_password?.trim() || null,
  };
}

async function loadRequesterAccess(userId: string) {
  const { data: profile, error: profileError } = await supabaseAdmin
    .from('profiles')
    .select('cargo_global, status')
    .eq('id', userId)
    .maybeSingle();

  if (profileError) {
    throw new Error(profileError.message);
  }

  if (!profile || profile.status !== 'active') {
    return {
      isAllowed: false,
      isGlobalAdmin: false,
      adminCompanyIds: [] as string[],
    };
  }

  const isGlobalAdmin = profile.cargo_global === 'admin_global';
  const { data: memberships, error: membershipError } = await supabaseAdmin
    .from('company_memberships')
    .select('company_id, role, status')
    .eq('user_id', userId)
    .eq('status', 'active');

  if (membershipError) {
    throw new Error(membershipError.message);
  }

  const adminCompanyIds = (memberships ?? [])
    .filter((membership) => membership.role === 'admin')
    .map((membership) => membership.company_id);

  return {
    isAllowed: isGlobalAdmin || adminCompanyIds.length > 0,
    isGlobalAdmin,
    adminCompanyIds,
  };
}

async function loadCompany(companyId: string) {
  const { data, error } = await supabaseAdmin
    .from('companies')
    .select('id, code, name')
    .eq('id', companyId)
    .maybeSingle();

  if (error) {
    throw new Error(error.message);
  }

  if (!data) {
    throw new Error('Empresa informada não foi encontrada.');
  }

  return data;
}

function generateTemporaryPassword() {
  return crypto.randomUUID().replaceAll('-', '').slice(0, 12);
}

function jsonResponse(payload: unknown, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}
