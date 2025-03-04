--
-- PostgreSQL database dump
--

-- Dumped from database version 15.8
-- Dumped by pg_dump version 17.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO pg_database_owner;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: approval_status_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.approval_status_type AS ENUM (
    'pending',
    'approved',
    'rejected'
);


ALTER TYPE public.approval_status_type OWNER TO postgres;

--
-- Name: article_category_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.article_category_type AS ENUM (
    'general',
    'product',
    'service',
    'troubleshooting',
    'faq',
    'policy',
    'other'
);


ALTER TYPE public.article_category_type OWNER TO postgres;

--
-- Name: article_status_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.article_status_type AS ENUM (
    'draft',
    'pending_approval',
    'approved',
    'rejected',
    'archived'
);


ALTER TYPE public.article_status_type OWNER TO postgres;

--
-- Name: department_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.department_type AS ENUM (
    'sales',
    'marketing',
    'support',
    'engineering',
    'other'
);


ALTER TYPE public.department_type OWNER TO postgres;

--
-- Name: message_sender_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.message_sender_type AS ENUM (
    'employee',
    'customer'
);


ALTER TYPE public.message_sender_type OWNER TO postgres;

--
-- Name: permission_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.permission_type AS ENUM (
    'super_admin',
    'admin',
    'manager',
    'agent'
);


ALTER TYPE public.permission_type OWNER TO postgres;

--
-- Name: shift_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.shift_type AS ENUM (
    'morning',
    'afternoon',
    'evening',
    'night'
);


ALTER TYPE public.shift_type OWNER TO postgres;

--
-- Name: ticket_category_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.ticket_category_type AS ENUM (
    'general',
    'billing',
    'technical',
    'feedback',
    'account',
    'feature_request',
    'other'
);


ALTER TYPE public.ticket_category_type OWNER TO postgres;

--
-- Name: ticket_priority_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.ticket_priority_type AS ENUM (
    'low',
    'medium',
    'high',
    'critical'
);


ALTER TYPE public.ticket_priority_type OWNER TO postgres;

--
-- Name: ticket_status_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.ticket_status_type AS ENUM (
    'fresh',
    'in_progress',
    'closed'
);


ALTER TYPE public.ticket_status_type OWNER TO postgres;

