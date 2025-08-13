CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END $$;

-- 2) table
CREATE TABLE users (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name  VARCHAR(40),
    last_name   VARCHAR(40),
    email       VARCHAR(120) NOT NULL,
    birth_date  DATE CHECK (birth_date <= current_date),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3) case-insensitive uniqueness for email
CREATE UNIQUE INDEX ux_users_email_lower ON users ((lower(email)));

-- 4) updated_at auto-maintenance
CREATE TRIGGER trg_users_updated
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION set_updated_at();
ALTER TABLE users
ADD CONSTRAINT chk_users_email_format
CHECK (email ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$');

-- one-time helper if not already created
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END $$;

-- PORTFOLIOS
CREATE TABLE portfolios (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    description TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX ux_portfolios_name_lower ON portfolios ((lower(name)));
CREATE TRIGGER trg_portfolios_updated
BEFORE UPDATE ON portfolios
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- CATEGORIES
CREATE TABLE categories (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR(50) NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX ux_categories_name_lower ON categories ((lower(name)));
CREATE TRIGGER trg_categories_updated
BEFORE UPDATE ON categories
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- TLDS  (store without the leading dot, e.g., 'com', 'io')
CREATE TABLE tlds (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR(50) NOT NULL,  -- 'com', 'io'
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_tlds_name_format CHECK (name ~* '^[a-z0-9-]+$')
);
CREATE UNIQUE INDEX ux_tlds_name_lower ON tlds ((lower(name)));
CREATE TRIGGER trg_tlds_updated
BEFORE UPDATE ON tlds
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- DOMAINS
CREATE TABLE domains (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name          VARCHAR(255) NOT NULL,             -- e.g., example.com (punycode)
    owner_id      BIGINT REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL,
    portfolio_id  BIGINT REFERENCES portfolios(id) ON UPDATE CASCADE ON DELETE SET NULL,
    category_id   BIGINT REFERENCES categories(id) ON UPDATE CASCADE ON DELETE SET NULL,
    tld_id        BIGINT REFERENCES tlds(id) ON UPDATE CASCADE ON DELETE SET NULL,
    registrar     VARCHAR(120),                      -- consider normalizing later
    price_usd     NUMERIC(12,2),
    status        VARCHAR(32) NOT NULL DEFAULT 'available',
    listing_url   VARCHAR(255),
    logo_url      VARCHAR(255),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    -- basic invariants
    CONSTRAINT chk_domains_name_format CHECK (name ~* '^[a-z0-9-]+(\.[a-z0-9-]+)+$'),
    CONSTRAINT chk_domains_status CHECK (status IN ('available','listed','sold','parked','pending'))
);
-- case-insensitive uniqueness & fast lookup
CREATE UNIQUE INDEX ux_domains_name_lower ON domains ((lower(name)));
CREATE INDEX ix_domains_owner       ON domains (owner_id);
CREATE INDEX ix_domains_portfolio   ON domains (portfolio_id);
CREATE INDEX ix_domains_category    ON domains (category_id);
CREATE INDEX ix_domains_tld         ON domains (tld_id);
CREATE INDEX ix_domains_status      ON domains (status);
CREATE TRIGGER trg_domains_updated
BEFORE UPDATE ON domains
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- TAGS
CREATE TABLE tags (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tag         VARCHAR(50) NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX ux_tags_tag_lower ON tags ((lower(tag)));
CREATE TRIGGER trg_tags_updated
BEFORE UPDATE ON tags
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- DOMAIN <-> TAGS
CREATE TABLE domain_tags (
    domain_id   BIGINT NOT NULL REFERENCES domains(id) ON UPDATE CASCADE ON DELETE CASCADE,
    tag_id      BIGINT NOT NULL REFERENCES tags(id)    ON UPDATE CASCADE ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (domain_id, tag_id)
);

INSERT INTO categories (name) VALUES
('Brandable'), ('Tech'), ('Finance'), ('Health'),
('Real Estate'), ('Crypto'), ('AI'), ('E-commerce')
ON CONFLICT ((lower(name))) DO NOTHING;

INSERT INTO tlds (name) VALUES
('com'), ('net'), ('org'), ('io'), ('ai'), ('de'), ('uk')
ON CONFLICT ((lower(name))) DO NOTHING;

CREATE OR REPLACE VIEW domain_full_view AS
SELECT
    d.id,
    d.name,
    COALESCE(NULLIF(TRIM(CONCAT_WS(' ', u.first_name, u.last_name)), ''), NULL) AS owner,
    p.name AS portfolio,
    c.name AS category,
    CASE WHEN t.name IS NOT NULL THEN '.' || t.name ELSE NULL END AS tld,
    d.registrar,
    d.price_usd,
    d.status,
    d.listing_url,
    d.logo_url,
    d.created_at,
    d.updated_at
FROM domains d
LEFT JOIN users u       ON d.owner_id     = u.id
LEFT JOIN portfolios p  ON d.portfolio_id = p.id
LEFT JOIN categories c  ON d.category_id  = c.id
LEFT JOIN tlds t        ON d.tld_id       = t.id;

CREATE OR REPLACE VIEW user_domains_view AS
SELECT
    u.id,
    u.first_name,
    u.last_name,
    CONCAT_WS(' ', u.first_name, u.last_name) AS full_name,
    COUNT(d.id) AS domains_count
FROM users u
LEFT JOIN domains d ON u.id = d.owner_id
GROUP BY u.id, u.first_name, u.last_name;
CREATE TABLE membership_plans (
    plan_id     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    plan_name   VARCHAR(100) NOT NULL,
    description TEXT,
    price       NUMERIC(12,2) NOT NULL CHECK (price >= 0),
    duration    INTERVAL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX ux_membership_plans_name_lower
  ON membership_plans ((lower(plan_name)));

CREATE TRIGGER trg_membership_plans_updated
BEFORE UPDATE ON membership_plans
FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TYPE payment_status AS ENUM ('active', 'expired', 'failed', 'pending');

CREATE TABLE customers (
    customer_id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name               VARCHAR(255) NOT NULL,
    email              VARCHAR(255),
    phone              VARCHAR(32),
    address            TEXT,
    plan_id            BIGINT REFERENCES membership_plans(plan_id)
                           ON UPDATE CASCADE ON DELETE SET NULL,
    subscription_start DATE,
    subscription_end   DATE,
    payment_status     payment_status NOT NULL DEFAULT 'pending',
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_subscription_range
      CHECK (subscription_end IS NULL OR subscription_start IS NULL
             OR subscription_end >= subscription_start)
);
-- case-insensitive uniqueness for email (make email NOT NULL first if you want strict uniqueness)
CREATE UNIQUE INDEX IF NOT EXISTS ux_customers_email_lower
  ON customers ((lower(email))) WHERE email IS NOT NULL;
CREATE INDEX ix_customers_plan_id       ON customers (plan_id);
CREATE INDEX ix_customers_payment_status ON customers (payment_status);

CREATE TRIGGER trg_customers_updated
BEFORE UPDATE ON customers
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE payments (
    payment_id     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id    BIGINT NOT NULL REFERENCES customers(customer_id)
                      ON UPDATE CASCADE ON DELETE CASCADE,
    payment_type   VARCHAR(50),                 -- e.g., 'card','paypal'
    provider_token TEXT,                        -- token/intent id (sensitive)
    amount         NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
    currency       CHAR(3) NOT NULL DEFAULT 'USD',
    expiration_date DATE,                       -- if applicable (e.g., card token)
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_payments_customer_id ON payments (customer_id);
CREATE INDEX ix_payments_created_at  ON payments (created_at);

CREATE TABLE login_credentials (
    credential_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id        BIGINT UNIQUE NOT NULL
                           REFERENCES customers(customer_id)
                           ON UPDATE CASCADE ON DELETE CASCADE,
    username           VARCHAR(50) NOT NULL,
    password_hash      TEXT NOT NULL,
    password_updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- case-insensitive uniqueness for username
CREATE UNIQUE INDEX ux_login_username_lower
  ON login_credentials ((lower(username)));

CREATE TRIGGER trg_login_credentials_updated
BEFORE UPDATE ON login_credentials
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

------------------------------------------------------here

CREATE OR REPLACE VIEW customer_profile AS
SELECT 
    c.customer_id,
    c.name,
    c.email,
    c.address,
    mp.plan_name,
    mp.price,
    c.subscription_start,
    c.subscription_end
FROM customers c
LEFT JOIN membership_plans mp ON c.plan_id = mp.plan_id;
CREATE TABLE roles (
    role_id     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    role_name   VARCHAR(100) NOT NULL,
    description TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX ux_roles_name_lower ON roles ((lower(role_name)));
CREATE TRIGGER trg_roles_updated
BEFORE UPDATE ON roles
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

ALTER TABLE customers
  ADD COLUMN role_id BIGINT REFERENCES roles(role_id)
      ON UPDATE CASCADE ON DELETE SET NULL;

CREATE INDEX ix_customers_role_id ON customers(role_id);
CREATE TABLE staff_roles (
    role_id     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    role_name   VARCHAR(100) NOT NULL,
    description TEXT,
    permissions JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX ux_staff_roles_name_lower ON staff_roles ((lower(role_name)));
CREATE INDEX ix_staff_roles_permissions_gin ON staff_roles USING GIN (permissions);
CREATE TRIGGER trg_staff_roles_updated
BEFORE UPDATE ON staff_roles
FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TABLE staff (
    staff_id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR(255) NOT NULL,
    role_id     BIGINT REFERENCES staff_roles(role_id)
                   ON UPDATE CASCADE ON DELETE SET NULL,
    email       VARCHAR(255),
    phone       VARCHAR(32),
    address     TEXT,
    hire_date   DATE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- optional email uniqueness if you want: NOT NULL first for strict uniqueness
CREATE UNIQUE INDEX ux_staff_email_lower
  ON staff ((lower(email))) WHERE email IS NOT NULL;
CREATE INDEX ix_staff_role_id ON staff(role_id);

CREATE TRIGGER trg_staff_updated
BEFORE UPDATE ON staff
FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TABLE staff_login_credentials (
    credential_id       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    staff_id            BIGINT UNIQUE NOT NULL
                           REFERENCES staff(staff_id)
                           ON UPDATE CASCADE ON DELETE CASCADE,
    username            VARCHAR(50) NOT NULL,
    password_hash       TEXT NOT NULL,
    password_updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX ux_staff_login_username_lower
  ON staff_login_credentials ((lower(username)));

CREATE TRIGGER trg_staff_login_credentials_updated
BEFORE UPDATE ON staff_login_credentials
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

----------------------------------------------------------------------HERE

CREATE OR REPLACE VIEW customer_dashboard AS
SELECT 
    c.customer_id,
    c.name,
    c.email,
    c.phone,
    c.address,
    mp.plan_name,
    mp.price,
    c.subscription_start,
    c.subscription_end,
    c.payment_status,
    p_latest.payment_type,
    p_latest.expiration_date,
    r.role_name AS customer_role
FROM customers c
LEFT JOIN membership_plans mp ON c.plan_id = mp.plan_id
LEFT JOIN roles r             ON c.role_id = r.role_id
LEFT JOIN LATERAL (
    SELECT p.payment_type, p.expiration_date
    FROM payments p
    WHERE p.customer_id = c.customer_id
    ORDER BY p.created_at DESC, p.payment_id DESC
    LIMIT 1
) AS p_latest ON true;

-----------------------------------------------------------------HERE

CREATE TABLE registrars (
  registrar_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name         TEXT NOT NULL,
  api_key_id   BIGINT,  -- optional: reference secrets table later
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX ux_registrars_name_lower ON registrars ((lower(name)));

CREATE TRIGGER trg_registrars_updated
BEFORE UPDATE ON registrars
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE registrar_accounts (
  id                 BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_id        BIGINT NOT NULL REFERENCES customers(customer_id)
                        ON UPDATE CASCADE ON DELETE CASCADE,
  registrar_id       BIGINT NOT NULL REFERENCES registrars(registrar_id)
                        ON UPDATE CASCADE ON DELETE RESTRICT,
  external_username  TEXT NOT NULL,
  external_account_id TEXT,
  verified           BOOLEAN NOT NULL DEFAULT FALSE,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (customer_id, registrar_id)
);
-- Prevent duplicate usernames per registrar (case-insensitive)
CREATE UNIQUE INDEX ux_regacct_reg_user_lower
  ON registrar_accounts (registrar_id, lower(external_username));

CREATE INDEX ix_regacct_customer ON registrar_accounts (customer_id);
CREATE TRIGGER trg_registrar_accounts_updated
BEFORE UPDATE ON registrar_accounts
FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TYPE order_status AS ENUM
('pending','paid','provisioning','fulfilled','failed','canceled','refunded');

CREATE TABLE orders (
  order_id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_id BIGINT NOT NULL REFERENCES customers(customer_id)
                ON UPDATE CASCADE ON DELETE RESTRICT,
  status      order_status NOT NULL DEFAULT 'pending',
  currency    CHAR(3) NOT NULL DEFAULT 'USD',
  subtotal    NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (subtotal >= 0),
  fees        NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (fees >= 0),
  tax         NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (tax >= 0),
  total       NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (total >= 0),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_orders_customer   ON orders (customer_id);
CREATE INDEX ix_orders_status     ON orders (status);
CREATE INDEX ix_orders_created_at ON orders (created_at);

CREATE TRIGGER trg_orders_updated
BEFORE UPDATE ON orders
FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TYPE order_item_type AS ENUM
('domain_registration','domain_transfer','renewal','ssl','hosting','private_email','premium_dns','service_fee');

CREATE TABLE order_items (
  order_item_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  order_id      BIGINT NOT NULL REFERENCES orders(order_id)
                   ON UPDATE CASCADE ON DELETE CASCADE,
  item_type     order_item_type NOT NULL,
  sku           TEXT,
  description   TEXT,
  quantity      INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
  unit_price    NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0),
  amount        NUMERIC(12,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
  meta          JSONB NOT NULL DEFAULT '{}'::jsonb
);
CREATE INDEX ix_order_items_order_id ON order_items (order_id);
CREATE INDEX ix_order_items_item_type ON order_items (item_type);
CREATE INDEX ix_order_items_meta_gin ON order_items USING GIN (meta);
CREATE TYPE payment_method AS ENUM
('paypal','card','stripe','flutterwave','paystack','opay','palmpay','btc','usdt','bank_transfer','other');

CREATE TYPE payment_state AS ENUM
('initiated','authorized','captured','failed','refunded','chargeback');

CREATE TABLE order_payments (
  payment_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  order_id     BIGINT NOT NULL REFERENCES orders(order_id)
                  ON UPDATE CASCADE ON DELETE CASCADE,
  method       payment_method NOT NULL,
  provider_ref TEXT,
  amount       NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
  currency     CHAR(3) NOT NULL DEFAULT 'USD',
  state        payment_state NOT NULL,
  received_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  raw_response JSONB
);
CREATE INDEX ix_order_payments_order_id ON order_payments (order_id);
CREATE INDEX ix_order_payments_state    ON order_payments (state);
CREATE INDEX ix_order_payments_method   ON order_payments (method);
CREATE INDEX ix_order_payments_received ON order_payments (received_at);
CREATE TYPE domain_event AS ENUM
('created','assigned','pushed','transferred_in','transferred_out','renewed','dns_changed','status_changed','sold');

CREATE TABLE domain_history (
  id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  domain_id    BIGINT NOT NULL REFERENCES domains(id)
                  ON UPDATE CASCADE ON DELETE CASCADE,
  customer_id  BIGINT REFERENCES customers(customer_id)
                  ON UPDATE CASCADE ON DELETE SET NULL,
  registrar_id BIGINT REFERENCES registrars(registrar_id)
                  ON UPDATE CASCADE ON DELETE SET NULL,
  event        domain_event NOT NULL,
  details      JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_domain_history_domain     ON domain_history (domain_id);
CREATE INDEX ix_domain_history_event      ON domain_history (event);
CREATE INDEX ix_domain_history_created_at ON domain_history (created_at);
CREATE INDEX ix_domain_history_details_gin ON domain_history USING GIN (details);

-----------------------------------------------------------------------

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = current_schema()
      AND table_name = 'staff_roles'
      AND column_name = 'permissions'
      AND data_type = 'text'
  ) THEN
    ALTER TABLE staff_roles
      ADD COLUMN permissions_tmp JSONB NOT NULL DEFAULT '{}'::jsonb;

    UPDATE staff_roles
    SET permissions_tmp = CASE
      WHEN permissions IS NULL OR trim(permissions) = '' THEN '{}'::jsonb
      WHEN permissions ~ '^\s*\{.*\}\s*$' THEN permissions::jsonb
      ELSE jsonb_build_object('note', permissions)
    END;

    ALTER TABLE staff_roles DROP COLUMN permissions;
    ALTER TABLE staff_roles RENAME COLUMN permissions_tmp TO permissions;

    ALTER TABLE staff_roles
      ALTER COLUMN permissions SET DEFAULT '{}'::jsonb;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS ix_staff_roles_permissions_gin
  ON staff_roles USING gin (permissions);

CREATE UNIQUE INDEX IF NOT EXISTS ux_staff_roles_name_lower
  ON staff_roles ((lower(role_name)));

ALTER TABLE staff_roles
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

DROP TRIGGER IF EXISTS trg_staff_roles_updated ON staff_roles;
CREATE TRIGGER trg_staff_roles_updated
BEFORE UPDATE ON staff_roles
FOR EACH ROW EXECUTE FUNCTION set_updated_at();
--------------------
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = current_schema() AND table_name='staff_roles';

SELECT indexname, indexdef
FROM pg_indexes
WHERE schemaname = current_schema() AND tablename='staff_roles';

SELECT tgname
FROM pg_trigger
WHERE tgrelid = 'staff_roles'::regclass;

-----------------------------------------Here last
-- (A) Make staff field explicit (rename old owner_id → steward_user_id)
ALTER TABLE domains RENAME COLUMN owner_id TO steward_user_id;

-- (B) Add current customer owner + invariant
ALTER TABLE domains
  ADD COLUMN IF NOT EXISTS current_owner_customer_id BIGINT
    REFERENCES customers(customer_id) ON UPDATE CASCADE ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS company_owned BOOLEAN NOT NULL DEFAULT TRUE;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='chk_domains_ownership_consistency') THEN
    ALTER TABLE domains
      ADD CONSTRAINT chk_domains_ownership_consistency
      CHECK (
        (company_owned = TRUE  AND current_owner_customer_id IS NULL) OR
        (company_owned = FALSE AND current_owner_customer_id IS NOT NULL)
      );
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS ix_domains_owner_customer
  ON domains (current_owner_customer_id);
CREATE INDEX IF NOT EXISTS ix_domains_company_owned
  ON domains (company_owned);

--------------------------------------------------here most
-- domains should point to the registrar account used for management
ALTER TABLE domains
  ADD COLUMN IF NOT EXISTS registrar_account_id BIGINT
    REFERENCES registrar_accounts(id)
    ON UPDATE CASCADE ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS ix_domains_registrar_account
  ON domains (registrar_account_id);


-- optional (if you want to mark company-owned registrar accounts)
ALTER TABLE registrar_accounts
  ADD COLUMN IF NOT EXISTS is_company BOOLEAN NOT NULL DEFAULT FALSE;

-----------------------------------------------------------here

-- Force canonical lowercase ASCII in `name` (store punycode here)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='chk_domains_name_ascii_lower') THEN
    ALTER TABLE domains
      ADD CONSTRAINT chk_domains_name_ascii_lower
      CHECK (name = lower(name) AND name ~ '^[\x00-\x7F]+$');
  END IF;
END $$;

-- Optional display name for UI (may contain Unicode)
ALTER TABLE domains
  ADD COLUMN IF NOT EXISTS name_display TEXT;

  ------------------------
  DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname='domain_status') THEN
    CREATE TYPE domain_status AS ENUM ('available','listed','sold','parked','pending');
  END IF;
END $$;

ALTER TABLE domains
  ADD COLUMN IF NOT EXISTS status_enum domain_status;

UPDATE domains SET status_enum = status::domain_status
WHERE status_enum IS NULL;  -- migrate data

ALTER TABLE domains
  ALTER COLUMN status_enum SET DEFAULT 'available',
  ALTER COLUMN status_enum SET NOT NULL;

-- (after app update)
-- ALTER TABLE domains DROP COLUMN status;
-- CREATE INDEX IF NOT EXISTS ix_domains_status_enum ON domains (status_enum);
-- 1) Backfill country_code for existing 2-letter TLDs
-- 1) Add the column
ALTER TABLE tlds
  ADD COLUMN IF NOT EXISTS country_code CHAR(2);

-- 2) Backfill country_code for existing 2-letter TLDs
UPDATE tlds
SET country_code = upper(name)
WHERE length(name) = 2 AND country_code IS NULL;

-- ISO quirk: .uk uses GB as the ISO alpha-2 code
UPDATE tlds
SET country_code = 'GB'
WHERE lower(name) = 'uk';

-- 3) Add constraints (safe to re-run)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='chk_tlds_cc_format') THEN
    ALTER TABLE tlds
      ADD CONSTRAINT chk_tlds_cc_format
      CHECK (country_code IS NULL OR country_code ~ '^[A-Z]{2}$');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='chk_tlds_cc_logic') THEN
    ALTER TABLE tlds
      ADD CONSTRAINT chk_tlds_cc_logic
      CHECK (
        (length(name) = 2 AND country_code IS NOT NULL)
        OR (length(name) <> 2)
      );
  END IF;
END $$;

-- 4) Quick sanity check
SELECT id, name, country_code FROM tlds ORDER BY name;



------------------------
ALTER TABLE domains
  ADD COLUMN IF NOT EXISTS expires_at  TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS auto_renew  BOOLEAN   NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS lock_status BOOLEAN   NOT NULL DEFAULT TRUE,  -- registrar lock
  ADD COLUMN IF NOT EXISTS auth_code   TEXT,
  ADD COLUMN IF NOT EXISTS nameservers TEXT[];   -- ['ns1.example','ns2.example']

CREATE INDEX IF NOT EXISTS ix_domains_expires_at ON domains (expires_at);

------------------
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='chk_login_username_len') THEN
    ALTER TABLE login_credentials
      ADD CONSTRAINT chk_login_username_len CHECK (length(username) >= 3);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='chk_login_hash_prefix') THEN
    ALTER TABLE login_credentials
      ADD CONSTRAINT chk_login_hash_prefix
      CHECK (password_hash ~ '^\$(2[aby]|argon2|pbkdf2)');
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='chk_staff_login_username_len') THEN
    ALTER TABLE staff_login_credentials
      ADD CONSTRAINT chk_staff_login_username_len CHECK (length(username) >= 3);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='chk_staff_login_hash_prefix') THEN
    ALTER TABLE staff_login_credentials
      ADD CONSTRAINT chk_staff_login_hash_prefix
      CHECK (password_hash ~ '^\$(2[aby]|argon2|pbkdf2)');
  END IF;
