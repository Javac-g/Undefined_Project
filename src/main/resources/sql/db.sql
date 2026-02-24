-- ============================================
-- Pines Digital — Domains Broker (PostgreSQL)
-- Mapping from Books/Authors schema
-- ============================================

-- USERS (replaces authors)
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(40),
    last_name  VARCHAR(40),
    email      VARCHAR(120) UNIQUE,
    birth_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- PORTFOLIOS (replaces groups_list)
CREATE TABLE portfolios (
    id   SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT
);

-- CATEGORIES (replaces genres)
CREATE TABLE categories (
    id   SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL
);

-- TLDS (replaces languages)
CREATE TABLE tlds (
    id       SERIAL PRIMARY KEY,
    name     VARCHAR(50) UNIQUE NOT NULL, -- e.g., .com, .io
    iso_code CHAR(2)                      -- optional 2-char code
);

-- DOMAINS (replaces books)
CREATE TABLE domains (
    id           SERIAL PRIMARY KEY,
    name         VARCHAR(255) UNIQUE NOT NULL,  -- e.g., example.com
    owner_id     INTEGER REFERENCES users(id),
    portfolio_id INTEGER REFERENCES portfolios(id),
    category_id  INTEGER REFERENCES categories(id),
    tld_id       INTEGER REFERENCES tlds(id),
    registrar    VARCHAR(120),
    price_usd    DECIMAL(12,2),
    status       VARCHAR(32) DEFAULT 'available', -- available|listed|sold|parked|pending
    listing_url  VARCHAR(255),
    logo_url     VARCHAR(255),
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- TAGS (replaces hashtags)
CREATE TABLE tags (
    id  SERIAL PRIMARY KEY,
    tag VARCHAR(50) UNIQUE NOT NULL
);

-- DOMAIN <-> TAG (replaces book_hashtags)
CREATE TABLE domain_tags (
    domain_id INTEGER NOT NULL,
    tag_id    INTEGER NOT NULL,
    PRIMARY KEY (domain_id, tag_id),
    FOREIGN KEY (domain_id) REFERENCES domains(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id)    REFERENCES tags(id)    ON DELETE CASCADE
);

-- Update last_modified trigger (renamed for domains)
CREATE OR REPLACE FUNCTION update_domains_last_modified()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_modified = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_domains_last_modified
BEFORE UPDATE ON domains
FOR EACH ROW
EXECUTE FUNCTION update_domains_last_modified();

-- Seed categories (from genres)
INSERT INTO categories (name) VALUES
('Brandable'),
('Tech'),
('Finance'),
('Health'),
('Real Estate'),
('Crypto'),
('AI'),
('E-commerce');

-- Seed TLDs (from languages)
INSERT INTO tlds (name, iso_code) VALUES
('.com', 'US'),
('.net', 'US'),
('.org', 'US'),
('.io',  'IO'),
('.ai',  'AI'),
('.de',  'DE'),
('.uk',  'GB');

-- Views (remapped)
CREATE OR REPLACE VIEW domain_full_view AS
SELECT
    d.id,
    d.name,
    (u.first_name || ' ' || u.last_name) AS owner,
    p.name AS portfolio,
    c.name AS category,
    t.name AS tld,
    d.registrar,
    d.price_usd,
    d.status,
    d.listing_url,
    d.logo_url,
    d.created_at,
    d.last_modified
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
    CONCAT(u.first_name, ' ', u.last_name) AS full_name,
    COUNT(d.id) AS domains_count
FROM users u
LEFT JOIN domains d ON u.id = d.owner_id
GROUP BY u.id, u.first_name, u.last_name;

-- ==============================
-- Membership / Customers layer
-- (renamed from Members, etc.)
-- ==============================

CREATE TABLE membership_plans (
    plan_id SERIAL PRIMARY KEY,
    plan_name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    duration INTERVAL
);

CREATE TYPE payment_status AS ENUM ('active', 'expired', 'failed', 'pending');

CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(100),
    phone VARCHAR(20),
    address TEXT,
    plan_id INTEGER REFERENCES membership_plans(plan_id),
    subscription_start DATE,
    subscription_end   DATE,
    payment_status payment_status
);

CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id) ON DELETE CASCADE,
    payment_type VARCHAR(50),
    provider_token VARCHAR(255),
    expiration_date DATE
);

CREATE TABLE login_credentials (
    credential_id SERIAL PRIMARY KEY,
    customer_id INTEGER UNIQUE REFERENCES customers(customer_id) ON DELETE CASCADE,
    username VARCHAR(50) UNIQUE,
    password_hash VARCHAR(255)
);

-- Profile view (renamed from MemberProfile)
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
JOIN membership_plans mp ON c.plan_id = mp.plan_id;

-- Roles (renamed from MemberRoles)
CREATE TABLE roles (
    role_id SERIAL PRIMARY KEY,
    role_name VARCHAR(100) NOT NULL,
    description TEXT
);

ALTER TABLE customers
ADD COLUMN role_id INTEGER REFERENCES roles(role_id);

-- Staff roles (snake_case)
CREATE TABLE staff_roles (
    role_id SERIAL PRIMARY KEY,
    role_name VARCHAR(100) NOT NULL,
    description TEXT,
    permissions TEXT
);

CREATE TABLE staff (
    staff_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    role_id INTEGER REFERENCES staff_roles(role_id),
    email VARCHAR(100),
    phone VARCHAR(20),
    address TEXT,
    hire_date DATE
);

CREATE TABLE staff_login_credentials (
    credential_id SERIAL PRIMARY KEY,
    staff_id INTEGER UNIQUE REFERENCES staff(staff_id) ON DELETE CASCADE,
    username VARCHAR(50) UNIQUE,
    password_hash VARCHAR(255)
);