--
-- Name: handle_new_user(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.handle_new_user() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$

BEGIN

  INSERT INTO public.customers (id)

  VALUES (new.id);

  RETURN new;

END;

$$;


ALTER FUNCTION public.handle_new_user() OWNER TO postgres;

--
-- Name: increment_article_view_count(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.increment_article_view_count(article_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    UPDATE articles
    SET view_count = view_count + 1
    WHERE id = article_id;
END;
$$;


ALTER FUNCTION public.increment_article_view_count(article_id uuid) OWNER TO postgres;

--
-- Name: refresh_employee_metrics(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.refresh_employee_metrics() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY employee_performance_metrics;
EXCEPTION 
    WHEN OTHERS THEN
        REFRESH MATERIALIZED VIEW employee_performance_metrics;
END;
$$;


ALTER FUNCTION public.refresh_employee_metrics() OWNER TO postgres;

--
-- Name: refresh_employee_metrics_trigger(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.refresh_employee_metrics_trigger() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
    PERFORM refresh_employee_metrics();
    RETURN NULL;
END;
$$;


ALTER FUNCTION public.refresh_employee_metrics_trigger() OWNER TO postgres;

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN

    NEW.updated_at = CURRENT_TIMESTAMP;

    RETURN NEW;

END;

$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: approval_requests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.approval_requests (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    article_id uuid NOT NULL,
    version_id uuid NOT NULL,
    submitted_by uuid NOT NULL,
    submitted_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    reviewed_by uuid,
    reviewed_at timestamp with time zone,
    status public.approval_status_type DEFAULT 'pending'::public.approval_status_type,
    feedback text
);


ALTER TABLE public.approval_requests OWNER TO postgres;

--
-- Name: article_notes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.article_notes (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    article_id uuid NOT NULL,
    content text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    created_by uuid DEFAULT auth.uid() NOT NULL
);


ALTER TABLE public.article_notes OWNER TO postgres;

--
-- Name: article_tags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.article_tags (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    article_id uuid NOT NULL,
    tag text NOT NULL
);


ALTER TABLE public.article_tags OWNER TO postgres;

--
-- Name: article_versions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.article_versions (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    article_id uuid NOT NULL,
    title text NOT NULL,
    description text,
    content text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    created_by uuid NOT NULL,
    version_number integer NOT NULL,
    change_summary text
);


ALTER TABLE public.article_versions OWNER TO postgres;

--
-- Name: articles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.articles (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    title text NOT NULL,
    description text,
    content text NOT NULL,
    status public.article_status_type DEFAULT 'draft'::public.article_status_type,
    created_by uuid NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    published_at timestamp with time zone,
    view_count integer DEFAULT 0,
    is_faq boolean DEFAULT false,
    category public.article_category_type DEFAULT 'general'::public.article_category_type,
    slug text NOT NULL
);


ALTER TABLE public.articles OWNER TO postgres;

--
-- Name: customers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.customers (
    id uuid NOT NULL,
    product_interests text[] DEFAULT ARRAY[]::text[],
    is_registered boolean DEFAULT true
);


ALTER TABLE public.customers OWNER TO postgres;

--
-- Name: employees; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.employees (
    id uuid NOT NULL,
    permissions public.permission_type NOT NULL,
    department public.department_type NOT NULL,
    shift public.shift_type NOT NULL,
    description text
);


ALTER TABLE public.employees OWNER TO postgres;

--
-- Name: employee_profiles; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.employee_profiles AS
 SELECT e.id,
    e.permissions,
    e.department,
    e.shift,
    e.description,
    (u.raw_user_meta_data ->> 'full_name'::text) AS full_name
   FROM (public.employees e
     JOIN auth.users u ON ((u.id = e.id)));


ALTER VIEW public.employee_profiles OWNER TO postgres;

--
-- Name: messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.messages (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    ticket_id uuid NOT NULL,
    created_by uuid NOT NULL,
    sender_type public.message_sender_type NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    message text NOT NULL,
    is_system_message boolean DEFAULT false
);


ALTER TABLE public.messages OWNER TO postgres;

--
-- Name: tickets; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tickets (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    name text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    resolved boolean DEFAULT false,
    status public.ticket_status_type DEFAULT 'fresh'::public.ticket_status_type,
    priority public.ticket_priority_type DEFAULT 'low'::public.ticket_priority_type,
    category public.ticket_category_type DEFAULT 'general'::public.ticket_category_type,
    assigned_to uuid,
    created_by uuid NOT NULL
);


ALTER TABLE public.tickets OWNER TO postgres;

--
-- Name: employee_performance_metrics; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW public.employee_performance_metrics AS
 WITH all_employees AS (
         SELECT employees.id AS employee_id
           FROM public.employees
        UNION
         SELECT tickets.assigned_to
           FROM public.tickets
          WHERE (tickets.assigned_to IS NOT NULL)
        UNION
         SELECT articles.created_by
           FROM public.articles
          WHERE (articles.created_by IS NOT NULL)
        ), ticket_counts AS (
         SELECT tickets.assigned_to AS employee_id,
            tickets.priority,
            tickets.category,
            count(*) AS count,
            count(*) FILTER (WHERE (tickets.resolved = true)) AS resolved_count,
            count(*) FILTER (WHERE (tickets.resolved = false)) AS unresolved_count,
            avg(
                CASE
                    WHEN (tickets.resolved = true) THEN EXTRACT(epoch FROM (tickets.updated_at - tickets.created_at))
                    ELSE NULL::numeric
                END) AS avg_resolution_seconds
           FROM public.tickets
          WHERE (tickets.assigned_to IS NOT NULL)
          GROUP BY tickets.assigned_to, tickets.priority, tickets.category
        ), priority_counts AS (
         SELECT ticket_counts.employee_id,
            ticket_counts.priority,
            sum(ticket_counts.count) AS count
           FROM ticket_counts
          GROUP BY ticket_counts.employee_id, ticket_counts.priority
        ), category_counts AS (
         SELECT ticket_counts.employee_id,
            ticket_counts.category,
            sum(ticket_counts.count) AS count
           FROM ticket_counts
          GROUP BY ticket_counts.employee_id, ticket_counts.category
        ), ticket_metrics AS (
         SELECT tc.employee_id,
            sum(tc.count) AS total_tickets_assigned,
            sum(tc.resolved_count) AS total_tickets_resolved,
            sum(tc.unresolved_count) AS current_open_tickets,
            make_interval(secs => (avg(tc.avg_resolution_seconds))::double precision) AS avg_resolution_time,
            ( SELECT jsonb_object_agg(pc.priority, pc.count) AS jsonb_object_agg
                   FROM priority_counts pc
                  WHERE (pc.employee_id = tc.employee_id)) AS tickets_by_priority,
            ( SELECT jsonb_object_agg(cc.category, cc.count) AS jsonb_object_agg
                   FROM category_counts cc
                  WHERE (cc.employee_id = tc.employee_id)) AS tickets_by_category
           FROM ticket_counts tc
          GROUP BY tc.employee_id
        ), first_responses AS (
         SELECT t.id AS ticket_id,
            t.assigned_to AS employee_id,
            t.created_at AS ticket_created_at,
            min(m.created_at) AS first_response_at
           FROM (public.tickets t
             JOIN public.messages m ON (((t.id = m.ticket_id) AND (m.sender_type = 'employee'::public.message_sender_type))))
          WHERE (t.assigned_to IS NOT NULL)
          GROUP BY t.id, t.assigned_to, t.created_at
        ), response_metrics AS (
         SELECT t.assigned_to AS employee_id,
            make_interval(secs => (avg(EXTRACT(epoch FROM (fr.first_response_at - fr.ticket_created_at))))::double precision) AS avg_first_response_time,
            ( SELECT count(*) AS count
                   FROM (public.messages m2
                     JOIN public.tickets t2 ON ((m2.ticket_id = t2.id)))
                  WHERE ((t2.assigned_to = t.assigned_to) AND (m2.sender_type = 'employee'::public.message_sender_type))) AS total_messages_sent,
            round((( SELECT (count(*))::numeric AS count
                   FROM (public.messages m2
                     JOIN public.tickets t2 ON ((m2.ticket_id = t2.id)))
                  WHERE ((t2.assigned_to = t.assigned_to) AND (m2.sender_type = 'employee'::public.message_sender_type))) / (NULLIF(count(DISTINCT t.id), 0))::numeric), 2) AS avg_messages_per_ticket
           FROM (public.tickets t
             LEFT JOIN first_responses fr ON ((t.id = fr.ticket_id)))
          WHERE (t.assigned_to IS NOT NULL)
          GROUP BY t.assigned_to
        ), article_counts AS (
         SELECT articles.created_by AS employee_id,
            articles.category,
            count(*) AS count,
            count(*) FILTER (WHERE (articles.status = 'approved'::public.article_status_type)) AS approved_count,
            count(*) FILTER (WHERE (articles.status = ANY (ARRAY['approved'::public.article_status_type, 'rejected'::public.article_status_type]))) AS reviewed_count,
            sum(articles.view_count) AS total_views
           FROM public.articles
          GROUP BY articles.created_by, articles.category
        ), article_category_counts AS (
         SELECT article_counts.employee_id,
            article_counts.category,
            sum(article_counts.count) AS count
           FROM article_counts
          GROUP BY article_counts.employee_id, article_counts.category
        ), kb_metrics AS (
         SELECT ac.employee_id,
            sum(ac.count) AS total_articles_created,
            sum(ac.approved_count) AS total_articles_published,
            round(((sum(ac.approved_count) / NULLIF(sum(ac.reviewed_count), (0)::numeric)) * (100)::numeric), 2) AS article_approval_rate,
            sum(ac.total_views) AS total_article_views,
            ( SELECT jsonb_object_agg(acc.category, acc.count) AS jsonb_object_agg
                   FROM article_category_counts acc
                  WHERE (acc.employee_id = ac.employee_id)) AS articles_by_category
           FROM article_counts ac
          GROUP BY ac.employee_id
        ), monthly_metrics AS (
         SELECT t.assigned_to AS employee_id,
            count(*) FILTER (WHERE ((t.resolved = true) AND (t.updated_at >= (now() - '30 days'::interval)))) AS monthly_tickets_resolved,
            count(*) FILTER (WHERE (t.created_at >= (now() - '30 days'::interval))) AS monthly_tickets_total,
            round((((count(*) FILTER (WHERE (EXISTS ( SELECT 1
                   FROM public.messages m
                  WHERE ((m.ticket_id = t.id) AND (m.sender_type = 'employee'::public.message_sender_type) AND (m.created_at >= (now() - '30 days'::interval)))))))::numeric / (NULLIF(count(*) FILTER (WHERE (t.created_at >= (now() - '30 days'::interval))), 0))::numeric) * (100)::numeric), 2) AS monthly_response_rate
           FROM public.tickets t
          WHERE (t.assigned_to IS NOT NULL)
          GROUP BY t.assigned_to
        )
 SELECT ae.employee_id,
    ep.full_name,
    e.department,
    COALESCE(tm.total_tickets_assigned, (0)::numeric) AS total_tickets_assigned,
    COALESCE(tm.total_tickets_resolved, (0)::numeric) AS total_tickets_resolved,
    COALESCE(tm.current_open_tickets, (0)::numeric) AS current_open_tickets,
    tm.avg_resolution_time,
    COALESCE(tm.tickets_by_priority, '{}'::jsonb) AS tickets_by_priority,
    COALESCE(tm.tickets_by_category, '{}'::jsonb) AS tickets_by_category,
    rm.avg_first_response_time,
    COALESCE(rm.total_messages_sent, (0)::bigint) AS total_messages_sent,
    COALESCE(rm.avg_messages_per_ticket, (0)::numeric) AS avg_messages_per_ticket,
    COALESCE(kb.total_articles_created, (0)::numeric) AS total_articles_created,
    COALESCE(kb.total_articles_published, (0)::numeric) AS total_articles_published,
    COALESCE(kb.article_approval_rate, (0)::numeric) AS article_approval_rate,
    COALESCE(kb.total_article_views, (0)::numeric) AS total_article_views,
    COALESCE(kb.articles_by_category, '{}'::jsonb) AS articles_by_category,
    COALESCE(mm.monthly_tickets_resolved, (0)::bigint) AS monthly_tickets_resolved,
    COALESCE(mm.monthly_response_rate, (0)::numeric) AS monthly_response_rate
   FROM ((((((all_employees ae
     LEFT JOIN public.employees e ON ((ae.employee_id = e.id)))
     LEFT JOIN public.employee_profiles ep ON ((ae.employee_id = ep.id)))
     LEFT JOIN ticket_metrics tm ON ((ae.employee_id = tm.employee_id)))
     LEFT JOIN response_metrics rm ON ((ae.employee_id = rm.employee_id)))
     LEFT JOIN kb_metrics kb ON ((ae.employee_id = kb.employee_id)))
     LEFT JOIN monthly_metrics mm ON ((ae.employee_id = mm.employee_id)))
  WITH NO DATA;


ALTER MATERIALIZED VIEW public.employee_performance_metrics OWNER TO postgres;

--
-- Name: MATERIALIZED VIEW employee_performance_metrics; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON MATERIALIZED VIEW public.employee_performance_metrics IS 'Comprehensive employee performance metrics including ticket handling, response times, and knowledge base contributions';


--
-- Name: ticket_notes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ticket_notes (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    ticket_id uuid NOT NULL,
    content text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    created_by uuid NOT NULL
);


ALTER TABLE public.ticket_notes OWNER TO postgres;

--
-- Name: approval_requests approval_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.approval_requests
    ADD CONSTRAINT approval_requests_pkey PRIMARY KEY (id);


--
-- Name: article_notes article_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.article_notes
    ADD CONSTRAINT article_notes_pkey PRIMARY KEY (id);


--
-- Name: article_tags article_tags_article_id_tag_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.article_tags
    ADD CONSTRAINT article_tags_article_id_tag_key UNIQUE (article_id, tag);


--
-- Name: article_tags article_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.article_tags
    ADD CONSTRAINT article_tags_pkey PRIMARY KEY (id);


--
-- Name: article_versions article_versions_article_id_version_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.article_versions
    ADD CONSTRAINT article_versions_article_id_version_number_key UNIQUE (article_id, version_number);


--
-- Name: article_versions article_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.article_versions
    ADD CONSTRAINT article_versions_pkey PRIMARY KEY (id);


--
-- Name: articles articles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.articles
    ADD CONSTRAINT articles_pkey PRIMARY KEY (id);


--
-- Name: articles articles_slug_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.articles
    ADD CONSTRAINT articles_slug_key UNIQUE (slug);


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (id);


--
-- Name: employees employees_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: ticket_notes ticket_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ticket_notes
    ADD CONSTRAINT ticket_notes_pkey PRIMARY KEY (id);


--
-- Name: tickets tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_pkey PRIMARY KEY (id);


--
-- Name: employee_metrics_employee_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX employee_metrics_employee_id_idx ON public.employee_performance_metrics USING btree (employee_id);


--
-- Name: idx_articles_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_articles_created_by ON public.articles USING btree (created_by);


--
-- Name: idx_articles_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_articles_status ON public.articles USING btree (status);


--
-- Name: idx_messages_sender_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_messages_sender_type ON public.messages USING btree (sender_type);


--
-- Name: idx_messages_ticket_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_messages_ticket_id ON public.messages USING btree (ticket_id);


--
-- Name: idx_tickets_assigned_to; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tickets_assigned_to ON public.tickets USING btree (assigned_to);


--
-- Name: idx_tickets_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tickets_created_at ON public.tickets USING btree (created_at);


--
-- Name: idx_tickets_resolved; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tickets_resolved ON public.tickets USING btree (resolved);


--
-- Name: idx_tickets_updated_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tickets_updated_at ON public.tickets USING btree (updated_at);


--
-- Name: articles refresh_employee_metrics_articles; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER refresh_employee_metrics_articles AFTER INSERT OR DELETE OR UPDATE ON public.articles FOR EACH STATEMENT EXECUTE FUNCTION public.refresh_employee_metrics_trigger();


--
-- Name: employees refresh_employee_metrics_employees; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER refresh_employee_metrics_employees AFTER INSERT OR DELETE OR UPDATE ON public.employees FOR EACH STATEMENT EXECUTE FUNCTION public.refresh_employee_metrics_trigger();


--
-- Name: messages refresh_employee_metrics_messages; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER refresh_employee_metrics_messages AFTER INSERT OR DELETE OR UPDATE ON public.messages FOR EACH STATEMENT EXECUTE FUNCTION public.refresh_employee_metrics_trigger();


--
-- Name: tickets refresh_employee_metrics_tickets; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER refresh_employee_metrics_tickets AFTER INSERT OR DELETE OR UPDATE ON public.tickets FOR EACH STATEMENT EXECUTE FUNCTION public.refresh_employee_metrics_trigger();


--
-- Name: approval_requests approval_requests_article_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.approval_requests
    ADD CONSTRAINT approval_requests_article_id_fkey FOREIGN KEY (article_id) REFERENCES public.articles(id) ON DELETE CASCADE;


--
-- Name: approval_requests approval_requests_reviewed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.approval_requests
    ADD CONSTRAINT approval_requests_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES auth.users(id);


--
-- Name: approval_requests approval_requests_submitted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.approval_requests
    ADD CONSTRAINT approval_requests_submitted_by_fkey FOREIGN KEY (submitted_by) REFERENCES auth.users(id);


--
-- Name: approval_requests approval_requests_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.approval_requests
    ADD CONSTRAINT approval_requests_version_id_fkey FOREIGN KEY (version_id) REFERENCES public.article_versions(id) ON DELETE CASCADE;


--
-- Name: article_notes article_notes_article_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.article_notes
    ADD CONSTRAINT article_notes_article_id_fkey FOREIGN KEY (article_id) REFERENCES public.articles(id) ON DELETE CASCADE;


--
-- Name: article_notes article_notes_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.article_notes
    ADD CONSTRAINT article_notes_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);


--
-- Name: article_tags article_tags_article_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.article_tags
    ADD CONSTRAINT article_tags_article_id_fkey FOREIGN KEY (article_id) REFERENCES public.articles(id) ON DELETE CASCADE;


--
-- Name: article_versions article_versions_article_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.article_versions
    ADD CONSTRAINT article_versions_article_id_fkey FOREIGN KEY (article_id) REFERENCES public.articles(id) ON DELETE CASCADE;


--
-- Name: article_versions article_versions_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.article_versions
    ADD CONSTRAINT article_versions_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);


--
-- Name: articles articles_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.articles
    ADD CONSTRAINT articles_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);


--
-- Name: customers customers_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id);


--
-- Name: employees employees_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id);


