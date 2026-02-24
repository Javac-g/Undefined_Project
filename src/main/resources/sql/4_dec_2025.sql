
CREATE TYPE payment_status AS ENUM ('pending','paid','failed','canceled','refunded');
CREATE TYPE subscription_status AS ENUM ('active','expired','canceled','pending');
CREATE TYPE service_type_enum AS ENUM ('domain', 'ssl', 'hosting', 'email');
CREATE TYPE service_status AS ENUM ('active','pending','expired','canceled','suspended');
CREATE TYPE order_type_enum AS ENUM ('purchase', 'renewal', 'upgrade');
CREATE TYPE user_status AS ENUM ('active','inactive','banned','pending','suspended');
CREATE TYPE user_tier AS ENUM ('basic','premium','business','enterprise');
CREATE TYPE domain_status AS ENUM ('active','expired','pending','canceled','suspended','grace');

CREATE TABLE roles(
	id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	name varchar(25) UNIQUE NOT NULL,
	description varchar(255)

);
CREATE TABLE credentials(
	id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	role_id BIGINT NOT NULL REFERENCES roles(id),
	login varchar(60) UNIQUE NOT NULL,
	email varchar(255) UNIQUE NOT NULL,
	password_hash varchar(255) NOT NULL
	
);
CREATE TABLE users(
	id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	credential_id BIGINT UNIQUE NOT NULL REFERENCES credentials(id) ON DELETE CASCADE,
	full_name varchar(255),
	created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
	updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
	status user_status NOT NULL DEFAULT 'active',
	tier user_tier NOT NULL DEFAULT 'basic'
	
);

CREATE TABLE vendors(
	id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	login varchar(255) UNIQUE DEFAULT 'none',
	email varchar(255) UNIQUE NOT NULL,
	password varchar(255) NOT NULL
	
);
CREATE TABLE vendors_credentials(
	id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	pines_cred BIGINT UNIQUE NOT NULL REFERENCES credentials(id) ON DELETE CASCADE,
	vendors_cred BIGINT UNIQUE NOT NULL REFERENCES vendors(id) ON DELETE CASCADE

);




CREATE TABLE domains (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	user_id BIGINT  NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,                     -- "example"
    tld VARCHAR(50) NOT NULL,                       -- ".com"
    fqdn VARCHAR(310) GENERATED ALWAYS AS (name || tld) STORED,
   
    expires_at TIMESTAMP NOT NULL,
    renewal_date TIMESTAMP NOT NULL,
    price NUMERIC(10,2) NOT NULL,
    renewal_fee NUMERIC(10,2) NOT NULL,
    redemption_fee NUMERIC(10,2) NOT NULL,
    auto_renew BOOLEAN DEFAULT TRUE,
    transfer_lock BOOLEAN DEFAULT TRUE,
	transfer_lock_days INT DEFAULT 60,
    status domain_status NOT NULL DEFAULT 'active',                    -- active, expired, grace, etc.
    nameservers TEXT[] DEFAULT ARRAY[]::TEXT[],
    contacts JSONB NOT NULL,                        -- registrant/admin/tech/billing contacts
    epp_code VARCHAR(255),
    registrar VARCHAR(100) NOT NULL,
    is_legal_flagged BOOLEAN DEFAULT FALSE,         -- flagged for legal or abuse issues
    legal_notes TEXT,                               -- description, case ID, DMCA details, etc.
    created TIMESTAMP DEFAULT NOW(),
    updated TIMESTAMP DEFAULT NOW()
);




CREATE TABLE private_email_services (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
    domain_id BIGINT REFERENCES domains(id) ON UPDATE CASCADE ON DELETE SET NULL,  -- optional link
    service_name VARCHAR(255) NOT NULL,  -- e.g., "Private Email Pro", "Mailbox Plan"
    
    mailbox_count INT NOT NULL DEFAULT 1,  -- number of mailboxes included in this service
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    renewal_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    
    status service_status NOT NULL DEFAULT 'active',
    warnings TEXT[] NOT NULL DEFAULT '{}',
    
    CHECK (expires_at IS NULL OR expires_at > created_at)
);


CREATE TABLE hosting_services (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
    domain_id BIGINT REFERENCES domains(id) ON UPDATE CASCADE ON DELETE SET NULL,  -- optional link
    service_name VARCHAR(255) NOT NULL,   -- e.g., "Stellar Shared", "VPS-2"
    
    website_count INT NOT NULL DEFAULT 1,  -- number of websites allowed
    storage_gb NUMERIC(10,2) NOT NULL DEFAULT 5,  -- storage in GB, default 5GB
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    renewal_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    
    status service_status NOT NULL DEFAULT 'active',
    warnings TEXT[] NOT NULL DEFAULT '{}',
    
    CHECK (expires_at IS NULL OR expires_at > created_at)
);

CREATE TABLE ssl_certificates (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
    domain_id BIGINT REFERENCES domains(id) ON UPDATE CASCADE ON DELETE SET NULL, -- optional link
    
    certificate_cn VARCHAR(255) NOT NULL,   -- Common Name (CN)
    certificate_type VARCHAR(20) NOT NULL DEFAULT 'DV',  -- DV/OV/EV
    validity_days INT NOT NULL DEFAULT 365,
    wildcard BOOLEAN NOT NULL DEFAULT FALSE,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),  -- issued/created time
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    renewal_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    
    status service_status NOT NULL DEFAULT 'active',
    warnings TEXT[] NOT NULL DEFAULT '{}',
    
    CHECK (expires_at IS NULL OR expires_at > created_at)
);

