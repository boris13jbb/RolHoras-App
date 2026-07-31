-- 001_init_schema.sql
-- Esquema multiempresa SaaS Rol de Pagos + RLS
-- Idempotente en lo posible para entornos locales.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------
DO $$ BEGIN
  CREATE TYPE membership_role AS ENUM (
    'owner', 'admin', 'payroll_manager', 'auditor', 'employee'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE membership_status AS ENUM (
    'active', 'invited', 'suspended', 'removed'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE gmail_connection_status AS ENUM (
    'connecting', 'active', 'syncing', 'requires_reauth', 'revoked', 'error'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE document_status AS ENUM (
    'uploaded', 'validating', 'queued', 'processing',
    'needs_password', 'needs_review', 'completed', 'failed'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE job_status AS ENUM (
    'pending', 'running', 'succeeded', 'failed', 'dead'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE subscription_status AS ENUM (
    'trialing', 'active', 'past_due', 'canceled', 'grace', 'expired'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ---------------------------------------------------------------------------
-- Core identity / multiempresa
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  timezone TEXT NOT NULL DEFAULT 'America/Guayaquil',
  is_personal BOOLEAN NOT NULL DEFAULT FALSE,
  retention_days INTEGER NOT NULL DEFAULT 365,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY, -- auth.users.id when using Supabase
  email TEXT NOT NULL UNIQUE,
  full_name TEXT,
  avatar_url TEXT,
  locale TEXT NOT NULL DEFAULT 'es',
  mfa_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS memberships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  role membership_role NOT NULL DEFAULT 'employee',
  status membership_status NOT NULL DEFAULT 'active',
  invited_email TEXT,
  invited_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (organization_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_memberships_user ON memberships(user_id);
CREATE INDEX IF NOT EXISTS idx_memberships_org ON memberships(organization_id);

CREATE TABLE IF NOT EXISTS employees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  employee_code TEXT,
  display_name TEXT NOT NULL,
  document_id TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (organization_id, user_id)
);

CREATE TABLE IF NOT EXISTS invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  role membership_role NOT NULL DEFAULT 'employee',
  token_hash TEXT NOT NULL UNIQUE,
  invited_by UUID NOT NULL REFERENCES profiles(id),
  expires_at TIMESTAMPTZ NOT NULL,
  accepted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (organization_id, email)
);

CREATE TABLE IF NOT EXISTS consents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  document_type TEXT NOT NULL,
  document_version TEXT NOT NULL,
  accepted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  ip_hash TEXT,
  UNIQUE (user_id, document_type, document_version)
);

-- ---------------------------------------------------------------------------
-- Gmail
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS gmail_connections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  google_account_id TEXT,
  email_address TEXT,
  refresh_token_ciphertext TEXT,
  refresh_token_key_version TEXT,
  scopes TEXT[] NOT NULL DEFAULT ARRAY['https://www.googleapis.com/auth/gmail.readonly'],
  history_id TEXT,
  watch_expiration TIMESTAMPTZ,
  sender_filter TEXT,
  subject_pattern TEXT,
  last_sync_at TIMESTAMPTZ,
  last_success_at TIMESTAMPTZ,
  status gmail_connection_status NOT NULL DEFAULT 'connecting',
  last_error_code TEXT,
  last_error_message TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (organization_id, user_id)
);

CREATE TABLE IF NOT EXISTS gmail_oauth_states (
  state TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  code_verifier TEXT,
  nonce TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS gmail_sync_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  connection_id UUID NOT NULL REFERENCES gmail_connections(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  history_id TEXT,
  pubsub_message_id TEXT,
  payload_digest TEXT,
  status TEXT NOT NULL DEFAULT 'received',
  error_code TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  processed_at TIMESTAMPTZ,
  UNIQUE (pubsub_message_id)
);

CREATE INDEX IF NOT EXISTS idx_gmail_sync_events_connection
  ON gmail_sync_events(connection_id, created_at DESC);

-- ---------------------------------------------------------------------------
-- Documents / extraction
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS payroll_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  employee_id UUID REFERENCES employees(id) ON DELETE SET NULL,
  owner_user_id UUID NOT NULL REFERENCES profiles(id),
  gmail_connection_id UUID REFERENCES gmail_connections(id) ON DELETE SET NULL,
  gmail_message_id TEXT,
  gmail_attachment_id TEXT,
  source TEXT NOT NULL DEFAULT 'gmail', -- gmail | manual
  original_filename TEXT,
  content_sha256 TEXT NOT NULL,
  storage_path TEXT NOT NULL,
  mime_type TEXT NOT NULL DEFAULT 'application/pdf',
  size_bytes BIGINT NOT NULL,
  period_year INTEGER,
  period_month INTEGER,
  status document_status NOT NULL DEFAULT 'uploaded',
  status_message TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (organization_id, content_sha256),
  UNIQUE (gmail_connection_id, gmail_message_id, gmail_attachment_id)
);

CREATE TABLE IF NOT EXISTS payroll_document_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id UUID NOT NULL REFERENCES payroll_documents(id) ON DELETE CASCADE,
  version_number INTEGER NOT NULL,
  storage_path TEXT NOT NULL,
  content_sha256 TEXT NOT NULL,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (document_id, version_number)
);

CREATE TABLE IF NOT EXISTS pdf_secrets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  password_ciphertext TEXT NOT NULL,
  key_version TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (organization_id, user_id)
);

CREATE TABLE IF NOT EXISTS extraction_runs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id UUID NOT NULL REFERENCES payroll_documents(id) ON DELETE CASCADE,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  parser_name TEXT NOT NULL,
  parser_version TEXT NOT NULL,
  overall_confidence NUMERIC(5,4),
  warnings JSONB NOT NULL DEFAULT '[]'::jsonb,
  requires_review BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS extracted_fields (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  extraction_run_id UUID NOT NULL REFERENCES extraction_runs(id) ON DELETE CASCADE,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  field_key TEXT NOT NULL,
  field_value TEXT,
  page_number INTEGER,
  label_text TEXT,
  evidence_snippet TEXT,
  confidence NUMERIC(5,4),
  is_manual_override BOOLEAN NOT NULL DEFAULT FALSE,
  overridden_by UUID REFERENCES profiles(id),
  overridden_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS processing_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  document_id UUID REFERENCES payroll_documents(id) ON DELETE CASCADE,
  job_type TEXT NOT NULL,
  status job_status NOT NULL DEFAULT 'pending',
  attempts INTEGER NOT NULL DEFAULT 0,
  max_attempts INTEGER NOT NULL DEFAULT 5,
  available_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  locked_at TIMESTAMPTZ,
  locked_by TEXT,
  last_error_code TEXT,
  last_error_message TEXT,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_processing_jobs_pending
  ON processing_jobs(status, available_at)
  WHERE status IN ('pending', 'failed');

-- ---------------------------------------------------------------------------
-- Hours / rules / balances
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS calculation_rule_sets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  version INTEGER NOT NULL,
  effective_from DATE NOT NULL,
  effective_to DATE,
  unit TEXT NOT NULL DEFAULT 'hours', -- hours | minutes
  formula JSONB NOT NULL,
  created_by UUID REFERENCES profiles(id),
  change_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (organization_id, name, version)
);

CREATE TABLE IF NOT EXISTS hour_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  employee_id UUID REFERENCES employees(id) ON DELETE SET NULL,
  user_id UUID NOT NULL REFERENCES profiles(id),
  entry_date DATE NOT NULL,
  period_year INTEGER NOT NULL,
  period_month INTEGER NOT NULL,
  minutes INTEGER NOT NULL, -- duración en minutos enteros
  surcharge_percent NUMERIC(8,4) NOT NULL DEFAULT 100,
  equivalent_minutes INTEGER NOT NULL,
  entry_type TEXT NOT NULL DEFAULT 'worked', -- worked | paid | adjustment | compensation
  notes TEXT,
  rule_set_id UUID REFERENCES calculation_rule_sets(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS period_balances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id),
  employee_id UUID REFERENCES employees(id),
  period_year INTEGER NOT NULL,
  period_month INTEGER NOT NULL,
  debt_minutes INTEGER NOT NULL DEFAULT 0,
  paid_minutes INTEGER NOT NULL DEFAULT 0,
  pending_minutes INTEGER NOT NULL DEFAULT 0,
  credit_minutes INTEGER NOT NULL DEFAULT 0,
  monetary_amount NUMERIC(18,4),
  currency TEXT NOT NULL DEFAULT 'USD',
  is_closed BOOLEAN NOT NULL DEFAULT FALSE,
  rule_set_id UUID REFERENCES calculation_rule_sets(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (organization_id, user_id, period_year, period_month)
);

-- ---------------------------------------------------------------------------
-- Subscriptions / entitlements / audit
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  max_employees INTEGER,
  max_documents_per_month INTEGER,
  max_storage_bytes BIGINT,
  features JSONB NOT NULL DEFAULT '{}'::jsonb,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  plan_id UUID NOT NULL REFERENCES plans(id),
  status subscription_status NOT NULL DEFAULT 'trialing',
  provider TEXT NOT NULL DEFAULT 'noop',
  provider_subscription_id TEXT,
  trial_ends_at TIMESTAMPTZ,
  current_period_start TIMESTAMPTZ,
  current_period_end TIMESTAMPTZ,
  cancel_at TIMESTAMPTZ,
  grace_ends_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (organization_id)
);

