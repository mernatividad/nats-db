


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "board_pulse";


ALTER SCHEMA "board_pulse" OWNER TO "postgres";


CREATE SCHEMA IF NOT EXISTS "public";


ALTER SCHEMA "public" OWNER TO "pg_database_owner";


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE TYPE "public"."AdminRole" AS ENUM (
    'VIEWER',
    'EDITOR',
    'SUPER_ADMIN'
);


ALTER TYPE "public"."AdminRole" OWNER TO "postgres";


CREATE TYPE "public"."BlogWorkflowState" AS ENUM (
    'draft',
    'review',
    'published',
    'archived'
);


ALTER TYPE "public"."BlogWorkflowState" OWNER TO "postgres";


CREATE TYPE "public"."PrivacyRequestResolution" AS ENUM (
    'ANONYMIZED',
    'ERASED',
    'REJECTED'
);


ALTER TYPE "public"."PrivacyRequestResolution" OWNER TO "postgres";


CREATE TYPE "public"."PrivacyRequestStatus" AS ENUM (
    'OPEN',
    'IN_PROGRESS',
    'COMPLETED',
    'REJECTED'
);


ALTER TYPE "public"."PrivacyRequestStatus" OWNER TO "postgres";


CREATE TYPE "public"."PrivacyRequestType" AS ENUM (
    'ACCOUNT_DELETION',
    'CONTENT_ERASURE'
);


ALTER TYPE "public"."PrivacyRequestType" OWNER TO "postgres";


CREATE TYPE "public"."ReviewDisputeResolution" AS ENUM (
    'NO_ACTION',
    'ADD_CORRECTION_NOTE',
    'REMOVE_REVIEW'
);


ALTER TYPE "public"."ReviewDisputeResolution" OWNER TO "postgres";


CREATE TYPE "public"."ReviewDisputeStatus" AS ENUM (
    'OPEN',
    'UNDER_REVIEW',
    'RESOLVED'
);


ALTER TYPE "public"."ReviewDisputeStatus" OWNER TO "postgres";


CREATE TYPE "public"."ReviewModerationActionType" AS ENUM (
    'APPROVE',
    'FLAG',
    'REMOVE'
);


ALTER TYPE "public"."ReviewModerationActionType" OWNER TO "postgres";


CREATE TYPE "public"."TraderAuthTokenPurpose" AS ENUM (
    'EMAIL_VERIFICATION',
    'PASSWORD_RESET'
);


ALTER TYPE "public"."TraderAuthTokenPurpose" OWNER TO "postgres";


CREATE TYPE "public"."TraderReviewAppealResult" AS ENUM (
    'PENDING',
    'UPHELD',
    'OVERTURNED'
);


ALTER TYPE "public"."TraderReviewAppealResult" OWNER TO "postgres";


CREATE TYPE "public"."TraderReviewContext" AS ENUM (
    'CHALLENGE',
    'FUNDED',
    'BOTH'
);


ALTER TYPE "public"."TraderReviewContext" OWNER TO "postgres";


CREATE TYPE "public"."TraderReviewDenialReason" AS ENUM (
    'KYC_MISMATCH',
    'RULE_BREACH',
    'INCONSISTENT_ACTIVITY',
    'OTHER'
);


ALTER TYPE "public"."TraderReviewDenialReason" OWNER TO "postgres";


CREATE TYPE "public"."TraderReviewModerationStatus" AS ENUM (
    'pending_moderation',
    'published',
    'flagged',
    'removed'
);


ALTER TYPE "public"."TraderReviewModerationStatus" OWNER TO "postgres";


CREATE TYPE "public"."TraderReviewOutcome" AS ENUM (
    'PAID',
    'DENIED',
    'PENDING'
);


ALTER TYPE "public"."TraderReviewOutcome" OWNER TO "postgres";