--
-- Name: messages messages_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);


--
-- Name: messages messages_ticket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.tickets(id);


--
-- Name: ticket_notes ticket_notes_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ticket_notes
    ADD CONSTRAINT ticket_notes_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);


--
-- Name: ticket_notes ticket_notes_ticket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ticket_notes
    ADD CONSTRAINT ticket_notes_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.tickets(id) ON DELETE CASCADE;


--
-- Name: tickets tickets_assigned_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES auth.users(id);


--
-- Name: tickets tickets_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);


--
-- Name: employees Anyone can read employee records; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Anyone can read employee records" ON public.employees FOR SELECT USING (true);


--
-- Name: messages Anyone can read messages; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Anyone can read messages" ON public.messages FOR SELECT USING (true);


--
-- Name: tickets Anyone can read tickets; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Anyone can read tickets" ON public.tickets FOR SELECT USING (true);


--
-- Name: messages Authenticated users can create messages; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Authenticated users can create messages" ON public.messages FOR INSERT WITH CHECK ((auth.role() = 'authenticated'::text));


--
-- Name: tickets Authenticated users can create tickets; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Authenticated users can create tickets" ON public.tickets FOR INSERT WITH CHECK ((auth.role() = 'authenticated'::text));


--
-- Name: messages Message creators and ticket owners can update messages; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Message creators and ticket owners can update messages" ON public.messages FOR UPDATE USING (((auth.uid() = created_by) OR (EXISTS ( SELECT 1
   FROM public.tickets
  WHERE ((tickets.id = messages.ticket_id) AND ((tickets.created_by = auth.uid()) OR (tickets.assigned_to = auth.uid()))))) OR (EXISTS ( SELECT 1
   FROM public.employees
  WHERE ((employees.id = auth.uid()) AND (employees.permissions = ANY (ARRAY['manager'::public.permission_type, 'admin'::public.permission_type, 'super_admin'::public.permission_type])))))));


