import { createClient } from 'npm:@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';

type MembershipInput = {
  company_code: string;
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
const technicalEmailDomain = 'barcode-app.test';

if (!supabaseUrl || !serviceRoleKey) {
  throw new Error('SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY sao obrigatorias.');
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
      return jsonResponse({ error: 'Token de autorizacao ausente.' }, 401);
    }

    const token = authorization.replace('Bearer ', '');
    const {
      data: { user: requester },
      error: requesterError,
    } = await supabaseAdmin.auth.getUser(token);

    if (requesterError || !requester) {
      return jsonResponse({ error: 'Nao foi possivel validar o usuario solicitante.' }, 401);
    }

    const payload = (await request.json()) as AdminCreateUserRequest;
    const parsed = validatePayload(payload);
    const requesterAccess = await loadRequesterAccess(requester.id);

    if (!requesterAccess.isAllowed) {
      return jsonResponse({ error: 'Somente administradores podem criar usuarios.' }, 403);
    }

    const companies = await loadCompaniesByCode(parsed.memberships.map((membership) => membership.company_code));
    const companyIdByCode = new Map(companies.map((company) => [company.code, company.id]));
    const unauthorizedCompany = parsed.memberships.find((membership) => {
      const companyId = companyIdByCode.get(membership.company_code);
      if (!companyId) {
        return true;
      }

      if (requesterAccess.isGlobalAdmin) {
        return false;
      }

      return !requesterAccess.adminCompanyIds.includes(companyId);
    });

    if (unauthorizedCompany) {
      return jsonResponse(
        { error: 'O solicitante nao possui administracao para todas as empresas informadas.' },
        403,
      );
    }

    if (!requesterAccess.isGlobalAdmin && parsed.global_role) {
      return jsonResponse(
        { error: 'Somente admin global pode definir cargo global.' },
        403,
      );
    }

    const primaryCompany = companies[0];
    const technicalEmail = `${parsed.matricula}@${technicalEmailDomain}`;

    const { data: authUser, error: createUserError } =
      await supabaseAdmin.auth.admin.createUser({
        email: technicalEmail,
        password: parsed.temporary_password,
        email_confirm: true,
        user_metadata: {
          nome: parsed.nome,
          matricula: parsed.matricula,
        },
      });

    if (createUserError || !authUser.user) {
      return jsonResponse(
        { error: createUserError?.message ?? 'Nao foi possivel criar usuario no Auth.' },
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
        company_id: companyIdByCode.get(membership.company_code),
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
  const temporaryPassword = payload.temporary_password?.trim();

  if (!matricula) {
    throw new Error('Matricula e obrigatoria.');
  }

  if (!nome) {
    throw new Error('Nome e obrigatorio.');
  }

  if (!temporaryPassword) {
    throw new Error('Senha inicial e obrigatoria.');
  }

  if (!memberships.length) {
    throw new Error('Ao menos uma empresa deve ser vinculada ao usuario.');
  }

  const allowedRoles = new Set(['reader', 'operator', 'manager', 'admin']);
  const companyCodes = new Set<string>();

  for (const membership of memberships) {
    if (!membership.company_code) {
      throw new Error('company_code e obrigatorio em memberships.');
    }

    if (!allowedRoles.has(membership.role)) {
      throw new Error(`Papel invalido em memberships: ${membership.role}`);
    }

    if (companyCodes.has(membership.company_code)) {
      throw new Error('Empresas duplicadas nao sao permitidas em memberships.');
    }

    companyCodes.add(membership.company_code);
  }

  return {
    matricula,
    nome,
    memberships,
    global_role: payload.global_role ?? null,
    temporary_password: temporaryPassword,
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

async function loadCompaniesByCode(companyCodes: string[]) {
  const { data, error } = await supabaseAdmin
    .from('companies')
    .select('id, code, name')
    .in('code', companyCodes);

  if (error) {
    throw new Error(error.message);
  }

  const companies = data ?? [];
  if (companies.length !== companyCodes.length) {
    throw new Error('Uma ou mais empresas informadas nao foram encontradas.');
  }

  return companyCodes.map((companyCode) => {
    const company = companies.find((item) => item.code === companyCode);
    if (!company) {
      throw new Error('Empresa informada nao foi encontrada.');
    }

    return company;
  });
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