CREATE TYPE "public"."TraderReviewPublicFlagReason" AS ENUM (
    'SPAM',
    'OFFENSIVE',
    'MISLEADING_CLAIM',
    'OFF_TOPIC',
    'OTHER'
);


ALTER TYPE "public"."TraderReviewPublicFlagReason" OWNER TO "postgres";


CREATE TYPE "public"."TraderReviewPublicFlagStatus" AS ENUM (
    'OPEN',
    'RESOLVED'
);


ALTER TYPE "public"."TraderReviewPublicFlagStatus" OWNER TO "postgres";


CREATE TYPE "public"."TraderReviewRevisionKind" AS ENUM (
    'INITIAL_SUBMISSION',
    'PENDING_RESOLUTION_UPDATE',
    'TRADER_EDIT'
);


ALTER TYPE "public"."TraderReviewRevisionKind" OWNER TO "postgres";


CREATE TYPE "public"."TraderReviewTradingStyle" AS ENUM (
    'SCALPING',
    'INTRADAY',
    'SWING',
    'ALGO',
    'DISCRETIONARY',
    'MIXED'
);


ALTER TYPE "public"."TraderReviewTradingStyle" OWNER TO "postgres";


CREATE TYPE "public"."TraderReviewVoteValue" AS ENUM (
    'HELPFUL',
    'NOT_HELPFUL'
);


ALTER TYPE "public"."TraderReviewVoteValue" OWNER TO "postgres";


CREATE TYPE "public"."TraderUserStatus" AS ENUM (
    'ACTIVE',
    'DISABLED',
    'ANONYMIZED'
);


ALTER TYPE "public"."TraderUserStatus" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "board_pulse"."touch_processed_articles_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  new.updated_at = now();
  return new;
end;
$$;


ALTER FUNCTION "board_pulse"."touch_processed_articles_updated_at"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "board_pulse"."alert_channels" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "alert_subscription_id" "uuid" NOT NULL,
    "channel" "text" NOT NULL,
    "email_subscriber_id" "uuid",
    "push_subscription_id" "uuid",
    "enabled" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "alert_channels_channel_check" CHECK (("channel" = ANY (ARRAY['email'::"text", 'push'::"text"]))),
    CONSTRAINT "alert_channels_check" CHECK (((("channel" = 'email'::"text") AND ("email_subscriber_id" IS NOT NULL) AND ("push_subscription_id" IS NULL)) OR (("channel" = 'push'::"text") AND ("push_subscription_id" IS NOT NULL) AND ("email_subscriber_id" IS NULL))))
);


ALTER TABLE "board_pulse"."alert_channels" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "board_pulse"."alert_subscriptions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "exam_id" "uuid" NOT NULL,
    "alert_type" "text" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "confirmed_at" timestamp with time zone,
    "cancelled_at" timestamp with time zone,
    "expires_at" timestamp with time zone,
    CONSTRAINT "alert_subscriptions_alert_type_check" CHECK (("alert_type" = ANY (ARRAY['result_release'::"text", 'name_match'::"text", 'room_assignment'::"text", 'application_deadline'::"text"]))),
    CONSTRAINT "alert_subscriptions_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'active'::"text", 'triggered'::"text", 'cancelled'::"text", 'expired'::"text"])))
);


ALTER TABLE "board_pulse"."alert_subscriptions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "board_pulse"."email_subscribers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "email" "text" NOT NULL,
    "email_normalized" "text" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "verification_token_hash" "text",
    "verified_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "unsubscribed_at" timestamp with time zone,
    CONSTRAINT "email_subscribers_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'verified'::"text", 'unsubscribed'::"text", 'bounced'::"text", 'complained'::"text"])))
);


ALTER TABLE "board_pulse"."email_subscribers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "board_pulse"."exams" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "slug" "text" NOT NULL,
    "category" "text" NOT NULL,
    "scheduled_date" "date" NOT NULL,
    "results_released_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "passers_pdf_url" "text",
    "top_notchers_pdf_url" "text"
);