CREATE TABLE IF NOT EXISTS entitlements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  feature_key TEXT NOT NULL,
  limit_value BIGINT,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  UNIQUE (organization_id, feature_key)
);

CREATE TABLE IF NOT EXISTS payment_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
  provider TEXT NOT NULL,
  event_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  payload_digest TEXT,
  processed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (provider, event_id)
);

CREATE TABLE IF NOT EXISTS audit_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
  actor_user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  correlation_id TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_audit_org_created
  ON audit_events(organization_id, created_at DESC);

-- Seed planes base
INSERT INTO plans (code, name, max_employees, max_documents_per_month, max_storage_bytes, features)
VALUES
  ('personal', 'Personal', 1, 24, 524288000, '{"gmail":true,"manual_upload":true}'::jsonb),
  ('empresa', 'Empresa', 50, 500, 5368709120, '{"gmail":true,"manual_upload":true,"audit":true}'::jsonb),
  ('empresa_pro', 'Empresa Pro', 500, 5000, 53687091200, '{"gmail":true,"ocr":true,"api":true}'::jsonb)
ON CONFLICT (code) DO NOTHING;

-- ---------------------------------------------------------------------------
-- Helpers RLS (compatibles con JWT claims de Supabase)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.current_user_id() RETURNS UUID
LANGUAGE sql STABLE AS $$
  SELECT NULLIF(current_setting('request.jwt.claim.sub', true), '')::uuid;