--
-- Name: messages Only managers and admins can delete messages; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Only managers and admins can delete messages" ON public.messages FOR DELETE USING ((EXISTS ( SELECT 1
   FROM public.employees
  WHERE ((employees.id = auth.uid()) AND (employees.permissions = ANY (ARRAY['manager'::public.permission_type, 'admin'::public.permission_type, 'super_admin'::public.permission_type]))))));


--
-- Name: tickets Only managers and admins can delete tickets; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Only managers and admins can delete tickets" ON public.tickets FOR DELETE USING ((EXISTS ( SELECT 1
   FROM public.employees
  WHERE ((employees.id = auth.uid()) AND (employees.permissions = ANY (ARRAY['manager'::public.permission_type, 'admin'::public.permission_type, 'super_admin'::public.permission_type]))))));


--
-- Name: tickets Ticket creators and assignees can update tickets; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Ticket creators and assignees can update tickets" ON public.tickets FOR UPDATE USING (((auth.uid() = created_by) OR (auth.uid() = assigned_to) OR (EXISTS ( SELECT 1
   FROM public.employees
  WHERE ((employees.id = auth.uid()) AND (employees.permissions = ANY (ARRAY['manager'::public.permission_type, 'admin'::public.permission_type, 'super_admin'::public.permission_type])))))));