-- Dashboard view (renamed from MemberDashboard)
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
    p.payment_type,
    p.expiration_date,
    r.role_name AS customer_role
FROM customers c
LEFT JOIN membership_plans mp ON c.plan_id = mp.plan_id
LEFT JOIN payments p          ON c.customer_id = p.customer_id
LEFT JOIN roles r             ON c.role_id = r.role_id;

-- FK safety: when plan deleted, keep customer but null plan_id
ALTER TABLE customers
ADD CONSTRAINT fk_customers_plan_id
FOREIGN KEY (plan_id)
REFERENCES membership_plans(plan_id)
ON DELETE SET NULL;

-----------------

-- Who you buy from / manage on
CREATE TABLE registrars (
  registrar_id SERIAL PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,        -- e.g., Namecheap, GoDaddy
  api_key_id INTEGER,               -- refer to secrets table if you keep keys
  created_at TIMESTAMPTZ DEFAULT now()
);

-- External account a customer uses at a registrar
CREATE TABLE registrar_accounts (
  id SERIAL PRIMARY KEY,
  customer_id INTEGER NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
  registrar_id INTEGER NOT NULL REFERENCES registrars(registrar_id),
  external_username TEXT NOT NULL,
  external_account_id TEXT,         -- if the API returns an ID
  verified BOOLEAN DEFAULT FALSE,
  UNIQUE (customer_id, registrar_id)
);

-- Orders (domains, hosting, SSL, PE) with line items
CREATE TYPE order_status AS ENUM ('pending','paid','provisioning','fulfilled','failed','canceled','refunded');
CREATE TABLE orders (
  order_id BIGSERIAL PRIMARY KEY,
  customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
  status order_status NOT NULL DEFAULT 'pending',
  currency CHAR(3) NOT NULL DEFAULT 'USD',
  subtotal DECIMAL(12,2) NOT NULL DEFAULT 0,
  fees DECIMAL(12,2) NOT NULL DEFAULT 0,
  tax DECIMAL(12,2) NOT NULL DEFAULT 0,
  total DECIMAL(12,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TYPE order_item_type AS ENUM ('domain_registration','domain_transfer','renewal','ssl','hosting','private_email','premium_dns','service_fee');

CREATE TABLE order_items (
  order_item_id BIGSERIAL PRIMARY KEY,
  order_id BIGINT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
  item_type order_item_type NOT NULL,
  sku TEXT,                                      -- e.g., ".com-1y"
  description TEXT,
  quantity INTEGER NOT NULL DEFAULT 1,
  unit_price DECIMAL(12,2) NOT NULL,
  amount DECIMAL(12,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
  meta JSONB DEFAULT '{}'::jsonb                 -- registrar, tld, term, etc.
);

-- Payments recorded against orders (multiple partials allowed)
CREATE TYPE payment_method AS ENUM ('paypal','card','stripe','flutterwave','paystack','opay','palmpay','btc','usdt','bank_transfer','other');
CREATE TYPE payment_state  AS ENUM ('initiated','authorized','captured','failed','refunded','chargeback');

CREATE TABLE order_payments (
  payment_id BIGSERIAL PRIMARY KEY,
  order_id BIGINT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
  method payment_method NOT NULL,
  provider_ref TEXT,                  -- PSP reference/tx id (token, hash)
  amount DECIMAL(12,2) NOT NULL,
  currency CHAR(3) NOT NULL DEFAULT 'USD',
  state payment_state NOT NULL,
  received_at TIMESTAMPTZ DEFAULT now(),
  raw_response JSONB
);

-- Domain ownership history (critical for audit/renewals/transfers)
CREATE TYPE domain_event AS ENUM ('created','assigned','pushed','transferred_in','transferred_out','renewed','dns_changed','status_changed','sold');

CREATE TABLE domain_history (
  id BIGSERIAL PRIMARY KEY,
  domain_id INTEGER NOT NULL REFERENCES domains(id) ON DELETE CASCADE,
  customer_id INTEGER REFERENCES customers(customer_id),
  registrar_id INTEGER REFERENCES registrars(registrar_id),
  event domain_event NOT NULL,
  details JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now()
);

--------------
-- 1) Add a JSONB temp column with a default
ALTER TABLE staff_roles
  ADD COLUMN permissions_tmp JSONB NOT NULL DEFAULT '{}'::jsonb;

-- 2) Migrate data from old TEXT -> JSONB safely
--    - NULL/empty -> {}
--    - If it already looks like JSON object -> cast
--    - Otherwise wrap as {"note": "<old text>"} so you don't lose data
UPDATE staff_roles
SET permissions_tmp = CASE
  WHEN permissions IS NULL OR trim(permissions) = '' THEN '{}'::jsonb
  WHEN permissions ~ '^\s*\{.*\}\s*$' THEN permissions::jsonb
  ELSE jsonb_build_object('note', permissions)
END;

-- 3) Drop old column, rename tmp to permissions
ALTER TABLE staff_roles DROP COLUMN permissions;
ALTER TABLE staff_roles RENAME COLUMN permissions_tmp TO permissions;

-- 4) Default for new rows
ALTER TABLE staff_roles
  ALTER COLUMN permissions SET DEFAULT '{}'::jsonb;

-- 5) Create the GIN index on JSONB (no operator class needed)
CREATE INDEX ix_staff_roles_permissions_gin
  ON staff_roles USING gin (permissions);
------------
-- key existence
SELECT * FROM staff_roles WHERE permissions ? 'can_manage_domains';

-- nested structure check
SELECT * FROM staff_roles
WHERE permissions @> '{"billing":{"refunds":true}}';

