# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_10_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "account_deletion_requests", force: :cascade do |t|
    t.datetime "canceled_at"
    t.datetime "completed_at"
    t.string "cpf_cnpj_fingerprint"
    t.datetime "created_at", null: false
    t.string "email_fingerprint"
    t.string "name_fingerprint"
    t.string "phone_fingerprint"
    t.datetime "requested_at", null: false
    t.datetime "scheduled_for", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index [ "completed_at" ], name: "index_account_deletion_requests_on_completed_at"
    t.index [ "cpf_cnpj_fingerprint" ], name: "index_account_deletion_requests_on_cpf_cnpj_fingerprint"
    t.index [ "email_fingerprint" ], name: "index_account_deletion_requests_on_email_fingerprint"
    t.index [ "name_fingerprint" ], name: "index_account_deletion_requests_on_name_fingerprint"
    t.index [ "phone_fingerprint" ], name: "index_account_deletion_requests_on_phone_fingerprint"
    t.index [ "status", "scheduled_for" ], name: "index_account_deletion_requests_on_status_and_scheduled_for"
    t.index [ "user_id" ], name: "index_account_deletion_requests_on_pending_user_id", unique: true, where: "(status = 0)"
    t.index [ "user_id" ], name: "index_account_deletion_requests_on_user_id"
  end

  create_table "anella_space_profiles", force: :cascade do |t|
    t.string "address"
    t.boolean "appointment_automation_enabled", default: false, null: false
    t.text "booking_success_message"
    t.text "business_hours"
    t.jsonb "business_hours_schedule", default: {}
    t.string "business_type"
    t.integer "cancellation_min_hours_before"
    t.datetime "completed_onboarding_at"
    t.integer "confirmation_lead_hours", default: [ 24, 2 ], null: false, array: true
    t.time "confirmation_quiet_hours_end"
    t.time "confirmation_quiet_hours_start"
    t.datetime "created_at", null: false
    t.bigint "default_inbox_assignee_id"
    t.string "email"
    t.string "facebook_url"
    t.string "instagram_url"
    t.datetime "onboarding_nudge_sent_at"
    t.integer "onboarding_step", default: 0, null: false
    t.integer "personalized_slug_changes_count", default: 0, null: false
    t.datetime "personalized_slug_last_changed_at"
    t.string "phone"
    t.integer "request_max_days_ahead"
    t.integer "request_min_hours_ahead"
    t.integer "reschedule_min_hours_before"
    t.integer "slot_duration_minutes", default: 30, null: false
    t.bigint "space_id", null: false
    t.datetime "updated_at", null: false
    t.index [ "space_id" ], name: "index_anella_space_profiles_on_space_id"
  end

  create_table "appointment_events", force: :cascade do |t|
    t.bigint "actor_id"
    t.string "actor_label"
    t.string "actor_type", null: false
    t.bigint "appointment_id", null: false
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.string "idempotency_key", null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "space_id", null: false
    t.index [ "appointment_id" ], name: "index_appointment_events_on_appointment_id"
    t.index [ "idempotency_key" ], name: "index_appointment_events_on_idempotency_key", unique: true
    t.index [ "space_id", "appointment_id", "created_at" ], name: "idx_appt_events_space_appointment_created_at"
    t.index [ "space_id" ], name: "index_appointment_events_on_space_id"
  end

  create_table "appointment_reminders", force: :cascade do |t|
    t.string "action_token_digest"
    t.bigint "appointment_id", null: false
    t.string "channel", default: "whatsapp", null: false
    t.datetime "created_at", null: false
    t.datetime "delivered_at"
    t.datetime "fire_at", null: false
    t.string "kind", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "sent_at"
    t.bigint "space_id", null: false
    t.integer "status", default: 0, null: false
    t.string "template_name"
    t.string "template_version"
    t.datetime "updated_at", null: false
    t.string "wamid"
    t.index [ "appointment_id", "kind" ], name: "idx_reminders_one_live_per_kind", unique: true, where: "(status = ANY (ARRAY[0, 1, 2, 3]))"
    t.index [ "appointment_id" ], name: "index_appointment_reminders_on_appointment_id"
    t.index [ "space_id" ], name: "index_appointment_reminders_on_space_id"
    t.index [ "status", "fire_at" ], name: "idx_reminders_dispatcher_scan"
    t.index [ "wamid" ], name: "index_appointment_reminders_on_wamid", unique: true, where: "(wamid IS NOT NULL)"
  end

  create_table "appointments", force: :cascade do |t|
    t.integer "appointment_mode", default: 0, null: false
    t.bigint "bookable_resource_id"
    t.datetime "confirmation_decided_at"
    t.string "confirmation_decided_via"
    t.integer "confirmation_state", default: 0, null: false
    t.datetime "created_at", null: false
    t.bigint "customer_id"
    t.datetime "discarded_at"
    t.integer "duration_minutes"
    t.datetime "finished_at"
    t.text "meeting_instructions"
    t.string "meeting_url"
    t.datetime "requested_at"
    t.datetime "rescheduled_from"
    t.datetime "scheduled_at"
    t.bigint "space_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index [ "bookable_resource_id" ], name: "index_appointments_on_bookable_resource_id"
    t.index [ "customer_id", "scheduled_at" ], name: "index_appointments_on_client_scheduled_at"
    t.index [ "customer_id" ], name: "index_appointments_on_customer_id"
    t.index [ "discarded_at" ], name: "index_appointments_on_discarded_at"
    t.index [ "space_id", "appointment_mode" ], name: "index_appointments_on_space_id_and_appointment_mode"
    t.index [ "space_id", "bookable_resource_id" ], name: "index_appointments_on_space_id_and_bookable_resource_id"
    t.index [ "space_id", "confirmation_state" ], name: "index_appointments_on_space_id_and_confirmation_state"
    t.index [ "space_id", "scheduled_at" ], name: "index_appointments_unique_active_slot", unique: true, where: "((status = ANY (ARRAY[0, 1, 3])) AND (scheduled_at IS NOT NULL) AND (discarded_at IS NULL))"
    t.index [ "space_id", "status", "scheduled_at" ], name: "index_appointments_on_space_status_scheduled_at"
    t.index [ "space_id" ], name: "index_appointments_on_space_id"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.bigint "actor_user_id"
    t.bigint "auditable_id"
    t.string "auditable_type"
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.boolean "impersonated", default: false, null: false
    t.string "ip_address"
    t.jsonb "metadata", default: {}, null: false
    t.string "request_id"
    t.bigint "space_id"
    t.string "subject_cpf_cnpj_fingerprint"
    t.string "subject_email_fingerprint"
    t.bigint "subject_id"
    t.string "subject_name_fingerprint"
    t.string "subject_phone_fingerprint"
    t.string "subject_type"
    t.index [ "actor_user_id", "created_at" ], name: "index_audit_logs_on_actor_user_id_and_created_at"
    t.index [ "actor_user_id" ], name: "index_audit_logs_on_actor_user_id"
    t.index [ "auditable_type", "auditable_id" ], name: "index_audit_logs_on_auditable_type_and_auditable_id"
    t.index [ "created_at" ], name: "index_audit_logs_on_created_at"
    t.index [ "event_type" ], name: "index_audit_logs_on_event_type"
    t.index [ "space_id", "created_at" ], name: "index_audit_logs_on_space_id_and_created_at"
    t.index [ "space_id" ], name: "index_audit_logs_on_space_id"
    t.index [ "subject_cpf_cnpj_fingerprint" ], name: "index_audit_logs_on_subject_cpf_cnpj_fingerprint"
    t.index [ "subject_email_fingerprint" ], name: "index_audit_logs_on_subject_email_fingerprint"
    t.index [ "subject_name_fingerprint" ], name: "index_audit_logs_on_subject_name_fingerprint"
    t.index [ "subject_phone_fingerprint" ], name: "index_audit_logs_on_subject_phone_fingerprint"
    t.index [ "subject_type", "subject_id" ], name: "index_audit_logs_on_subject_type_and_subject_id"
  end

  create_table "availability_schedules", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "schedulable_id", null: false
    t.string "schedulable_type", null: false
    t.string "timezone"
    t.datetime "updated_at", null: false
    t.index [ "schedulable_type", "schedulable_id" ], name: "index_availability_schedules_on_schedulable"
  end

  create_table "availability_windows", force: :cascade do |t|
    t.bigint "availability_schedule_id", null: false
    t.time "closes_at", null: false
    t.datetime "created_at", null: false
    t.time "opens_at", null: false
    t.datetime "updated_at", null: false
    t.integer "weekday", null: false
    t.index [ "availability_schedule_id", "weekday" ], name: "index_availability_windows_on_schedule_weekday"
    t.index [ "availability_schedule_id" ], name: "index_availability_windows_on_availability_schedule_id"
  end

  create_table "backup_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "enabled", default: true, null: false
    t.text "last_error"
    t.datetime "last_failure_at"
    t.string "last_remote_key"
    t.datetime "last_run_finished_at"
    t.datetime "last_run_started_at"
    t.string "last_status"
    t.datetime "last_success_at"
    t.datetime "updated_at", null: false
  end

  create_table "billing_coupon_redemption_cycles", force: :cascade do |t|
    t.string "asaas_payment_id", null: false
    t.integer "base_amount_cents", null: false
    t.integer "charged_amount_cents", null: false
    t.bigint "coupon_redemption_id", null: false
    t.datetime "created_at", null: false
    t.integer "cycle_number", null: false
    t.integer "discount_amount_cents", null: false
    t.bigint "payment_id"
    t.datetime "updated_at", null: false
    t.index [ "asaas_payment_id" ], name: "index_billing_coupon_redemption_cycles_on_asaas_payment_id"
    t.index [ "coupon_redemption_id", "asaas_payment_id" ], name: "idx_coupon_redemption_cycles_unique_payment", unique: true
    t.index [ "coupon_redemption_id" ], name: "index_billing_coupon_redemption_cycles_on_coupon_redemption_id"
    t.index [ "payment_id" ], name: "index_billing_coupon_redemption_cycles_on_payment_id"
    t.check_constraint "cycle_number > 0 AND base_amount_cents > 0 AND discount_amount_cents >= 0 AND charged_amount_cents > 0", name: "chk_coupon_redemption_cycles_amounts_positive"
  end

  create_table "billing_coupon_redemptions", force: :cascade do |t|
    t.bigint "actor_id"
    t.integer "amount_off_cents"
    t.datetime "asaas_synced_at"
    t.bigint "billing_product_id", null: false
    t.string "coupon_code", null: false
    t.bigint "coupon_id", null: false
    t.datetime "created_at", null: false
    t.integer "cycles_consumed", default: 0, null: false
    t.integer "discount_type", null: false
    t.integer "duration", null: false
    t.integer "duration_months", default: 1, null: false
    t.datetime "ended_at"
    t.integer "percent_off"
    t.integer "source", null: false
    t.bigint "space_id", null: false
    t.datetime "starts_at", null: false
    t.integer "status", default: 0, null: false
    t.bigint "subscription_id", null: false
    t.text "sync_error"
    t.datetime "updated_at", null: false
    t.index [ "actor_id" ], name: "index_billing_coupon_redemptions_on_actor_id"
    t.index [ "billing_product_id" ], name: "index_billing_coupon_redemptions_on_billing_product_id"
    t.index [ "coupon_id", "status" ], name: "index_billing_coupon_redemptions_on_coupon_id_and_status"
    t.index [ "coupon_id" ], name: "index_billing_coupon_redemptions_on_coupon_id"
    t.index [ "space_id", "coupon_id" ], name: "index_billing_coupon_redemptions_on_space_id_and_coupon_id"
    t.index [ "space_id" ], name: "index_billing_coupon_redemptions_on_space_id"
    t.index [ "subscription_id", "status" ], name: "index_billing_coupon_redemptions_on_subscription_id_and_status"
    t.index [ "subscription_id" ], name: "idx_coupon_redemptions_one_current_per_subscription", unique: true, where: "(status = ANY (ARRAY[0, 1, 2]))"
    t.index [ "subscription_id" ], name: "index_billing_coupon_redemptions_on_subscription_id"
    t.check_constraint "cycles_consumed >= 0", name: "chk_coupon_redemptions_cycles_non_negative"
    t.check_constraint "duration <> 0 OR duration_months > 0", name: "chk_coupon_redemptions_duration_months_positive"
  end

  create_table "billing_coupons", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.integer "amount_off_cents"
    t.bigint "billing_product_id", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.integer "discount_type", null: false
    t.integer "duration", default: 0, null: false
    t.integer "duration_months", default: 1, null: false
    t.datetime "expires_at"
    t.integer "max_redemptions"
    t.integer "max_redemptions_per_space", default: 1, null: false
    t.string "name", null: false
    t.integer "percent_off"
    t.boolean "public", default: true, null: false
    t.datetime "starts_at"
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.index [ "active", "public" ], name: "index_billing_coupons_on_active_and_public"
    t.index [ "billing_product_id", "code" ], name: "index_billing_coupons_on_billing_product_id_and_code", unique: true
    t.index [ "billing_product_id" ], name: "index_billing_coupons_on_billing_product_id"
    t.index [ "created_by_id" ], name: "index_billing_coupons_on_created_by_id"
    t.index [ "expires_at" ], name: "index_billing_coupons_on_expires_at"
    t.index [ "updated_by_id" ], name: "index_billing_coupons_on_updated_by_id"
    t.check_constraint "discount_type = 0 AND percent_off >= 1 AND percent_off <= 100 AND amount_off_cents IS NULL OR discount_type = 1 AND amount_off_cents > 0 AND percent_off IS NULL", name: "chk_billing_coupons_discount_value"
    t.check_constraint "duration <> 0 OR duration_months > 0", name: "chk_billing_coupons_duration_months_positive"
    t.check_constraint "max_redemptions IS NULL OR max_redemptions > 0", name: "chk_billing_coupons_max_redemptions_positive"
    t.check_constraint "max_redemptions_per_space > 0", name: "chk_billing_coupons_max_per_space_positive"
  end

  create_table "billing_credit_transactions", force: :cascade do |t|
    t.bigint "actor_id"
    t.integer "amount", null: false
    t.integer "balance_after", null: false
    t.datetime "created_at", null: false
    t.string "idempotency_key"
    t.jsonb "metadata", default: {}, null: false
    t.string "meter", null: false
    t.string "source", null: false
    t.bigint "space_id", null: false
    t.datetime "updated_at", null: false
    t.index [ "actor_id" ], name: "index_billing_credit_transactions_on_actor_id"
    t.index [ "idempotency_key" ], name: "index_billing_credit_transactions_on_idempotency_key", unique: true
    t.index [ "meter" ], name: "index_billing_credit_transactions_on_meter"
    t.index [ "space_id", "meter" ], name: "index_billing_credit_transactions_on_space_id_and_meter"
    t.index [ "space_id" ], name: "index_billing_credit_transactions_on_space_id"
  end

  create_table "billing_events", force: :cascade do |t|
    t.integer "actor_id"
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "space_id", null: false
    t.bigint "subscription_id"
    t.index "((metadata ->> 'asaas_payment_id'::text))", name: "idx_billing_events_metadata_asaas_payment_id", where: "((metadata ->> 'asaas_payment_id'::text) IS NOT NULL)"
    t.index [ "event_type" ], name: "index_billing_events_on_event_type"
    t.index [ "space_id", "created_at" ], name: "index_billing_events_on_space_id_and_created_at"
    t.index [ "space_id" ], name: "index_billing_events_on_space_id"
    t.index [ "subscription_id" ], name: "index_billing_events_on_subscription_id"
  end

  create_table "billing_plans", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.jsonb "allowed_payment_methods", default: [], null: false
    t.bigint "billing_product_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.jsonb "features", default: [], null: false
    t.boolean "highlighted", default: false, null: false
    t.integer "max_customers"
    t.integer "max_scheduling_links"
    t.integer "max_team_members"
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.integer "price_cents", default: 0, null: false
    t.boolean "public", default: true, null: false
    t.string "slug", null: false
    t.boolean "trial_default", default: false, null: false
    t.datetime "updated_at", null: false
    t.integer "whatsapp_monthly_quota"
    t.index [ "billing_product_id", "slug" ], name: "index_billing_plans_on_product_and_slug", unique: true
    t.index [ "billing_product_id", "trial_default" ], name: "index_billing_plans_on_product_and_trial_default", unique: true, where: "(trial_default = true)"
    t.index [ "billing_product_id" ], name: "index_billing_plans_on_billing_product_id"
    t.index [ "position" ], name: "index_billing_plans_on_position"
  end

  create_table "billing_products", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index [ "key" ], name: "index_billing_products_on_key", unique: true
  end

  create_table "bookable_resources", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "color"
    t.datetime "created_at", null: false
    t.integer "default_duration_minutes"
    t.boolean "default_resource", default: false, null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.string "resource_type", default: "generic", null: false
    t.bigint "space_id", null: false
    t.bigint "space_membership_id"
    t.datetime "updated_at", null: false
    t.index [ "space_id", "active" ], name: "index_bookable_resources_on_space_id_and_active"
    t.index [ "space_id", "space_membership_id" ], name: "index_bookable_resources_on_space_id_and_space_membership_id"
    t.index [ "space_id" ], name: "index_bookable_resources_on_space_id"
    t.index [ "space_id" ], name: "index_bookable_resources_one_default_per_space", unique: true, where: "(default_resource = true)"
    t.index [ "space_membership_id" ], name: "index_bookable_resources_on_space_membership_id"
  end

  create_table "conversation_messages", force: :cascade do |t|
    t.text "body"
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.integer "credit_cost", default: 0, null: false
    t.integer "direction", null: false
    t.string "external_message_id"
    t.string "message_type", default: "text"
    t.jsonb "metadata", default: {}
    t.bigint "sent_by_id"
    t.integer "status", default: 0
    t.datetime "updated_at", null: false
    t.index [ "conversation_id", "created_at" ], name: "index_conversation_messages_on_conversation_id_and_created_at"
    t.index [ "conversation_id" ], name: "index_conversation_messages_on_conversation_id"
    t.index [ "external_message_id" ], name: "index_conversation_messages_on_external_message_id", unique: true, where: "(external_message_id IS NOT NULL)"
    t.index [ "sent_by_id" ], name: "index_conversation_messages_on_sent_by_id"
  end

  create_table "conversations", force: :cascade do |t|
    t.bigint "assigned_to_id"
    t.integer "channel", null: false
    t.string "contact_identifier", null: false
    t.string "contact_name"
    t.datetime "created_at", null: false
    t.integer "credit_cost_total", default: 0, null: false
    t.bigint "customer_id"
    t.string "external_id", null: false
    t.datetime "first_response_at"
    t.datetime "last_message_at"
    t.string "last_message_body"
    t.jsonb "metadata", default: {}
    t.integer "priority", default: 1, null: false
    t.datetime "session_expires_at"
    t.boolean "sla_breached", default: false, null: false
    t.datetime "sla_deadline_at"
    t.bigint "space_id", null: false
    t.integer "status", default: 0, null: false
    t.string "subject"
    t.boolean "unread", default: false, null: false
    t.datetime "updated_at", null: false
    t.index [ "assigned_to_id" ], name: "index_conversations_on_assigned_to_id"
    t.index [ "customer_id" ], name: "index_conversations_on_customer_id"
    t.index [ "space_id", "assigned_to_id" ], name: "index_conversations_on_space_id_and_assigned_to_id", where: "(assigned_to_id IS NOT NULL)"
    t.index [ "space_id", "channel", "external_id" ], name: "index_conversations_on_space_id_and_channel_and_external_id", unique: true
    t.index [ "space_id", "channel" ], name: "index_conversations_on_space_id_and_channel"
    t.index [ "space_id", "customer_id" ], name: "index_conversations_on_space_id_and_customer_id"
    t.index [ "space_id", "sla_breached" ], name: "index_conversations_on_space_id_and_sla_breached", where: "(sla_breached = true)"
    t.index [ "space_id", "status", "last_message_at" ], name: "index_conversations_on_space_id_and_status_and_last_message_at"
    t.index [ "space_id", "unread" ], name: "index_conversations_on_space_id_and_unread", where: "((unread = true) AND (status = ANY (ARRAY[1, 2, 3])))"
    t.index [ "space_id" ], name: "index_conversations_on_space_id"
  end

  create_table "credit_bundles", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.integer "amount", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.integer "price_cents", null: false
    t.datetime "updated_at", null: false
    t.index [ "position" ], name: "index_credit_bundles_on_position"
  end

  create_table "credit_purchases", force: :cascade do |t|
    t.integer "actor_id"
    t.integer "amount", null: false
    t.string "asaas_payment_id"
    t.string "bank_slip_url"
    t.datetime "created_at", null: false
    t.bigint "credit_bundle_id", null: false
    t.string "invoice_url"
    t.text "pix_payload"
    t.text "pix_qr_code_base64"
    t.integer "price_cents", null: false
    t.bigint "space_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index [ "asaas_payment_id" ], name: "index_credit_purchases_on_asaas_payment_id", unique: true, where: "(asaas_payment_id IS NOT NULL)"
    t.index [ "credit_bundle_id" ], name: "index_credit_purchases_on_credit_bundle_id"
    t.index [ "space_id", "status" ], name: "index_credit_purchases_on_space_id_and_status"
    t.index [ "space_id" ], name: "index_credit_purchases_on_space_id"
  end

  create_table "crm_public_profiles", force: :cascade do |t|
    t.text "address"
    t.text "booking_success_message"
    t.string "business_type"
    t.datetime "created_at", null: false
    t.string "display_name", null: false
    t.string "email"
    t.string "facebook_url"
    t.string "instagram_url"
    t.string "phone"
    t.datetime "published_at"
    t.string "slug"
    t.bigint "space_id", null: false
    t.datetime "updated_at", null: false
    t.index [ "slug" ], name: "index_crm_public_profiles_on_slug", unique: true, where: "(slug IS NOT NULL)"
    t.index [ "space_id" ], name: "index_crm_public_profiles_on_space_id", unique: true
  end

  create_table "customers", force: :cascade do |t|
    t.string "address"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "locale"
    t.string "name", null: false
    t.string "phone"
    t.bigint "space_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.string "whatsapp_opt_in_source"
    t.string "whatsapp_opt_out_source"
    t.datetime "whatsapp_opted_in_at"
    t.datetime "whatsapp_opted_out_at"
    t.index "space_id, lower((email)::text)", name: "index_customers_on_space_id_lower_email", where: "(email IS NOT NULL)"
    t.index [ "space_id" ], name: "index_customers_on_space_id"
    t.index [ "user_id" ], name: "index_customers_on_user_id"
  end

  create_table "demo_scheduling_appointments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "scheduled_at", null: false
    t.bigint "space_id"
    t.string "status", default: "pending", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index [ "space_id" ], name: "index_demo_scheduling_appointments_on_space_id"
  end

  create_table "message_credits", force: :cascade do |t|
    t.integer "balance", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "monthly_quota_remaining", default: 0, null: false
    t.datetime "quota_refreshed_at"
    t.bigint "space_id", null: false
    t.datetime "updated_at", null: false
    t.index [ "space_id" ], name: "index_message_credits_on_space_id"
    t.index [ "space_id" ], name: "index_message_credits_on_space_id_unique", unique: true
  end

  create_table "messages", force: :cascade do |t|
    t.integer "channel", default: 0, null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.bigint "messageable_id", null: false
    t.string "messageable_type", null: false
    t.bigint "recipient_id", null: false
    t.bigint "sender_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index [ "messageable_type", "messageable_id" ], name: "index_messages_on_messageable"
    t.index [ "recipient_id", "created_at" ], name: "index_messages_on_recipient_id_created_at"
    t.index [ "recipient_id" ], name: "index_messages_on_recipient_id"
    t.index [ "sender_id", "created_at" ], name: "index_messages_on_sender_id_created_at"
    t.index [ "sender_id" ], name: "index_messages_on_sender_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "event_type", default: "", null: false
    t.bigint "notifiable_id", null: false
    t.string "notifiable_type", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index [ "event_type" ], name: "index_notifications_on_event_type"
    t.index [ "notifiable_type", "notifiable_id" ], name: "index_notifications_on_notifiable"
    t.index [ "user_id" ], name: "index_notifications_on_user_id"
  end

  create_table "pave_audit_events", force: :cascade do |t|
    t.bigint "actor_id"
    t.string "actor_label"
    t.string "actor_type"
    t.datetime "created_at", null: false
    t.string "idempotency_key"
    t.string "key", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "occurred_at", null: false
    t.string "request_id"
    t.string "source"
    t.bigint "space_id"
    t.bigint "target_id"
    t.string "target_label"
    t.string "target_type"
    t.datetime "updated_at", null: false
    t.index [ "actor_type", "actor_id", "occurred_at" ], name: "idx_on_actor_type_actor_id_occurred_at_de079bcc5d"
    t.index [ "idempotency_key" ], name: "index_pave_audit_events_on_idempotency_key", unique: true, where: "(idempotency_key IS NOT NULL)"
    t.index [ "key", "occurred_at" ], name: "index_pave_audit_events_on_key_and_occurred_at"
    t.index [ "space_id", "occurred_at" ], name: "index_pave_audit_events_on_space_id_and_occurred_at"
    t.index [ "target_type", "target_id", "occurred_at" ], name: "idx_on_target_type_target_id_occurred_at_6ba21dd835"
  end

  create_table "pave_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.string "namespace", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.text "value"
    t.string "value_type", default: "string", null: false
    t.index [ "namespace", "key" ], name: "index_pave_settings_on_namespace_and_key", unique: true
    t.index [ "updated_by_id" ], name: "index_pave_settings_on_updated_by_id"
  end

  create_table "payments", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.string "asaas_payment_id", null: false
    t.string "asaas_status"
    t.datetime "created_at", null: false
    t.date "due_date"
    t.string "invoice_url"
    t.datetime "paid_at"
    t.integer "payment_method", null: false
    t.bigint "space_id", null: false
    t.integer "status", default: 0, null: false
    t.bigint "subscription_id", null: false
    t.datetime "updated_at", null: false
    t.index [ "asaas_payment_id" ], name: "index_payments_on_asaas_payment_id", unique: true
    t.index [ "space_id" ], name: "index_payments_on_space_id"
    t.index [ "status", "payment_method", "due_date" ], name: "index_payments_on_status_method_due_date"
    t.index [ "subscription_id", "created_at" ], name: "index_payments_on_subscription_id_and_created_at"
    t.index [ "subscription_id" ], name: "index_payments_on_subscription_id"
  end

  create_table "personalized_scheduling_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "slug", null: false
    t.bigint "space_id", null: false
    t.datetime "updated_at", null: false
    t.index [ "slug" ], name: "index_personalized_scheduling_links_on_slug", unique: true
    t.index [ "space_id" ], name: "index_personalized_scheduling_links_on_space_id"
  end

  create_table "platform_meta_template_library_refreshes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "error_code"
    t.text "error_message"
    t.datetime "finished_at"
    t.string "locale", null: false
    t.jsonb "metadata", default: {}, null: false
    t.integer "refreshed_count", default: 0, null: false
    t.datetime "started_at", null: false
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.index [ "locale", "status", "finished_at" ], name: "idx_platform_meta_template_refresh_status"
  end

  create_table "push_subscriptions", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.text "auth", null: false
    t.datetime "created_at", null: false
    t.text "endpoint", null: false
    t.string "endpoint_sha256", null: false
    t.integer "failure_count", default: 0, null: false
    t.text "last_error"
    t.datetime "last_failure_at"
    t.datetime "last_success_at"
    t.text "p256dh", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index [ "endpoint_sha256" ], name: "index_push_subscriptions_on_endpoint_sha256", unique: true
    t.index [ "user_id", "active" ], name: "index_push_subscriptions_on_user_id_and_active"
    t.index [ "user_id" ], name: "index_push_subscriptions_on_user_id"
  end

  create_table "registration_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "enabled", default: true, null: false
    t.integer "singleton_guard", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index [ "singleton_guard" ], name: "index_registration_settings_on_singleton_guard", unique: true
  end

  create_table "scheduling_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.integer "link_type", default: 0, null: false
    t.string "name"
    t.bigint "space_id", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.index [ "space_id" ], name: "index_scheduling_links_on_space_id"
    t.index [ "token" ], name: "index_scheduling_links_on_token", unique: true
  end

  create_table "space_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "space_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index [ "space_id" ], name: "index_space_memberships_on_space_id"
    t.index [ "user_id", "space_id" ], name: "index_space_memberships_on_user_id_and_space_id", unique: true
    t.index [ "user_id" ], name: "index_space_memberships_on_user_id"
  end

  create_table "spaces", force: :cascade do |t|
    t.text "address"
    t.boolean "appointment_automation_enabled", default: false, null: false
    t.text "booking_success_message"
    t.text "business_hours"
    t.jsonb "business_hours_schedule", default: {}
    t.string "business_type"
    t.integer "cancellation_min_hours_before"
    t.datetime "completed_onboarding_at"
    t.integer "confirmation_lead_hours", default: [ 24, 2 ], null: false, array: true
    t.time "confirmation_quiet_hours_end"
    t.time "confirmation_quiet_hours_start"
    t.datetime "created_at", null: false
    t.bigint "default_inbox_assignee_id"
    t.string "email"
    t.string "facebook_url"
    t.string "instagram_url"
    t.string "name", null: false
    t.datetime "onboarding_nudge_sent_at"
    t.integer "onboarding_step", default: 0, null: false
    t.bigint "owner_id"
    t.integer "personalized_slug_changes_count", default: 0, null: false
    t.datetime "personalized_slug_last_changed_at"
    t.string "phone"
    t.integer "request_max_days_ahead"
    t.integer "request_min_hours_ahead"
    t.integer "reschedule_min_hours_before"
    t.integer "slot_duration_minutes", default: 30, null: false
    t.string "timezone"
    t.datetime "updated_at", null: false
    t.index [ "appointment_automation_enabled" ], name: "index_spaces_on_appointment_automation_enabled", where: "(appointment_automation_enabled = true)"
    t.index [ "created_at" ], name: "index_spaces_on_created_at"
    t.index [ "default_inbox_assignee_id" ], name: "index_spaces_on_default_inbox_assignee_id"
    t.index [ "owner_id" ], name: "index_spaces_on_owner_id"
  end

  create_table "stored_files", force: :cascade do |t|
    t.bigint "attachable_id", null: false
    t.string "attachable_type", null: false
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.string "content_type", null: false
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "original_filename", null: false
    t.string "scope", null: false
    t.bigint "space_id"
    t.string "storage_adapter", null: false
    t.string "storage_path", null: false
    t.datetime "updated_at", null: false
    t.index [ "attachable_type", "attachable_id", "scope" ], name: "idx_on_attachable_type_attachable_id_scope_5b12b85fa5", unique: true
    t.index [ "attachable_type", "attachable_id" ], name: "index_stored_files_on_attachable"
    t.index [ "scope" ], name: "index_stored_files_on_scope"
    t.index [ "space_id", "scope" ], name: "index_stored_files_on_space_id_and_scope"
    t.index [ "space_id" ], name: "index_stored_files_on_space_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.string "asaas_customer_id"
    t.string "asaas_subscription_id"
    t.bigint "billing_plan_id", null: false
    t.bigint "billing_product_id", null: false
    t.datetime "canceled_at"
    t.datetime "created_at", null: false
    t.datetime "current_period_end"
    t.datetime "current_period_start"
    t.boolean "demo_automations_enabled", default: false, null: false
    t.integer "funding_source", default: 0, null: false
    t.integer "payment_method"
    t.bigint "pending_billing_plan_id"
    t.integer "platform_monthly_message_quota"
    t.bigint "space_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "trial_ends_at"
    t.datetime "updated_at", null: false
    t.index [ "asaas_subscription_id" ], name: "index_subscriptions_on_asaas_subscription_id", unique: true, where: "(asaas_subscription_id IS NOT NULL)"
    t.index [ "billing_plan_id" ], name: "index_subscriptions_on_billing_plan_id"
    t.index [ "billing_product_id" ], name: "index_subscriptions_on_billing_product_id"
    t.index [ "funding_source" ], name: "index_subscriptions_on_funding_source"
    t.index [ "pending_billing_plan_id" ], name: "index_subscriptions_on_pending_billing_plan_id"
    t.index [ "space_id", "billing_product_id" ], name: "index_subscriptions_on_space_product_active", unique: true, where: "(status <> 4)"
    t.index [ "space_id" ], name: "index_subscriptions_on_space_id"
    t.index [ "status", "trial_ends_at" ], name: "index_subscriptions_on_status_and_trial_ends_at"
    t.check_constraint "funding_source <> 1 OR asaas_customer_id IS NULL AND asaas_subscription_id IS NULL AND payment_method IS NULL", name: "chk_subscriptions_platform_demo_unwired"
    t.check_constraint "platform_monthly_message_quota IS NULL OR platform_monthly_message_quota >= 0", name: "chk_subscriptions_platform_monthly_quota_non_negative"
  end

  create_table "user_identities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.boolean "email_verified", default: false, null: false
    t.datetime "last_authenticated_at"
    t.jsonb "metadata", default: {}, null: false
    t.string "provider", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index [ "provider", "uid" ], name: "index_user_identities_on_provider_and_uid", unique: true
    t.index [ "user_id", "provider" ], name: "index_user_identities_on_user_id_and_provider", unique: true
    t.index [ "user_id" ], name: "index_user_identities_on_user_id"
  end

  create_table "user_passkeys", force: :cascade do |t|
    t.boolean "backup_eligible"
    t.boolean "backup_state"
    t.datetime "created_at", null: false
    t.string "external_id", null: false
    t.string "label", null: false
    t.datetime "last_used_at"
    t.boolean "platform_authenticator", default: false, null: false
    t.text "public_key", null: false
    t.string "rp_id", null: false
    t.bigint "sign_count", default: 0, null: false
    t.jsonb "transports", default: [], null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index [ "external_id" ], name: "index_user_passkeys_on_external_id", unique: true
    t.index [ "user_id", "rp_id" ], name: "index_user_passkeys_on_user_id_and_rp_id"
    t.index [ "user_id" ], name: "index_user_passkeys_on_user_id"
  end

  create_table "user_permissions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "permission", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index [ "user_id", "permission" ], name: "index_user_permissions_on_user_id_and_permission", unique: true
    t.index [ "user_id" ], name: "index_user_permissions_on_user_id"
  end

  create_table "user_preferences", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "dismissed_welcome_card", default: false, null: false
    t.string "locale", default: "pt-BR", null: false
    t.datetime "push_notifications_decided_at"
    t.datetime "push_notifications_disabled_at"
    t.boolean "push_notifications_enabled", default: false, null: false
    t.datetime "push_notifications_enabled_at"
    t.string "push_notifications_permission", default: "default", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index [ "user_id" ], name: "index_user_preferences_on_user_id", unique: true
  end

  create_table "user_recovery_codes", force: :cascade do |t|
    t.string "code_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.bigint "user_id", null: false
    t.index [ "user_id", "used_at" ], name: "index_user_recovery_codes_on_user_id_and_used_at"
    t.index [ "user_id" ], name: "index_user_recovery_codes_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.string "cpf_cnpj"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "last_mfa_at"
    t.datetime "mfa_enabled_at"
    t.string "name"
    t.string "phone_number"
    t.datetime "privacy_policy_accepted_at"
    t.string "privacy_policy_version"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", default: "", null: false
    t.integer "system_role"
    t.datetime "terms_of_service_accepted_at"
    t.string "terms_of_service_version"
    t.integer "totp_consumed_timestep"
    t.datetime "totp_enabled_at"
    t.datetime "totp_last_verified_at"
    t.string "totp_secret"
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.string "webauthn_id"
    t.index [ "confirmation_token" ], name: "index_users_on_confirmation_token", unique: true
    t.index [ "email" ], name: "index_users_on_email", unique: true
    t.index [ "phone_number" ], name: "index_users_on_phone_number", unique: true
    t.index [ "reset_password_token" ], name: "index_users_on_reset_password_token", unique: true
    t.index [ "webauthn_id" ], name: "index_users_on_webauthn_id", unique: true
  end

  create_table "whatsapp_contact_identities", force: :cascade do |t|
    t.string "business_portfolio_id"
    t.datetime "created_at", null: false
    t.bigint "customer_id"
    t.datetime "first_seen_at", null: false
    t.datetime "last_seen_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "parent_user_id"
    t.string "phone"
    t.string "profile_name"
    t.bigint "space_id", null: false
    t.datetime "updated_at", null: false
    t.string "user_id"
    t.string "username"
    t.string "wa_id"
    t.string "waba_id", null: false
    t.bigint "whatsapp_phone_number_id", null: false
    t.index [ "customer_id" ], name: "index_whatsapp_contact_identities_on_customer_id"
    t.index [ "space_id", "customer_id" ], name: "index_whatsapp_contact_identities_on_space_id_and_customer_id"
    t.index [ "space_id", "phone" ], name: "idx_whatsapp_contact_identities_on_space_phone", where: "(phone IS NOT NULL)"
    t.index [ "space_id", "whatsapp_phone_number_id", "parent_user_id" ], name: "idx_whatsapp_contact_identities_on_scoped_parent_user_id", unique: true, where: "(parent_user_id IS NOT NULL)"
    t.index [ "space_id", "whatsapp_phone_number_id", "user_id" ], name: "idx_whatsapp_contact_identities_on_scoped_user_id", unique: true, where: "(user_id IS NOT NULL)"
    t.index [ "space_id", "whatsapp_phone_number_id", "wa_id" ], name: "idx_whatsapp_contact_identities_on_scoped_wa_id", unique: true, where: "(wa_id IS NOT NULL)"
    t.index [ "space_id" ], name: "index_whatsapp_contact_identities_on_space_id"
    t.index [ "whatsapp_phone_number_id" ], name: "index_whatsapp_contact_identities_on_whatsapp_phone_number_id"
  end

  create_table "whatsapp_conversations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "customer_id"
    t.string "customer_name"
    t.string "customer_phone"
    t.string "external_user_id"
    t.string "external_user_id_type"
    t.datetime "last_message_at"
    t.datetime "session_expires_at"
    t.bigint "space_id", null: false
    t.boolean "unread", default: false, null: false
    t.datetime "updated_at", null: false
    t.string "wa_id"
    t.bigint "whatsapp_contact_identity_id"
    t.bigint "whatsapp_phone_number_id"
    t.index [ "customer_id" ], name: "index_whatsapp_conversations_on_customer_id"
    t.index [ "space_id", "wa_id" ], name: "index_whatsapp_conversations_on_space_id_and_wa_id", unique: true
    t.index [ "space_id", "whatsapp_phone_number_id", "external_user_id_type", "external_user_id" ], name: "idx_whatsapp_conversations_on_scoped_external_user", unique: true, where: "(external_user_id IS NOT NULL)"
    t.index [ "space_id" ], name: "index_whatsapp_conversations_on_space_id"
    t.index [ "whatsapp_contact_identity_id" ], name: "index_whatsapp_conversations_on_whatsapp_contact_identity_id"
    t.index [ "whatsapp_phone_number_id" ], name: "index_whatsapp_conversations_on_whatsapp_phone_number_id"
  end

  create_table "whatsapp_messages", force: :cascade do |t|
    t.bigint "appointment_reminder_id"
    t.text "body"
    t.datetime "created_at", null: false
    t.integer "direction", null: false
    t.string "message_type", default: "text", null: false
    t.jsonb "metadata", default: {}
    t.bigint "sent_by_id"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "wamid"
    t.bigint "whatsapp_conversation_id", null: false
    t.index [ "appointment_reminder_id" ], name: "index_whatsapp_messages_on_appointment_reminder_id"
    t.index [ "sent_by_id" ], name: "index_whatsapp_messages_on_sent_by_id"
    t.index [ "wamid" ], name: "index_whatsapp_messages_on_wamid", unique: true, where: "(wamid IS NOT NULL)"
    t.index [ "whatsapp_conversation_id" ], name: "index_whatsapp_messages_on_whatsapp_conversation_id"
  end

  create_table "whatsapp_phone_numbers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "display_number", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "normalized_phone"
    t.string "phone_number_id", null: false
    t.string "quality_rating"
    t.bigint "space_id"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "verified_name"
    t.string "waba_id", null: false
    t.index [ "normalized_phone" ], name: "index_whatsapp_phone_numbers_on_normalized_phone"
    t.index [ "phone_number_id" ], name: "index_whatsapp_phone_numbers_on_phone_number_id", unique: true
    t.index [ "space_id" ], name: "index_whatsapp_phone_numbers_on_space_id", unique: true, where: "(space_id IS NOT NULL)"
  end

  create_table "whatsapp_template_blueprints", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.text "body", null: false
    t.jsonb "buttons", default: [], null: false
    t.string "category", null: false
    t.jsonb "components", default: [], null: false
    t.datetime "created_at", null: false
    t.text "footer", default: "", null: false
    t.string "locale", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.jsonb "sample_values", default: {}, null: false
    t.datetime "updated_at", null: false
    t.jsonb "variables", default: [], null: false
    t.string "version", null: false
    t.index [ "active" ], name: "index_whatsapp_template_blueprints_on_active"
    t.index [ "name", "version", "locale" ], name: "idx_whatsapp_template_blueprints_identity", unique: true
  end

  create_table "whatsapp_templates", force: :cascade do |t|
    t.datetime "approved_at"
    t.text "body", null: false
    t.jsonb "buttons", default: [], null: false
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.text "footer", default: "", null: false
    t.boolean "has_request_contact_info_button", default: false, null: false
    t.text "last_error"
    t.datetime "last_synced_at"
    t.string "locale", null: false
    t.string "meta_category"
    t.string "meta_status", default: "NOT_REGISTERED", null: false
    t.string "meta_template_id"
    t.string "meta_template_name", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.jsonb "parameter_schema", default: {}, null: false
    t.text "rejected_reason"
    t.jsonb "remote_components", default: [], null: false
    t.jsonb "sample_values", default: {}, null: false
    t.string "source", default: "meta_synced", null: false
    t.bigint "space_id"
    t.datetime "submitted_at"
    t.boolean "supports_bsuid_recipient", default: false, null: false
    t.string "sync_mode", default: "read_only", null: false
    t.datetime "updated_at", null: false
    t.jsonb "variables", default: [], null: false
    t.string "version", null: false
    t.string "waba_id"
    t.bigint "whatsapp_phone_number_id"
    t.index [ "space_id", "meta_status" ], name: "idx_whatsapp_templates_space_status"
    t.index [ "space_id", "meta_template_name", "locale" ], name: "idx_whatsapp_templates_space_meta_locale", unique: true
    t.index [ "space_id", "name", "version", "locale" ], name: "idx_whatsapp_templates_space_identity", unique: true
    t.index [ "space_id", "source" ], name: "idx_whatsapp_templates_space_source"
    t.index [ "space_id" ], name: "index_whatsapp_templates_on_space_id"
    t.index [ "whatsapp_phone_number_id" ], name: "index_whatsapp_templates_on_whatsapp_phone_number_id"
  end

  add_foreign_key "account_deletion_requests", "users"
  add_foreign_key "anella_space_profiles", "spaces"
  add_foreign_key "appointment_events", "appointments"
  add_foreign_key "appointment_events", "spaces"
  add_foreign_key "appointment_reminders", "appointments"
  add_foreign_key "appointment_reminders", "spaces"
  add_foreign_key "appointments", "bookable_resources"
  add_foreign_key "appointments", "customers"
  add_foreign_key "appointments", "spaces"
  add_foreign_key "audit_logs", "spaces"
  add_foreign_key "audit_logs", "users", column: "actor_user_id"
  add_foreign_key "availability_windows", "availability_schedules"
  add_foreign_key "billing_coupon_redemption_cycles", "billing_coupon_redemptions", column: "coupon_redemption_id"
  add_foreign_key "billing_coupon_redemption_cycles", "payments"
  add_foreign_key "billing_coupon_redemptions", "billing_coupons", column: "coupon_id"
  add_foreign_key "billing_coupon_redemptions", "billing_products"
  add_foreign_key "billing_coupon_redemptions", "spaces"
  add_foreign_key "billing_coupon_redemptions", "subscriptions"
  add_foreign_key "billing_coupon_redemptions", "users", column: "actor_id"
  add_foreign_key "billing_coupons", "billing_products"
  add_foreign_key "billing_coupons", "users", column: "created_by_id"
  add_foreign_key "billing_coupons", "users", column: "updated_by_id"
  add_foreign_key "billing_credit_transactions", "spaces"
  add_foreign_key "billing_credit_transactions", "users", column: "actor_id"
  add_foreign_key "billing_events", "spaces"
  add_foreign_key "billing_events", "subscriptions"
  add_foreign_key "billing_plans", "billing_products"
  add_foreign_key "bookable_resources", "space_memberships"
  add_foreign_key "bookable_resources", "spaces"
  add_foreign_key "conversation_messages", "conversations"
  add_foreign_key "conversation_messages", "users", column: "sent_by_id"
  add_foreign_key "conversations", "customers"
  add_foreign_key "conversations", "spaces"
  add_foreign_key "conversations", "users", column: "assigned_to_id"
  add_foreign_key "credit_purchases", "credit_bundles"
  add_foreign_key "credit_purchases", "spaces"
  add_foreign_key "crm_public_profiles", "spaces"
  add_foreign_key "customers", "spaces"
  add_foreign_key "customers", "users"
  add_foreign_key "demo_scheduling_appointments", "spaces"
  add_foreign_key "message_credits", "spaces"
  add_foreign_key "messages", "users", column: "recipient_id"
  add_foreign_key "messages", "users", column: "sender_id"
  add_foreign_key "notifications", "users"
  add_foreign_key "payments", "spaces"
  add_foreign_key "payments", "subscriptions"
  add_foreign_key "personalized_scheduling_links", "spaces"
  add_foreign_key "push_subscriptions", "users"
  add_foreign_key "scheduling_links", "spaces"
  add_foreign_key "space_memberships", "spaces"
  add_foreign_key "space_memberships", "users"
  add_foreign_key "spaces", "users", column: "default_inbox_assignee_id"
  add_foreign_key "spaces", "users", column: "owner_id"
  add_foreign_key "stored_files", "spaces"
  add_foreign_key "subscriptions", "billing_plans"
  add_foreign_key "subscriptions", "billing_plans", column: "pending_billing_plan_id"
  add_foreign_key "subscriptions", "billing_products"
  add_foreign_key "subscriptions", "spaces"
  add_foreign_key "user_identities", "users"
  add_foreign_key "user_passkeys", "users"
  add_foreign_key "user_permissions", "users"
  add_foreign_key "user_preferences", "users"
  add_foreign_key "user_recovery_codes", "users"
  add_foreign_key "whatsapp_contact_identities", "customers"
  add_foreign_key "whatsapp_contact_identities", "spaces"
  add_foreign_key "whatsapp_contact_identities", "whatsapp_phone_numbers"
  add_foreign_key "whatsapp_conversations", "customers"
  add_foreign_key "whatsapp_conversations", "spaces"
  add_foreign_key "whatsapp_conversations", "whatsapp_contact_identities"
  add_foreign_key "whatsapp_conversations", "whatsapp_phone_numbers"
  add_foreign_key "whatsapp_messages", "appointment_reminders"
  add_foreign_key "whatsapp_messages", "users", column: "sent_by_id"
  add_foreign_key "whatsapp_messages", "whatsapp_conversations"
  add_foreign_key "whatsapp_phone_numbers", "spaces"
  add_foreign_key "whatsapp_templates", "spaces"
  add_foreign_key "whatsapp_templates", "whatsapp_phone_numbers"
end