--
-- Name: employees Users can delete own employee record; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can delete own employee record" ON public.employees FOR DELETE USING ((auth.uid() = id));


--
-- Name: employees Users can insert own employee record; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can insert own employee record" ON public.employees FOR INSERT WITH CHECK ((auth.uid() = id));


--
-- Name: employees Users can update own employee record; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can update own employee record" ON public.employees FOR UPDATE USING ((auth.uid() = id)) WITH CHECK ((auth.uid() = id));


--
-- Name: approval_requests; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.approval_requests ENABLE ROW LEVEL SECURITY;

--
-- Name: article_notes; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.article_notes ENABLE ROW LEVEL SECURITY;

--
-- Name: article_notes article_notes_delete_policy; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY article_notes_delete_policy ON public.article_notes FOR DELETE TO authenticated USING (((auth.uid() = created_by) OR (EXISTS ( SELECT 1
   FROM public.employees
  WHERE ((employees.id = auth.uid()) AND (employees.permissions = ANY (ARRAY['manager'::public.permission_type, 'admin'::public.permission_type, 'super_admin'::public.permission_type])))))));


--
-- Name: article_notes article_notes_insert_policy; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY article_notes_insert_policy ON public.article_notes FOR INSERT TO authenticated WITH CHECK (((auth.uid() = created_by) AND (EXISTS ( SELECT 1
   FROM public.articles
  WHERE ((articles.id = article_notes.article_id) AND ((articles.created_by = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.employees
          WHERE (employees.id = auth.uid())))))))));