$$;

CREATE OR REPLACE FUNCTION public.is_org_member(org_id UUID) RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM memberships m
    WHERE m.organization_id = org_id
      AND m.user_id = public.current_user_id()
      AND m.status = 'active'
  );
$$;

CREATE OR REPLACE FUNCTION public.org_role(org_id UUID) RETURNS membership_role
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT m.role FROM memberships m
  WHERE m.organization_id = org_id
    AND m.user_id = public.current_user_id()
    AND m.status = 'active'
  LIMIT 1;
$$;

ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE gmail_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE gmail_sync_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE payroll_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE payroll_document_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE pdf_secrets ENABLE ROW LEVEL SECURITY;
ALTER TABLE extraction_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE extracted_fields ENABLE ROW LEVEL SECURITY;
ALTER TABLE processing_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE hour_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE calculation_rule_sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE period_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE entitlements ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE consents ENABLE ROW LEVEL SECURITY;

-- Profiles: el usuario ve/edita el suyo
DROP POLICY IF EXISTS profiles_self ON profiles;
CREATE POLICY profiles_self ON profiles
  FOR ALL USING (id = public.current_user_id())
  WITH CHECK (id = public.current_user_id());

-- Organizations: miembros activos
DROP POLICY IF EXISTS orgs_member_select ON organizations;
CREATE POLICY orgs_member_select ON organizations
  FOR SELECT USING (public.is_org_member(id));

