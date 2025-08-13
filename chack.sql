-- Domains ownership fields present?
SELECT column_name, data_type FROM information_schema.columns
WHERE table_name='domains' AND column_name IN
('steward_user_id','current_owner_customer_id','company_owned','registrar_account_id',
 'expires_at','auto_renew','lock_status','auth_code','nameservers','status_enum');

-- Views compile?
SELECT 1 FROM domain_full_view LIMIT 1;
SELECT 1 FROM customer_dashboard LIMIT 1;