--
-- Name: article_notes article_notes_select_policy; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY article_notes_select_policy ON public.article_notes FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.articles
  WHERE ((articles.id = article_notes.article_id) AND ((articles.created_by = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.employees
          WHERE (employees.id = auth.uid()))))))));


--
-- Name: article_notes article_notes_update_policy; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY article_notes_update_policy ON public.article_notes FOR UPDATE TO authenticated USING (((auth.uid() = created_by) OR (EXISTS ( SELECT 1
   FROM public.employees
  WHERE ((employees.id = auth.uid()) AND (employees.permissions = ANY (ARRAY['manager'::public.permission_type, 'admin'::public.permission_type, 'super_admin'::public.permission_type])))))));


--
-- Name: article_tags; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.article_tags ENABLE ROW LEVEL SECURITY;

--
-- Name: article_tags article_tags_delete_policy; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY article_tags_delete_policy ON public.article_tags FOR DELETE USING ((EXISTS ( SELECT 1
   FROM public.articles
  WHERE ((articles.id = article_tags.article_id) AND (articles.created_by = auth.uid())))));


--
-- Name: article_tags article_tags_insert_policy; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY article_tags_insert_policy ON public.article_tags FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM public.articles
  WHERE ((articles.id = article_tags.article_id) AND (articles.created_by = auth.uid())))));


--
-- Name: article_tags article_tags_select_policy; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY article_tags_select_policy ON public.article_tags FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.articles
  WHERE ((articles.id = article_tags.article_id) AND ((articles.status = 'approved'::public.article_status_type) OR (articles.created_by = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.employees
          WHERE ((employees.id = auth.uid()) AND (employees.permissions = ANY (ARRAY['manager'::public.permission_type, 'admin'::public.permission_type, 'super_admin'::public.permission_type]))))))))));


--
-- Name: article_versions; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.article_versions ENABLE ROW LEVEL SECURITY;

--
-- Name: articles; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.articles ENABLE ROW LEVEL SECURITY;

--
-- Name: articles articles_delete_policy; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY articles_delete_policy ON public.articles FOR DELETE USING ((EXISTS ( SELECT 1
   FROM public.employees
  WHERE (employees.id = auth.uid()))));