ALTER TABLE "board_pulse"."exams" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "board_pulse"."name_alerts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "alert_subscription_id" "uuid" NOT NULL,
    "full_name" "text" NOT NULL,
    "normalized_name" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "board_pulse"."name_alerts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "board_pulse"."notification_deliveries" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "event_id" "uuid",
    "subscription_id" "uuid" NOT NULL,
    "channel" "text" NOT NULL,
    "destination_id" "uuid" NOT NULL,
    "status" "text" DEFAULT 'queued'::"text" NOT NULL,
    "attempt_count" integer DEFAULT 0 NOT NULL,
    "provider_message_id" "text",
    "payload" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "next_attempt_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "sent_at" timestamp with time zone,
    "failed_at" timestamp with time zone,
    "error" "text",
    CONSTRAINT "notification_deliveries_channel_check" CHECK (("channel" = ANY (ARRAY['email'::"text", 'push'::"text"]))),
    CONSTRAINT "notification_deliveries_status_check" CHECK (("status" = ANY (ARRAY['queued'::"text", 'sending'::"text", 'sent'::"text", 'failed'::"text", 'suppressed'::"text"])))
);


ALTER TABLE "board_pulse"."notification_deliveries" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "board_pulse"."notification_events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "exam_id" "uuid" NOT NULL,
    "event_type" "text" NOT NULL,
    "event_key" "text" NOT NULL,
    "payload" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "processed_at" timestamp with time zone
);


ALTER TABLE "board_pulse"."notification_events" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "board_pulse"."notification_settings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "scope" "text" NOT NULL,
    "exam_id" "uuid",
    "email_enabled" boolean DEFAULT true NOT NULL,
    "push_enabled" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "notification_settings_check" CHECK (((("scope" = 'global'::"text") AND ("exam_id" IS NULL)) OR (("scope" = 'exam'::"text") AND ("exam_id" IS NOT NULL)))),
    CONSTRAINT "notification_settings_scope_check" CHECK (("scope" = ANY (ARRAY['global'::"text", 'exam'::"text"])))
);


ALTER TABLE "board_pulse"."notification_settings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "board_pulse"."processed_articles" (
    "article_url" "text" NOT NULL,
    "exam_slug" "text",
    "run_id" "uuid",
    "processed_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "board_pulse"."processed_articles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "board_pulse"."push_subscriptions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "endpoint" "text" NOT NULL,
    "p256dh" "text" NOT NULL,
    "auth" "text" NOT NULL,
    "user_agent" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "last_used_at" timestamp with time zone,
    "revoked_at" timestamp with time zone
);


ALTER TABLE "board_pulse"."push_subscriptions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "board_pulse"."results" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "exam_id" "uuid" NOT NULL,
    "full_name" "text" NOT NULL,
    "school" "text" DEFAULT ''::"text" NOT NULL,
    "rating" numeric,
    "remarks" "text" NOT NULL,
    "rank" integer
);


ALTER TABLE "board_pulse"."results" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "board_pulse"."top_notchers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "exam_id" "uuid" NOT NULL,
    "rank" integer NOT NULL,
    "full_name" "text" NOT NULL,
    "school" "text" DEFAULT ''::"text" NOT NULL,
    "rating" numeric,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "board_pulse"."top_notchers" OWNER TO "postgres";


ALTER TABLE ONLY "board_pulse"."alert_channels"
    ADD CONSTRAINT "alert_channels_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "board_pulse"."alert_subscriptions"
    ADD CONSTRAINT "alert_subscriptions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "board_pulse"."email_subscribers"
    ADD CONSTRAINT "email_subscribers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "board_pulse"."exams"
    ADD CONSTRAINT "exams_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "board_pulse"."exams"
    ADD CONSTRAINT "exams_slug_key" UNIQUE ("slug");