END $$;

-------------------------------
CREATE TABLE listings (
  listing_id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  domain_id           BIGINT NOT NULL REFERENCES domains(id) ON DELETE CASCADE,
  seller_customer_id  BIGINT REFERENCES customers(customer_id) ON DELETE SET NULL,
  price               NUMERIC(12,2) CHECK (price >= 0),
  marketplace         TEXT,                  -- 'sedo','dan','afternic','custom'
  status              TEXT NOT NULL DEFAULT 'active',
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_listings_domain ON listings(domain_id);

CREATE TABLE leads (
  lead_id     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  domain_id   BIGINT REFERENCES domains(id) ON DELETE SET NULL,
  contact_name  TEXT,
  contact_email TEXT,
  message       TEXT,
  source        TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE offers (
  offer_id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  domain_id          BIGINT NOT NULL REFERENCES domains(id) ON DELETE CASCADE,
  buyer_customer_id  BIGINT REFERENCES customers(customer_id) ON DELETE SET NULL,
  amount             NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
  currency           CHAR(3) NOT NULL DEFAULT 'USD',
  status             TEXT NOT NULL DEFAULT 'open',
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE escrows (
  escrow_id  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  order_id   BIGINT REFERENCES orders(order_id) ON DELETE SET NULL,
  provider   TEXT,
  status     TEXT,
  fee        NUMERIC(12,2) CHECK (fee >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE commissions (
  commission_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  order_id           BIGINT REFERENCES orders(order_id) ON DELETE CASCADE,
  percent            NUMERIC(5,2) CHECK (percent >= 0),
  amount             NUMERIC(12,2) CHECK (amount >= 0),
  recipient_staff_id BIGINT REFERENCES staff(staff_id) ON DELETE SET NULL
);

---------------------
ALTER TABLE payments RENAME TO customer_payment_methods;

ALTER TABLE customer_payment_methods
  DROP COLUMN IF EXISTS amount,
  DROP COLUMN IF EXISTS currency,
  DROP COLUMN IF EXISTS expiration_date;

ALTER TABLE customer_payment_methods
  ADD COLUMN IF NOT EXISTS provider TEXT,          -- 'stripe','paypal',...
  ADD COLUMN IF NOT EXISTS token_last4 TEXT,
  ADD COLUMN IF NOT EXISTS active BOOLEAN NOT NULL DEFAULT TRUE;
----------------------
-- Redefine the view but KEEP the old column types/names
-- rename only (names change, types stay the same)
ALTER VIEW customer_dashboard RENAME COLUMN payment_type    TO last_payment_method;
ALTER VIEW customer_dashboard RENAME COLUMN expiration_date TO last_payment_at;

-- keep existing column names & types
CREATE OR REPLACE VIEW customer_dashboard AS
SELECT 
    c.customer_id,
    c.name,
    c.email,
    c.phone,
    c.address,
    mp.plan_name,
    mp.price,
    c.subscription_start,
    c.subscription_end,
    c.payment_status,
    (op_latest.method)::varchar(50) AS last_payment_method,  -- stays varchar(50)
    (op_latest.received_at)::date   AS last_payment_at,       -- stays date
    r.role_name                     AS customer_role
FROM customers c
LEFT JOIN membership_plans mp ON c.plan_id = mp.plan_id
LEFT JOIN roles r             ON c.role_id = r.role_id
LEFT JOIN LATERAL (
    SELECT op.method, op.state, op.received_at, op.payment_id
    FROM orders o
    JOIN order_payments op ON op.order_id = o.order_id
    WHERE o.customer_id = c.customer_id
    ORDER BY op.received_at DESC, op.payment_id DESC
    LIMIT 1
) op_latest ON true;

ALTER TABLE payments
  DROP COLUMN IF EXISTS amount,
  DROP COLUMN IF EXISTS currency,
  DROP COLUMN IF EXISTS expiration_date;

ALTER TABLE payments
  ADD COLUMN IF NOT EXISTS provider    TEXT,
  ADD COLUMN IF NOT EXISTS token_last4 TEXT,
  ADD COLUMN IF NOT EXISTS active      BOOLEAN NOT NULL DEFAULT TRUE;

CREATE INDEX IF NOT EXISTS ix_cpm_customer ON payments (customer_id);
CREATE INDEX IF NOT EXISTS ix_cpm_customer_active
  ON payments (customer_id) WHERE active;

  ALTER TABLE payments RENAME TO customer_payment_methods;

ALTER TABLE domains
  ADD COLUMN IF NOT EXISTS expires_at  TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS auto_renew  BOOLEAN   NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS lock_status BOOLEAN   NOT NULL DEFAULT TRUE,  -- registrar lock
  ADD COLUMN IF NOT EXISTS auth_code   TEXT,
  ADD COLUMN IF NOT EXISTS nameservers TEXT[];   -- ['ns1.example','ns2.example']

CREATE INDEX IF NOT EXISTS ix_domains_expires_at ON domains (expires_at);

CREATE OR REPLACE VIEW domain_full_view AS
SELECT
  d.id,
  d.name,
  -- keep owner as TEXT (old view produced text via concatenation)
  (CASE WHEN d.company_owned = FALSE THEN c.name ELSE NULL END)::text AS owner,
  p.name                 AS portfolio,            -- varchar(100)
  ccat.name              AS category,             -- varchar(50)
  -- keep tld as TEXT (old view used '.' || t.name which yields text)
  CASE WHEN t.name IS NOT NULL THEN '.' || t.name ELSE NULL END AS tld,
  -- keep registrar as varchar(120) (old view had d.registrar varchar)
  reg.name::varchar(120) AS registrar,
  d.price_usd,
  -- keep status as varchar(32) (old view had d.status varchar)
  COALESCE(d.status_enum::text, d.status)::varchar(32) AS status,
  d.listing_url,
  d.logo_url,
  d.created_at,
  d.updated_at
FROM domains d
LEFT JOIN customers        c    ON d.current_owner_customer_id = c.customer_id
LEFT JOIN portfolios       p    ON d.portfolio_id = p.id
LEFT JOIN categories       ccat ON d.category_id  = ccat.id
LEFT JOIN tlds             t    ON d.tld_id       = t.id
LEFT JOIN registrar_accounts ra ON d.registrar_account_id = ra.id
LEFT JOIN registrars       reg  ON ra.registrar_id = reg.registrar_id;

SELECT column_name, data_type FROM information_schema.columns
WHERE table_name='domains' AND column_name IN
('steward_user_id','current_owner_customer_id','company_owned','registrar_account_id',
 'expires_at','auto_renew','lock_status','auth_code','nameservers','status_enum');

-- Views compile?
SELECT 1 FROM domain_full_view LIMIT 1;
SELECT 1 FROM customer_dashboard LIMIT 1;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name='domains' AND column_name='owner_id'
  ) THEN
    EXECUTE 'ALTER TABLE domains RENAME COLUMN owner_id TO steward_user_id';
  END IF;
END $$;

ALTER TABLE domains
  ADD COLUMN IF NOT EXISTS current_owner_customer_id BIGINT
    REFERENCES customers(customer_id) ON UPDATE CASCADE ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS company_owned BOOLEAN NOT NULL DEFAULT TRUE;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='chk_domains_ownership_consistency'
  ) THEN
    ALTER TABLE domains
      ADD CONSTRAINT chk_domains_ownership_consistency
      CHECK (
        (company_owned = TRUE  AND current_owner_customer_id IS NULL) OR
        (company_owned = FALSE AND current_owner_customer_id IS NOT NULL)
      );
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS ix_domains_owner_customer
  ON domains (current_owner_customer_id);
CREATE INDEX IF NOT EXISTS ix_domains_company_owned
  ON domains (company_owned);

-- ===========================================
-- 2) DOMAINS: REGISTRAR ACCOUNT FK
-- ===========================================
ALTER TABLE domains
  ADD COLUMN IF NOT EXISTS registrar_account_id BIGINT
    REFERENCES registrar_accounts(id)
    ON UPDATE CASCADE ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS ix_domains_registrar_account
  ON domains (registrar_account_id);

-- ===========================================
-- 3) DOMAINS: EXPIRY / RENEWAL / LOCK / AUTH / NS
-- ===========================================
ALTER TABLE domains
  ADD COLUMN IF NOT EXISTS expires_at  TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS auto_renew  BOOLEAN   NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS lock_status BOOLEAN   NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS auth_code   TEXT,
  ADD COLUMN IF NOT EXISTS nameservers TEXT[];

CREATE INDEX IF NOT EXISTS ix_domains_expires_at ON domains (expires_at);

-- ===========================================
-- 4) (NICE) STATUS ENUM (migrate, keep old status column for now)
-- ===========================================
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname='domain_status') THEN
    CREATE TYPE domain_status AS ENUM ('available','listed','sold','parked','pending');
  END IF;
