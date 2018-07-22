--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.9
-- Dumped by pg_dump version 9.6.9

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: expire_token(); Type: FUNCTION; Schema: public; Owner: cloud
--

CREATE FUNCTION public.expire_token() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  DELETE FROM tokens WHERE created < NOW() - INTERVAL '3 days';
RETURN NEW;
END;
$$;


ALTER FUNCTION public.expire_token() OWNER TO cloud;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: lapis_migrations; Type: TABLE; Schema: public; Owner: cloud
--

CREATE TABLE public.lapis_migrations (
    name character varying(255) NOT NULL
);


ALTER TABLE public.lapis_migrations OWNER TO cloud;

--
-- Name: projects; Type: TABLE; Schema: public; Owner: cloud
--

CREATE TABLE public.projects (
    id integer NOT NULL,
    username text NOT NULL,
    projectname text NOT NULL,
    ispublic boolean DEFAULT false NOT NULL,
    ispublished boolean DEFAULT false NOT NULL,
    notes text,
    created timestamp with time zone NOT NULL,
    lastupdated timestamp with time zone,
    lastshared timestamp with time zone,
    firstpublished timestamp with time zone,
    remixes integer[]
);


ALTER TABLE public.projects OWNER TO cloud;

--
-- Name: projects_id_seq; Type: SEQUENCE; Schema: public; Owner: cloud
--

CREATE SEQUENCE public.projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.projects_id_seq OWNER TO cloud;

--
-- Name: projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cloud
--

ALTER SEQUENCE public.projects_id_seq OWNED BY public.projects.id;


--
-- Name: tokens; Type: TABLE; Schema: public; Owner: cloud
--

CREATE TABLE public.tokens (
    created timestamp with time zone NOT NULL,
    username text NOT NULL,
    purpose text NOT NULL,
    value text NOT NULL
);


ALTER TABLE public.tokens OWNER TO cloud;

--
-- Name: users; Type: TABLE; Schema: public; Owner: cloud
--

CREATE TABLE public.users (
    id integer NOT NULL,
    username text NOT NULL,
    created timestamp with time zone NOT NULL,
    email text NOT NULL,
    salt text NOT NULL,
    password text NOT NULL,
    about text,
    location text,
    isadmin boolean DEFAULT false NOT NULL,
    verified boolean DEFAULT false NOT NULL
);


ALTER TABLE public.users OWNER TO cloud;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: cloud
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO cloud;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cloud
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: projects id; Type: DEFAULT; Schema: public; Owner: cloud
--

ALTER TABLE ONLY public.projects ALTER COLUMN id SET DEFAULT nextval('public.projects_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: cloud
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: lapis_migrations lapis_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: cloud
--

ALTER TABLE ONLY public.lapis_migrations
    ADD CONSTRAINT lapis_migrations_pkey PRIMARY KEY (name);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: cloud
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (username, projectname);


--
-- Name: tokens tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: cloud
--

ALTER TABLE ONLY public.tokens
    ADD CONSTRAINT tokens_pkey PRIMARY KEY (value);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: cloud
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (username);


--
-- Name: tokens expire_token_trigger; Type: TRIGGER; Schema: public; Owner: cloud
--

CREATE TRIGGER expire_token_trigger AFTER INSERT ON public.tokens FOR EACH STATEMENT EXECUTE PROCEDURE public.expire_token();


--
-- Name: projects projects_username_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cloud
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_username_fkey FOREIGN KEY (username) REFERENCES public.users(username);


--
-- Name: tokens tokens_username_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cloud
--

ALTER TABLE ONLY public.tokens
    ADD CONSTRAINT tokens_username_fkey FOREIGN KEY (username) REFERENCES public.users(username);


--
-- PostgreSQL database dump complete
--