DROP POLICY IF EXISTS orgs_owner_update ON organizations;
CREATE POLICY orgs_owner_update ON organizations
  FOR UPDATE USING (public.org_role(id) IN ('owner', 'admin'));

-- Memberships
DROP POLICY IF EXISTS memberships_select ON memberships;
CREATE POLICY memberships_select ON memberships
  FOR SELECT USING (public.is_org_member(organization_id));

DROP POLICY IF EXISTS memberships_admin_write ON memberships;
CREATE POLICY memberships_admin_write ON memberships
  FOR ALL USING (public.org_role(organization_id) IN ('owner', 'admin'))
  WITH CHECK (public.org_role(organization_id) IN ('owner', 'admin'));

-- Employees
DROP POLICY IF EXISTS employees_select ON employees;
CREATE POLICY employees_select ON employees
  FOR SELECT USING (
    public.is_org_member(organization_id)
    AND (
      public.org_role(organization_id) IN ('owner', 'admin', 'payroll_manager', 'auditor')
      OR user_id = public.current_user_id()
    )
  );

DROP POLICY IF EXISTS employees_write ON employees;
CREATE POLICY employees_write ON employees
  FOR ALL USING (public.org_role(organization_id) IN ('owner', 'admin', 'payroll_manager'))
  WITH CHECK (public.org_role(organization_id) IN ('owner', 'admin', 'payroll_manager'));

-- Gmail connections: solo el dueño (y admins de org pueden ver metadatos)
DROP POLICY IF EXISTS gmail_owner ON gmail_connections;
CREATE POLICY gmail_owner ON gmail_connections
  FOR ALL USING (
    user_id = public.current_user_id()
    OR public.org_role(organization_id) IN ('owner', 'admin')
  )
  WITH CHECK (user_id = public.current_user_id());

-- Payroll documents: empleado solo los suyos; managers todos de la org
DROP POLICY IF EXISTS payroll_select ON payroll_documents;
CREATE POLICY payroll_select ON payroll_documents
  FOR SELECT USING (
    public.is_org_member(organization_id)
    AND (
      owner_user_id = public.current_user_id()
      OR public.org_role(organization_id) IN ('owner', 'admin', 'payroll_manager', 'auditor')
    )
  );

DROP POLICY IF EXISTS payroll_insert ON payroll_documents;
CREATE POLICY payroll_insert ON payroll_documents
  FOR INSERT WITH CHECK (
    public.is_org_member(organization_id)
    AND owner_user_id = public.current_user_id()
  );

DROP POLICY IF EXISTS payroll_update ON payroll_documents;
CREATE POLICY payroll_update ON payroll_documents
  FOR UPDATE USING (
    owner_user_id = public.current_user_id()
    OR public.org_role(organization_id) IN ('owner', 'admin', 'payroll_manager')
  );

-- Hour entries
DROP POLICY IF EXISTS hours_select ON hour_entries;
CREATE POLICY hours_select ON hour_entries
  FOR SELECT USING (
    public.is_org_member(organization_id)
    AND (
      user_id = public.current_user_id()
      OR public.org_role(organization_id) IN ('owner', 'admin', 'payroll_manager', 'auditor')
    )
  );

DROP POLICY IF EXISTS hours_write ON hour_entries;
CREATE POLICY hours_write ON hour_entries
  FOR ALL USING (
    user_id = public.current_user_id()
    OR public.org_role(organization_id) IN ('owner', 'admin', 'payroll_manager')
  )
  WITH CHECK (
    user_id = public.current_user_id()
    OR public.org_role(organization_id) IN ('owner', 'admin', 'payroll_manager')
  );

-- Period balances
DROP POLICY IF EXISTS balances_select ON period_balances;
CREATE POLICY balances_select ON period_balances
  FOR SELECT USING (
    public.is_org_member(organization_id)
    AND (
      user_id = public.current_user_id()
      OR public.org_role(organization_id) IN ('owner', 'admin', 'payroll_manager', 'auditor')
    )
  );