END $$;

ALTER TABLE domains
  ADD COLUMN IF NOT EXISTS status_enum domain_status;

-- migrate only where possible; ignore invalids
UPDATE domains d
SET status_enum = d.status::domain_status
WHERE d.status_enum IS NULL
  AND d.status IN ('available','listed','sold','parked','pending');

ALTER TABLE domains
  ALTER COLUMN status_enum SET DEFAULT 'available';

-- Optional index (keep old ix_domains_status if you still read text)
CREATE INDEX IF NOT EXISTS ix_domains_status_enum ON domains (status_enum);

-- ===========================================
-- 5) (NICE) IDN CANONICALIZATION + DISPLAY NAME
--      - store punycode + lowercase in domains.name
--      - keep UI form in domains.name_display
-- ===========================================
ALTER TABLE domains
  ADD COLUMN IF NOT EXISTS name_display TEXT;

-- Enforce lowercase ASCII (punycode) without breaking existing data:
-- If you want hard enforcement now, uncomment the CHECK; else add later after data cleanup.
-- DO $$ BEGIN
--   IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='chk_domains_name_ascii_lower') THEN
--     ALTER TABLE domains
--       ADD CONSTRAINT chk_domains_name_ascii_lower
--       CHECK (name = lower(name) AND name ~ '^[\x00-\x7F]+$');
--   END IF;
-- END $$;