ALTER TABLE ONLY "board_pulse"."name_alerts"
    ADD CONSTRAINT "name_alerts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "board_pulse"."notification_deliveries"
    ADD CONSTRAINT "notification_deliveries_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "board_pulse"."notification_events"
    ADD CONSTRAINT "notification_events_event_key_key" UNIQUE ("event_key");



ALTER TABLE ONLY "board_pulse"."notification_events"
    ADD CONSTRAINT "notification_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "board_pulse"."notification_settings"
    ADD CONSTRAINT "notification_settings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "board_pulse"."processed_articles"
    ADD CONSTRAINT "processed_articles_pkey" PRIMARY KEY ("article_url");



ALTER TABLE ONLY "board_pulse"."push_subscriptions"
    ADD CONSTRAINT "push_subscriptions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "board_pulse"."results"
    ADD CONSTRAINT "results_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "board_pulse"."top_notchers"
    ADD CONSTRAINT "top_notchers_pkey" PRIMARY KEY ("id");



CREATE INDEX "alert_channels_subscription_idx" ON "board_pulse"."alert_channels" USING "btree" ("alert_subscription_id", "enabled");



CREATE INDEX "alert_subscriptions_exam_status_idx" ON "board_pulse"."alert_subscriptions" USING "btree" ("exam_id", "alert_type", "status");



CREATE UNIQUE INDEX "email_subscribers_email_normalized_key" ON "board_pulse"."email_subscribers" USING "btree" ("email_normalized");



CREATE INDEX "name_alerts_normalized_name_idx" ON "board_pulse"."name_alerts" USING "btree" ("normalized_name");



CREATE INDEX "notification_deliveries_queue_idx" ON "board_pulse"."notification_deliveries" USING "btree" ("status", "next_attempt_at");



CREATE INDEX "notification_events_unprocessed_idx" ON "board_pulse"."notification_events" USING "btree" ("created_at") WHERE ("processed_at" IS NULL);



CREATE UNIQUE INDEX "notification_settings_exam_key" ON "board_pulse"."notification_settings" USING "btree" ("exam_id") WHERE ("scope" = 'exam'::"text");



CREATE UNIQUE INDEX "notification_settings_global_key" ON "board_pulse"."notification_settings" USING "btree" ("scope") WHERE ("scope" = 'global'::"text");



CREATE UNIQUE INDEX "push_subscriptions_endpoint_key" ON "board_pulse"."push_subscriptions" USING "btree" ("endpoint");



CREATE UNIQUE INDEX "results_exam_full_name_school_key" ON "board_pulse"."results" USING "btree" ("exam_id", "full_name", "school");



CREATE UNIQUE INDEX "top_notchers_exam_full_name_key" ON "board_pulse"."top_notchers" USING "btree" ("exam_id", "full_name");



CREATE INDEX "top_notchers_exam_rank_idx" ON "board_pulse"."top_notchers" USING "btree" ("exam_id", "rank");



CREATE OR REPLACE TRIGGER "trg_processed_articles_updated_at" BEFORE UPDATE ON "board_pulse"."processed_articles" FOR EACH ROW EXECUTE FUNCTION "board_pulse"."touch_processed_articles_updated_at"();



