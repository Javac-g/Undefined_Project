CREATE TYPE payment_status AS ENUM ('pending','paid','failed','canceled','refunded');
CREATE TYPE subscription_status AS ENUM ('active','expired','canceled','pending');

CREATE TABLE membership_plans(
	id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	plan_name varchar(25) NOT NULL UNIQUE,
	description TEXT,
	duration INTERVAL NOT NULL,
	fee numeric(12,2) NOT NULL,
	currency char(3) NOT NULL DEFAULT 'USD',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE users(
	id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	full_name varchar(255)NOT NULL,
	created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
	updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
	status varchar(25) NOT NULL DEFAULT 'active'
	
);

CREATE TABLE subscriptions(
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
  plan_id BIGINT NOT NULL REFERENCES membership_plans(id) ON UPDATE CASCADE,
  start_at timestamptz NOT NULL DEFAULT now(),
  end_at   timestamptz NOT NULL,            -- enforce end > start
  status subscription_status NOT NULL DEFAULT 'active',
  CHECK (end_at > start_at)
);

CREATE TABLE payments(
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
  subscription_id BIGINT  REFERENCES subscriptions(id) ON UPDATE CASCADE ON DELETE SET NULL,
  payment_type varchar(25) NOT NULL,        -- or a separate enum/table
  amount numeric(12,2) NOT NULL CHECK (amount > 0),
  currency char(3) NOT NULL DEFAULT 'USD',
  status payment_status NOT NULL DEFAULT 'pending',
  external_id varchar(100),                 -- gateway transaction id
  made_at timestamptz NOT NULL DEFAULT now(),
  description varchar(255)
	
);
CREATE TABLE roles(
	id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	name varchar(25) NOT NULL UNIQUE,
	description varchar(255)

);


CREATE TABLE login_credentials(
	id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	user_id BIGINT NOT NULL REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
	username varchar(60)NOT NULL UNIQUE,
	email varchar(255) NOT NULL UNIQUE,
	password_hash TEXT NOT NULL,
	is_locked boolean NOT NULL DEFAULT false
);

CREATE TABLE user_roles(
  user_id BIGINT NOT NULL REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
  role_id BIGINT NOT NULL REFERENCES roles(id) ON UPDATE CASCADE ON DELETE CASCADE,
  PRIMARY KEY (user_id, role_id)
);

CREATE UNIQUE INDEX uq_sub_one_open_per_user
    ON subscriptions(user_id)
    WHERE status IN ('active','pending');

CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_plan_id ON subscriptions(plan_id);
CREATE INDEX idx_subscriptions_status  ON subscriptions(status);
CREATE INDEX idx_payments_user_id          ON payments(user_id);
CREATE INDEX idx_payments_subscription_id  ON payments(subscription_id);
CREATE INDEX idx_payments_status           ON payments(status);
CREATE INDEX idx_user_roles_role_id ON user_roles(role_id);
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_plans_updated
BEFORE UPDATE ON membership_plans
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE OR REPLACE FUNCTION set_subscription_end_at()
RETURNS trigger AS $$
DECLARE v_duration interval;
BEGIN
  SELECT duration INTO v_duration FROM membership_plans WHERE id = NEW.plan_id;
  IF NEW.start_at IS NULL THEN
    NEW.start_at := now();
  END IF;
  NEW.end_at := NEW.start_at + v_duration;
  RETURN NEW;
END; $$ LANGUAGE plpgsql;

-- On INSERT compute end_at; on UPDATE recompute if plan or start changed
DROP TRIGGER IF EXISTS trg_subscriptions_set_end_at_ins ON subscriptions;
CREATE TRIGGER trg_subscriptions_set_end_at_ins
BEFORE INSERT ON subscriptions
FOR EACH ROW EXECUTE FUNCTION set_subscription_end_at();

DROP TRIGGER IF EXISTS trg_subscriptions_set_end_at_upd ON subscriptions;
CREATE TRIGGER trg_subscriptions_set_end_at_upd
BEFORE UPDATE OF plan_id, start_at ON subscriptions
FOR EACH ROW EXECUTE FUNCTION set_subscription_end_at();
ALTER TABLE membership_plans
  ADD CONSTRAINT chk_plan_currency_uc CHECK (currency ~ '^[A-Z]{3}$');

ALTER TABLE payments
  ADD CONSTRAINT chk_payment_currency_uc CHECK (currency ~ '^[A-Z]{3}$');

  -- Reusable status for service-like resources
CREATE TYPE service_status AS ENUM ('active','pending','expired','canceled','suspended');

-- =========================
-- DOMAINS
-- =========================
CREATE TABLE domains (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
  domain_name VARCHAR(255) NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  renewal_at TIMESTAMPTZ,                 -- next renewal date (if scheduled)
  expires_at TIMESTAMPTZ,                 -- registry expiry
  status service_status NOT NULL DEFAULT 'active',
  warnings TEXT[] NOT NULL DEFAULT '{}',
  CHECK (expires_at IS NULL OR expires_at > created_at)
);

CREATE INDEX idx_domains_user_id   ON domains(user_id);
CREATE INDEX idx_domains_status    ON domains(status);
CREATE INDEX idx_domains_expires   ON domains(expires_at);

-- Auto-updated updated_at (reuses your set_updated_at())
CREATE TRIGGER trg_domains_updated
BEFORE UPDATE ON domains
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =========================
-- SSL CERTIFICATES
-- =========================
CREATE TABLE ssl_certificates (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
  domain_id BIGINT REFERENCES domains(id) ON UPDATE CASCADE ON DELETE SET NULL, -- optional link
  certificate_cn VARCHAR(255) NOT NULL,   -- Common Name (CN)
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),  -- issued/created time
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  renewal_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  status service_status NOT NULL DEFAULT 'active',
  warnings TEXT[] NOT NULL DEFAULT '{}',
  CHECK (expires_at IS NULL OR expires_at > created_at)
);