--
-- Name: articles articles_insert_policy; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY articles_insert_policy ON public.articles FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM public.employees
  WHERE (employees.id = auth.uid()))));


--
-- Name: articles articles_select_policy; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY articles_select_policy ON public.articles FOR SELECT USING (true);


--
-- Name: articles articles_update_policy; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY articles_update_policy ON public.articles FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM public.employees
  WHERE (employees.id = auth.uid()))));


--
-- Name: customers; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;

--
-- Name: employees; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;

--
-- Name: approval_requests employees_create_own_approval_requests; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY employees_create_own_approval_requests ON public.approval_requests FOR INSERT TO authenticated WITH CHECK ((EXISTS ( SELECT 1
   FROM public.articles
  WHERE ((articles.id = approval_requests.article_id) AND (articles.created_by = auth.uid())))));


--
-- Name: article_notes employees_create_own_article_notes; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY employees_create_own_article_notes ON public.article_notes FOR INSERT TO authenticated WITH CHECK (((auth.uid() = created_by) AND (EXISTS ( SELECT 1
   FROM public.articles
  WHERE ((articles.id = article_notes.article_id) AND (articles.created_by = auth.uid()))))));


--
-- Name: article_versions employees_create_own_article_versions; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY employees_create_own_article_versions ON public.article_versions FOR INSERT TO authenticated WITH CHECK ((EXISTS ( SELECT 1
   FROM public.articles
  WHERE ((articles.id = article_versions.article_id) AND (articles.created_by = auth.uid())))));


--
-- Name: approval_requests employees_view_own_approval_requests; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY employees_view_own_approval_requests ON public.approval_requests FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.articles
  WHERE ((articles.id = approval_requests.article_id) AND (articles.created_by = auth.uid())))));


--
-- Name: article_notes employees_view_own_article_notes; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY employees_view_own_article_notes ON public.article_notes FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.articles
  WHERE ((articles.id = article_notes.article_id) AND (articles.created_by = auth.uid())))));


--
-- Name: article_versions employees_view_own_article_versions; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY employees_view_own_article_versions ON public.article_versions FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.articles
  WHERE ((articles.id = article_versions.article_id) AND (articles.created_by = auth.uid())))));


--
-- Name: article_notes managers_create_article_notes; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY managers_create_article_notes ON public.article_notes FOR INSERT TO authenticated WITH CHECK (((auth.uid() = created_by) AND (EXISTS ( SELECT 1
   FROM public.employees
  WHERE ((employees.id = auth.uid()) AND (employees.permissions = ANY (ARRAY['manager'::public.permission_type, 'admin'::public.permission_type, 'super_admin'::public.permission_type])))))));


--
-- Name: article_versions managers_create_article_versions; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY managers_create_article_versions ON public.article_versions FOR INSERT TO authenticated WITH CHECK ((EXISTS ( SELECT 1
   FROM public.employees
  WHERE ((employees.id = auth.uid()) AND (employees.permissions = ANY (ARRAY['manager'::public.permission_type, 'admin'::public.permission_type, 'super_admin'::public.permission_type]))))));


--
-- Name: approval_requests managers_update_approval_requests; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY managers_update_approval_requests ON public.approval_requests FOR UPDATE TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.employees
  WHERE ((employees.id = auth.uid()) AND (employees.permissions = ANY (ARRAY['manager'::public.permission_type, 'admin'::public.permission_type, 'super_admin'::public.permission_type])))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.employees
  WHERE ((employees.id = auth.uid()) AND (employees.permissions = ANY (ARRAY['manager'::public.permission_type, 'admin'::public.permission_type, 'super_admin'::public.permission_type]))))));


--
-- Name: approval_requests managers_view_all_approval_requests; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY managers_view_all_approval_requests ON public.approval_requests FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.employees
  WHERE ((employees.id = auth.uid()) AND (employees.permissions = ANY (ARRAY['manager'::public.permission_type, 'admin'::public.permission_type, 'super_admin'::public.permission_type]))))));


--
-- Name: article_notes managers_view_all_article_notes; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY managers_view_all_article_notes ON public.article_notes FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.employees
  WHERE ((employees.id = auth.uid()) AND (employees.permissions = ANY (ARRAY['manager'::public.permission_type, 'admin'::public.permission_type, 'super_admin'::public.permission_type]))))));


--
-- Name: article_versions managers_view_all_article_versions; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY managers_view_all_article_versions ON public.article_versions FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.employees
  WHERE ((employees.id = auth.uid()) AND (employees.permissions = ANY (ARRAY['manager'::public.permission_type, 'admin'::public.permission_type, 'super_admin'::public.permission_type]))))));


--
-- Name: messages; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

--
-- Name: ticket_notes; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.ticket_notes ENABLE ROW LEVEL SECURITY;