-- Rules: lectura miembros; escritura admin/payroll
DROP POLICY IF EXISTS rules_select ON calculation_rule_sets;
CREATE POLICY rules_select ON calculation_rule_sets
  FOR SELECT USING (public.is_org_member(organization_id));

DROP POLICY IF EXISTS rules_write ON calculation_rule_sets;
CREATE POLICY rules_write ON calculation_rule_sets
  FOR INSERT WITH CHECK (public.org_role(organization_id) IN ('owner', 'admin', 'payroll_manager'));

-- Audit: solo roles privilegiados
DROP POLICY IF EXISTS audit_select ON audit_events;
CREATE POLICY audit_select ON audit_events
  FOR SELECT USING (public.org_role(organization_id) IN ('owner', 'admin', 'auditor'));

-- Subscriptions / entitlements
DROP POLICY IF EXISTS subs_select ON subscriptions;
CREATE POLICY subs_select ON subscriptions
  FOR SELECT USING (public.is_org_member(organization_id));

DROP POLICY IF EXISTS entitlements_select ON entitlements;
CREATE POLICY entitlements_select ON entitlements
  FOR SELECT USING (public.is_org_member(organization_id));

-- Sync events / jobs / extraction: miembros privilegiados o dueño del doc
DROP POLICY IF EXISTS sync_events_select ON gmail_sync_events;
CREATE POLICY sync_events_select ON gmail_sync_events
  FOR SELECT USING (
    public.org_role(organization_id) IN ('owner', 'admin', 'payroll_manager')
    OR EXISTS (
      SELECT 1 FROM gmail_connections c
      WHERE c.id = connection_id AND c.user_id = public.current_user_id()
    )
  );

DROP POLICY IF EXISTS jobs_select ON processing_jobs;
CREATE POLICY jobs_select ON processing_jobs
  FOR SELECT USING (
    public.org_role(organization_id) IN ('owner', 'admin', 'payroll_manager', 'auditor')
  );

DROP POLICY IF EXISTS extraction_select ON extraction_runs;
CREATE POLICY extraction_select ON extraction_runs
  FOR SELECT USING (
    public.is_org_member(organization_id)
    AND EXISTS (
      SELECT 1 FROM payroll_documents d
      WHERE d.id = document_id
        AND (
          d.owner_user_id = public.current_user_id()
          OR public.org_role(organization_id) IN ('owner', 'admin', 'payroll_manager', 'auditor')
        )
    )
  );

DROP POLICY IF EXISTS extracted_fields_select ON extracted_fields;
CREATE POLICY extracted_fields_select ON extracted_fields
  FOR SELECT USING (
    public.is_org_member(organization_id)
  );

DROP POLICY IF EXISTS pdf_secrets_owner ON pdf_secrets;
CREATE POLICY pdf_secrets_owner ON pdf_secrets
  FOR ALL USING (user_id = public.current_user_id())
  WITH CHECK (user_id = public.current_user_id());

DROP POLICY IF EXISTS invitations_admin ON invitations;
CREATE POLICY invitations_admin ON invitations
  FOR ALL USING (public.org_role(organization_id) IN ('owner', 'admin'))
  WITH CHECK (public.org_role(organization_id) IN ('owner', 'admin'));

DROP POLICY IF EXISTS consents_self ON consents;
CREATE POLICY consents_self ON consents
  FOR ALL USING (user_id = public.current_user_id())
  WITH CHECK (user_id = public.current_user_id());

DROP POLICY IF EXISTS doc_versions_select ON payroll_document_versions;
CREATE POLICY doc_versions_select ON payroll_document_versions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM payroll_documents d
      WHERE d.id = document_id
        AND public.is_org_member(d.organization_id)
        AND (
          d.owner_user_id = public.current_user_id()
          OR public.org_role(d.organization_id) IN ('owner', 'admin', 'payroll_manager', 'auditor')
        )
    )
  );