CREATE INDEX idx_ssl_user_id     ON ssl_certificates(user_id);
CREATE INDEX idx_ssl_domain_id   ON ssl_certificates(domain_id);
CREATE INDEX idx_ssl_status      ON ssl_certificates(status);
CREATE INDEX idx_ssl_expires     ON ssl_certificates(expires_at);

CREATE TRIGGER trg_ssl_updated
BEFORE UPDATE ON ssl_certificates
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =========================
-- HOSTING SERVICES
-- =========================
CREATE TABLE hosting_services (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
  domain_id BIGINT REFERENCES domains(id) ON UPDATE CASCADE ON DELETE SET NULL,  -- optional link
  service_name VARCHAR(255) NOT NULL,   -- e.g., "Stellar Shared", "VPS-2"
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  renewal_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  status service_status NOT NULL DEFAULT 'active',
  warnings TEXT[] NOT NULL DEFAULT '{}',
  CHECK (expires_at IS NULL OR expires_at > created_at)
);

CREATE INDEX idx_hosting_user_id   ON hosting_services(user_id);
CREATE INDEX idx_hosting_domain_id ON hosting_services(domain_id);
CREATE INDEX idx_hosting_status    ON hosting_services(status);
CREATE INDEX idx_hosting_expires   ON hosting_services(expires_at);

CREATE TRIGGER trg_hosting_updated
BEFORE UPDATE ON hosting_services
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =========================
-- PRIVATE EMAIL SERVICES
-- =========================
CREATE TABLE private_email_services (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
  domain_id BIGINT REFERENCES domains(id) ON UPDATE CASCADE ON DELETE SET NULL,  -- optional link
  service_name VARCHAR(255) NOT NULL,  -- e.g., "Private Email Pro", "Mailbox Plan"
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  renewal_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  status service_status NOT NULL DEFAULT 'active',
  warnings TEXT[] NOT NULL DEFAULT '{}',
  CHECK (expires_at IS NULL OR expires_at > created_at)
);

CREATE INDEX idx_pemail_user_id   ON private_email_services(user_id);
CREATE INDEX idx_pemail_domain_id ON private_email_services(domain_id);
CREATE INDEX idx_pemail_status    ON private_email_services(status);
CREATE INDEX idx_pemail_expires   ON private_email_services(expires_at);

CREATE TRIGGER trg_pemail_updated
BEFORE UPDATE ON private_email_services
FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TABLE orders (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
  service_type VARCHAR(30) NOT NULL,       -- e.g., 'domain', 'ssl', 'hosting', 'email'
  service_id BIGINT NOT NULL,              -- id of the specific service (domain_id, ssl_id, etc.)
  payment_id BIGINT REFERENCES payments(id) ON UPDATE CASCADE ON DELETE SET NULL,
  total_amount NUMERIC(12,2) NOT NULL,
  currency CHAR(3) NOT NULL DEFAULT 'USD',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  renewed_at TIMESTAMPTZ,                 -- if this order represents a renewal
  expires_at TIMESTAMPTZ,
  status payment_status NOT NULL DEFAULT 'pending'
);
CREATE TYPE service_type_enum AS ENUM ('domain', 'ssl', 'hosting', 'email');

ALTER TABLE orders
  ALTER COLUMN service_type TYPE service_type_enum
  USING service_type::service_type_enum;
  CREATE OR REPLACE FUNCTION validate_order_service()
RETURNS trigger AS $$
BEGIN
  CASE NEW.service_type
    WHEN 'domain' THEN
      IF NOT EXISTS (SELECT 1 FROM domains WHERE id = NEW.service_id) THEN
        RAISE EXCEPTION 'Invalid domain_id % for order %', NEW.service_id, NEW.id;
      END IF;
    WHEN 'ssl' THEN
      IF NOT EXISTS (SELECT 1 FROM ssl_certificates WHERE id = NEW.service_id) THEN
        RAISE EXCEPTION 'Invalid ssl_id % for order %', NEW.service_id, NEW.id;
      END IF;
    WHEN 'hosting' THEN
      IF NOT EXISTS (SELECT 1 FROM hosting_services WHERE id = NEW.service_id) THEN
        RAISE EXCEPTION 'Invalid hosting_id % for order %', NEW.service_id, NEW.id;
      END IF;
    WHEN 'email' THEN
      IF NOT EXISTS (SELECT 1 FROM private_email_services WHERE id = NEW.service_id) THEN
        RAISE EXCEPTION 'Invalid email_id % for order %', NEW.service_id, NEW.id;
      END IF;
  END CASE;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_order_service
BEFORE INSERT OR UPDATE ON orders
FOR EACH ROW EXECUTE FUNCTION validate_order_service();