--
-- Name: ticket_notes ticket_notes_delete_policy; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY ticket_notes_delete_policy ON public.ticket_notes FOR DELETE TO authenticated USING (((auth.uid() = created_by) OR (EXISTS ( SELECT 1
   FROM public.employees
  WHERE ((employees.id = auth.uid()) AND (employees.permissions = ANY (ARRAY['manager'::public.permission_type, 'admin'::public.permission_type, 'super_admin'::public.permission_type])))))));


--
-- Name: ticket_notes ticket_notes_insert_policy; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY ticket_notes_insert_policy ON public.ticket_notes FOR INSERT TO authenticated WITH CHECK (((auth.uid() = created_by) AND (EXISTS ( SELECT 1
   FROM public.tickets
  WHERE ((tickets.id = ticket_notes.ticket_id) AND ((tickets.created_by = auth.uid()) OR (tickets.assigned_to = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.employees
          WHERE (employees.id = auth.uid())))))))));


--
-- Name: ticket_notes ticket_notes_select_policy; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY ticket_notes_select_policy ON public.ticket_notes FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.tickets
  WHERE ((tickets.id = ticket_notes.ticket_id) AND ((tickets.created_by = auth.uid()) OR (tickets.assigned_to = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.employees
          WHERE (employees.id = auth.uid()))))))));


--
-- Name: ticket_notes ticket_notes_update_policy; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY ticket_notes_update_policy ON public.ticket_notes FOR UPDATE TO authenticated USING (((auth.uid() = created_by) OR (EXISTS ( SELECT 1
   FROM public.employees
  WHERE ((employees.id = auth.uid()) AND (employees.permissions = ANY (ARRAY['manager'::public.permission_type, 'admin'::public.permission_type, 'super_admin'::public.permission_type])))))));


--
-- Name: tickets; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.tickets ENABLE ROW LEVEL SECURITY;

--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT USAGE ON SCHEMA public TO postgres;
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO service_role;


--
-- Name: FUNCTION handle_new_user(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.handle_new_user() TO anon;
GRANT ALL ON FUNCTION public.handle_new_user() TO authenticated;
GRANT ALL ON FUNCTION public.handle_new_user() TO service_role;


--
-- Name: FUNCTION increment_article_view_count(article_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.increment_article_view_count(article_id uuid) TO anon;
GRANT ALL ON FUNCTION public.increment_article_view_count(article_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.increment_article_view_count(article_id uuid) TO service_role;


--
-- Name: FUNCTION refresh_employee_metrics(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.refresh_employee_metrics() TO anon;
GRANT ALL ON FUNCTION public.refresh_employee_metrics() TO authenticated;
GRANT ALL ON FUNCTION public.refresh_employee_metrics() TO service_role;


--
-- Name: FUNCTION refresh_employee_metrics_trigger(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.refresh_employee_metrics_trigger() TO anon;
GRANT ALL ON FUNCTION public.refresh_employee_metrics_trigger() TO authenticated;
GRANT ALL ON FUNCTION public.refresh_employee_metrics_trigger() TO service_role;


--
-- Name: FUNCTION update_updated_at_column(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.update_updated_at_column() TO anon;
GRANT ALL ON FUNCTION public.update_updated_at_column() TO authenticated;
GRANT ALL ON FUNCTION public.update_updated_at_column() TO service_role;


--
-- Name: TABLE approval_requests; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.approval_requests TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.approval_requests TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.approval_requests TO service_role;


--
-- Name: TABLE article_notes; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.article_notes TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.article_notes TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.article_notes TO service_role;


--
-- Name: TABLE article_tags; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.article_tags TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.article_tags TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.article_tags TO service_role;


--
-- Name: TABLE article_versions; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.article_versions TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.article_versions TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.article_versions TO service_role;


--
-- Name: TABLE articles; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.articles TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.articles TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.articles TO service_role;


--
-- Name: TABLE customers; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.customers TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.customers TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.customers TO service_role;


--
-- Name: TABLE employees; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.employees TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.employees TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.employees TO service_role;


--
-- Name: TABLE employee_profiles; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.employee_profiles TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.employee_profiles TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.employee_profiles TO service_role;


--
-- Name: TABLE messages; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.messages TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.messages TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.messages TO service_role;


--
-- Name: TABLE tickets; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.tickets TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.tickets TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.tickets TO service_role;


--
-- Name: TABLE employee_performance_metrics; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.employee_performance_metrics TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.employee_performance_metrics TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.employee_performance_metrics TO service_role;


--
-- Name: TABLE ticket_notes; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.ticket_notes TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.ticket_notes TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.ticket_notes TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO service_role;


--
-- PostgreSQL database dump complete
--