ALTER TABLE ONLY "board_pulse"."alert_channels"
    ADD CONSTRAINT "alert_channels_alert_subscription_id_fkey" FOREIGN KEY ("alert_subscription_id") REFERENCES "board_pulse"."alert_subscriptions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "board_pulse"."alert_channels"
    ADD CONSTRAINT "alert_channels_email_subscriber_id_fkey" FOREIGN KEY ("email_subscriber_id") REFERENCES "board_pulse"."email_subscribers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "board_pulse"."alert_channels"
    ADD CONSTRAINT "alert_channels_push_subscription_id_fkey" FOREIGN KEY ("push_subscription_id") REFERENCES "board_pulse"."push_subscriptions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "board_pulse"."alert_subscriptions"
    ADD CONSTRAINT "alert_subscriptions_exam_id_fkey" FOREIGN KEY ("exam_id") REFERENCES "board_pulse"."exams"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "board_pulse"."name_alerts"
    ADD CONSTRAINT "name_alerts_alert_subscription_id_fkey" FOREIGN KEY ("alert_subscription_id") REFERENCES "board_pulse"."alert_subscriptions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "board_pulse"."notification_deliveries"
    ADD CONSTRAINT "notification_deliveries_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "board_pulse"."notification_events"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "board_pulse"."notification_deliveries"
    ADD CONSTRAINT "notification_deliveries_subscription_id_fkey" FOREIGN KEY ("subscription_id") REFERENCES "board_pulse"."alert_subscriptions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "board_pulse"."notification_events"
    ADD CONSTRAINT "notification_events_exam_id_fkey" FOREIGN KEY ("exam_id") REFERENCES "board_pulse"."exams"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "board_pulse"."notification_settings"
    ADD CONSTRAINT "notification_settings_exam_id_fkey" FOREIGN KEY ("exam_id") REFERENCES "board_pulse"."exams"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "board_pulse"."results"
    ADD CONSTRAINT "results_exam_id_fkey" FOREIGN KEY ("exam_id") REFERENCES "board_pulse"."exams"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "board_pulse"."top_notchers"
    ADD CONSTRAINT "top_notchers_exam_id_fkey" FOREIGN KEY ("exam_id") REFERENCES "board_pulse"."exams"("id") ON DELETE CASCADE;



ALTER TABLE "board_pulse"."alert_channels" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "board_pulse"."alert_subscriptions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "board_pulse"."email_subscribers" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "board_pulse"."exams" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "board_pulse"."name_alerts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "board_pulse"."notification_deliveries" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "board_pulse"."notification_events" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "board_pulse"."notification_settings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "board_pulse"."processed_articles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "public can read exams" ON "board_pulse"."exams" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "public can read results" ON "board_pulse"."results" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "public can read top notchers" ON "board_pulse"."top_notchers" FOR SELECT TO "authenticated", "anon" USING (true);



ALTER TABLE "board_pulse"."push_subscriptions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "board_pulse"."results" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "service role manages alert channels" ON "board_pulse"."alert_channels" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "service role manages alert subscriptions" ON "board_pulse"."alert_subscriptions" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "service role manages email subscribers" ON "board_pulse"."email_subscribers" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "service role manages name alerts" ON "board_pulse"."name_alerts" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "service role manages notification deliveries" ON "board_pulse"."notification_deliveries" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "service role manages notification events" ON "board_pulse"."notification_events" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "service role manages notification settings" ON "board_pulse"."notification_settings" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "service role manages push subscriptions" ON "board_pulse"."push_subscriptions" TO "service_role" USING (true) WITH CHECK (true);



ALTER TABLE "board_pulse"."top_notchers" ENABLE ROW LEVEL SECURITY;


GRANT USAGE ON SCHEMA "board_pulse" TO "anon";
GRANT USAGE ON SCHEMA "board_pulse" TO "authenticated";
GRANT USAGE ON SCHEMA "board_pulse" TO "service_role";



GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "board_pulse"."alert_channels" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "board_pulse"."alert_subscriptions" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "board_pulse"."email_subscribers" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "board_pulse"."exams" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "board_pulse"."exams" TO "authenticated";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "board_pulse"."exams" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "board_pulse"."name_alerts" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "board_pulse"."notification_deliveries" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "board_pulse"."notification_events" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "board_pulse"."notification_settings" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "board_pulse"."processed_articles" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "board_pulse"."push_subscriptions" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "board_pulse"."results" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "board_pulse"."results" TO "authenticated";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "board_pulse"."results" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "board_pulse"."top_notchers" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "board_pulse"."top_notchers" TO "authenticated";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "board_pulse"."top_notchers" TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";