-- ===========================================
-- 6) (NICE) TLD country_code (if not already done)
-- ===========================================
ALTER TABLE tlds
  ADD COLUMN IF NOT EXISTS country_code CHAR(2);

-- backfill for 2-letter TLDs missing cc
UPDATE tlds SET country_code = upper(name)
WHERE length(name)=2 AND country_code IS NULL;

-- ISO quirk: .uk uses GB
UPDATE tlds SET country_code = 'GB' WHERE lower(name)='uk';

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='chk_tlds_cc_format') THEN
    ALTER TABLE tlds
      ADD CONSTRAINT chk_tlds_cc_format
      CHECK (country_code IS NULL OR country_code ~ '^[A-Z]{2}$');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='chk_tlds_cc_logic') THEN
    ALTER TABLE tlds
      ADD CONSTRAINT chk_tlds_cc_logic
      CHECK (
        (length(name) = 2 AND country_code IS NOT NULL)
        OR (length(name) <> 2)
      );
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS listings (
  listing_id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  domain_id           BIGINT NOT NULL REFERENCES domains(id) ON UPDATE CASCADE ON DELETE CASCADE,
  seller_customer_id  BIGINT REFERENCES customers(customer_id) ON UPDATE CASCADE ON DELETE SET NULL,
  price               NUMERIC(12,2) CHECK (price >= 0),
  marketplace         TEXT,                  -- 'sedo','dan','afternic','custom'
  status              TEXT NOT NULL DEFAULT 'active',
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_listings_domain   ON listings(domain_id);
CREATE INDEX IF NOT EXISTS ix_listings_status   ON listings(status);
DROP TRIGGER IF EXISTS trg_listings_updated ON listings;
CREATE TRIGGER trg_listings_updated
BEFORE UPDATE ON listings
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE IF NOT EXISTS leads (
  lead_id       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  domain_id     BIGINT REFERENCES domains(id) ON UPDATE CASCADE ON DELETE SET NULL,
  contact_name  TEXT,
  contact_email TEXT,
  message       TEXT,
  source        TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_leads_domain ON leads(domain_id);

CREATE TABLE IF NOT EXISTS offers (
  offer_id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  domain_id          BIGINT NOT NULL REFERENCES domains(id) ON UPDATE CASCADE ON DELETE CASCADE,
  buyer_customer_id  BIGINT REFERENCES customers(customer_id) ON UPDATE CASCADE ON DELETE SET NULL,
  amount             NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
  currency           CHAR(3) NOT NULL DEFAULT 'USD',
  status             TEXT NOT NULL DEFAULT 'open',
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_offers_domain ON offers(domain_id);
DROP TRIGGER IF EXISTS trg_offers_updated ON offers;
CREATE TRIGGER trg_offers_updated
BEFORE UPDATE ON offers
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE IF NOT EXISTS escrows (
  escrow_id  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  order_id   BIGINT REFERENCES orders(order_id) ON UPDATE CASCADE ON DELETE SET NULL,
  provider   TEXT,
  status     TEXT,
  fee        NUMERIC(12,2) CHECK (fee >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS commissions (
  commission_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  order_id           BIGINT REFERENCES orders(order_id) ON UPDATE CASCADE ON DELETE CASCADE,
  percent            NUMERIC(5,2) CHECK (percent >= 0),
  amount             NUMERIC(12,2) CHECK (amount >= 0),
  recipient_staff_id BIGINT REFERENCES staff(staff_id) ON UPDATE CASCADE ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS ix_commissions_order ON commissions(order_id);

ALTER TABLE domains DROP COLUMN IF EXISTS registrar;

CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX IF NOT EXISTS ix_domains_name_trgm
  ON domains USING GIN (name gin_trgm_ops);

  -- domains ownership fields present?
SELECT column_name, data_type FROM information_schema.columns
WHERE table_name='domains' AND column_name IN
('steward_user_id','current_owner_customer_id','company_owned',
 'registrar_account_id','expires_at','auto_renew','lock_status',
 'auth_code','nameservers','status_enum');

-- views compile?
SELECT 1 FROM domain_full_view        LIMIT 1;
SELECT 1 FROM customer_dashboard      LIMIT 1;