CREATE TABLE apps_services (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
    service_name VARCHAR(255) NOT NULL,          -- e.g., "VPN Pro", "Cloud Backup"
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    renewal_at TIMESTAMPTZ,                     -- optional renewal date
    expires_at TIMESTAMPTZ,                     -- optional expiration
    status service_status NOT NULL DEFAULT 'active',
    warnings TEXT[] NOT NULL DEFAULT '{}',       -- any warnings or notes
    CHECK (expires_at IS NULL OR expires_at > created_at)
);
CREATE TABLE membership_plans (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    plan_name VARCHAR(25) NOT NULL UNIQUE,
    description TEXT,
    duration INTERVAL NOT NULL,
    cost NUMERIC(12,2) NOT NULL,
	service_fee NUMERIC(12,2) NOT NULL DEFAULT 0,
    currency CHAR(3) NOT NULL DEFAULT 'USD',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE subscriptions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
    plan_id BIGINT NOT NULL REFERENCES membership_plans(id) ON UPDATE CASCADE,
    start_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    end_at TIMESTAMPTZ NOT NULL,             -- enforce end > start
    status subscription_status NOT NULL DEFAULT 'active',
    CHECK (end_at > start_at)
);




CREATE TABLE payments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
    subscription_id BIGINT REFERENCES subscriptions(id) ON UPDATE CASCADE ON DELETE SET NULL,
    payment_type VARCHAR(25) NOT NULL,        -- could be ENUM or table
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    currency CHAR(3) NOT NULL DEFAULT 'USD',
    status payment_status NOT NULL DEFAULT 'pending',
    external_id VARCHAR(100),                 -- gateway transaction id
    made_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    description VARCHAR(255)
);


CREATE TABLE orders (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
    service_type service_type_enum NOT NULL,
    service_id BIGINT NOT NULL,
    payment_id BIGINT REFERENCES payments(id) ON UPDATE CASCADE ON DELETE SET NULL,
    order_type order_type_enum NOT NULL DEFAULT 'purchase',
    subscription_fee NUMERIC(12,2),           -- fee based on subscription
    discount_applied NUMERIC(12,2) DEFAULT 0,
    total_amount NUMERIC(12,2) NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'USD',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    renewed_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    status payment_status NOT NULL DEFAULT 'pending'
);


CREATE OR REPLACE FUNCTION set_subscription_end_at()
RETURNS trigger AS $$
BEGIN
    IF NEW.end_at IS NULL THEN
        SELECT NEW.start_at + mp.duration INTO NEW.end_at
        FROM membership_plans mp WHERE mp.id = NEW.plan_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_set_subscription_end_at
BEFORE INSERT ON subscriptions
FOR EACH ROW
EXECUTE FUNCTION set_subscription_end_at();

CREATE OR REPLACE FUNCTION update_email_updated_at()
RETURNS trigger AS $$
BEGIN
   NEW.updated_at := now();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_updated_at
BEFORE UPDATE ON private_email_services
FOR EACH ROW EXECUTE FUNCTION update_email_updated_at();

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


CREATE OR REPLACE FUNCTION apply_subscription_fee()
RETURNS trigger AS $$
DECLARE
    per_order_fee NUMERIC(12,2);
BEGIN
    SELECT mp.service_fee INTO per_order_fee
    FROM subscriptions s
    JOIN membership_plans mp ON s.plan_id = mp.id
    WHERE s.user_id = NEW.user_id
      AND s.status = 'active'
    LIMIT 1;

    IF per_order_fee IS NULL THEN
        per_order_fee := 0;
    END IF;

    NEW.subscription_fee := per_order_fee;
    NEW.total_amount := NEW.total_amount + per_order_fee;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_apply_subscription_fee
BEFORE INSERT ON orders
FOR EACH ROW EXECUTE FUNCTION apply_subscription_fee();

CREATE INDEX idx_credentials_login ON credentials(login);
CREATE INDEX idx_credentials_email ON credentials(email);
CREATE INDEX idx_users_credential_id ON users(credential_id);
CREATE INDEX idx_user_roles_role_id ON roles(id);
CREATE INDEX idx_pemail_user_status   ON private_email_services(user_id, status);
CREATE INDEX idx_pemail_expires       ON private_email_services(expires_at);
CREATE INDEX idx_pemail_domain_status ON private_email_services(domain_id, status);
CREATE INDEX idx_hosting_user_status   ON hosting_services(user_id, status);
CREATE INDEX idx_hosting_expires       ON hosting_services(expires_at);
CREATE INDEX idx_hosting_domain_status ON hosting_services(domain_id, status);
CREATE INDEX idx_ssl_user_status     ON ssl_certificates(user_id, status);
CREATE INDEX idx_ssl_domain_status   ON ssl_certificates(domain_id, status);
CREATE INDEX idx_ssl_expires         ON ssl_certificates(expires_at);
CREATE INDEX idx_domains_user_status ON domains(user_id, status);
CREATE INDEX idx_domains_expires     ON domains(expires_at);
CREATE INDEX idx_subscriptions_user_status ON subscriptions(user_id, status);
CREATE INDEX idx_subscriptions_plan_status ON subscriptions(plan_id, status);
CREATE INDEX idx_payments_user_status          ON payments(user_id, status);
CREATE INDEX idx_payments_subscription_status  ON payments(subscription_id, status);
CREATE INDEX idx_orders_user_status          ON orders(user_id, status);
CREATE INDEX idx_orders_service_type_status ON orders(service_type, status);
CREATE INDEX idx_orders_payment_id          ON orders(payment_id);
CREATE INDEX idx_orders_expires             ON orders(expires_at);



