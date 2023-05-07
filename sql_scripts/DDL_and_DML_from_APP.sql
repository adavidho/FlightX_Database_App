--
-- PostgreSQL database dump
--

-- Dumped from database version 15.2 (Debian 15.2-1.pgdg110+1)
-- Dumped by pg_dump version 15.2 (Debian 15.2-1.pgdg110+1)

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

--
-- Name: cancel_flight(character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.cancel_flight(IN flight_number character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- Update bookings
  UPDATE airlinex_booking SET cancelled = true WHERE flight_id = flight_number;
  -- Remove crew assignments for the flight
  DELETE FROM airlinex_assignment WHERE flight_id = flight_number;
END;$$;


ALTER PROCEDURE public.cancel_flight(IN flight_number character varying) OWNER TO postgres;

--
-- Name: cancel_flight_trigger_function(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cancel_flight_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.cancelled THEN
    CALL cancel_flight(NEW.number);
  END IF;
  RETURN NULL;
END;
$$;


ALTER FUNCTION public.cancel_flight_trigger_function() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: airlinex_aircraft; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.airlinex_aircraft (
    registration character varying(10) NOT NULL,
    type_series character varying(10) NOT NULL,
    passenger_capacity integer NOT NULL
);


ALTER TABLE public.airlinex_aircraft OWNER TO postgres;

--
-- Name: airlinex_assignment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.airlinex_assignment (
    id bigint NOT NULL,
    employee_id bigint NOT NULL,
    flight_id character varying(10) NOT NULL
);


ALTER TABLE public.airlinex_assignment OWNER TO postgres;

--
-- Name: airlinex_assignment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.airlinex_assignment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.airlinex_assignment_id_seq OWNER TO postgres;

--
-- Name: airlinex_assignment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.airlinex_assignment_id_seq OWNED BY public.airlinex_assignment.id;


--
-- Name: airlinex_booking; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.airlinex_booking (
    id bigint NOT NULL,
    "time" timestamp with time zone NOT NULL,
    cancelled boolean NOT NULL,
    flight_id character varying(10) NOT NULL,
    passenger_id bigint NOT NULL
);


ALTER TABLE public.airlinex_booking OWNER TO postgres;

--
-- Name: airlinex_booking_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.airlinex_booking_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.airlinex_booking_id_seq OWNER TO postgres;

--
-- Name: airlinex_booking_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.airlinex_booking_id_seq OWNED BY public.airlinex_booking.id;


--
-- Name: airlinex_employee; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.airlinex_employee (
    id bigint NOT NULL,
    first_name character varying(100) NOT NULL,
    last_name character varying(100) NOT NULL,
    email character varying(254) NOT NULL,
    role character varying(2) NOT NULL,
    based_in_id character varying(4),
    spouse_id bigint
);


ALTER TABLE public.airlinex_employee OWNER TO postgres;

--
-- Name: airlinex_employee_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.airlinex_employee_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.airlinex_employee_id_seq OWNER TO postgres;

--
-- Name: airlinex_employee_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.airlinex_employee_id_seq OWNED BY public.airlinex_employee.id;


--
-- Name: airlinex_flight; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.airlinex_flight (
    number character varying(10) NOT NULL,
    departure_time timestamp with time zone NOT NULL,
    arrival_time timestamp with time zone NOT NULL,
    delay integer NOT NULL,
    cancelled boolean NOT NULL,
    aircraft_id character varying(10) NOT NULL,
    departure_airport_id character varying(4) NOT NULL,
    destination_airport_id character varying(4) NOT NULL,
    CONSTRAINT airlinex_flight_delay_check CHECK ((delay >= 0))
);


ALTER TABLE public.airlinex_flight OWNER TO postgres;

--
-- Name: airlinex_passenger; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.airlinex_passenger (
    id bigint NOT NULL,
    first_name character varying(100) NOT NULL,
    last_name character varying(100) NOT NULL,
    status character varying(20) NOT NULL,
    notes text NOT NULL
);


ALTER TABLE public.airlinex_passenger OWNER TO postgres;

--
-- Name: airlinex_passenger_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.airlinex_passenger_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.airlinex_passenger_id_seq OWNER TO postgres;

--
-- Name: airlinex_passenger_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.airlinex_passenger_id_seq OWNED BY public.airlinex_passenger.id;


--
-- Name: airportx_airport; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.airportx_airport (
    icao_code character varying(4) NOT NULL,
    name character varying(100) NOT NULL
);


ALTER TABLE public.airportx_airport OWNER TO postgres;

--
-- Name: airport_stats; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.airport_stats AS
 SELECT a.icao_code,
    avg(f.delay) AS avg_delay,
    count(DISTINCT f.number) AS num_flights,
    sum((COALESCE(bd.num_departing_passengers, (0)::bigint) + COALESCE(ba.num_arriving_passengers, (0)::bigint))) AS num_passengers
   FROM (((public.airportx_airport a
     LEFT JOIN public.airlinex_flight f ON ((((a.icao_code)::text = (f.departure_airport_id)::text) OR ((a.icao_code)::text = (f.destination_airport_id)::text))))
     LEFT JOIN ( SELECT airlinex_booking.flight_id,
            count(*) AS num_departing_passengers
           FROM public.airlinex_booking
          WHERE (airlinex_booking.cancelled = false)
          GROUP BY airlinex_booking.flight_id) bd ON ((((f.number)::text = (bd.flight_id)::text) AND ((f.departure_airport_id)::text = (a.icao_code)::text))))
     LEFT JOIN ( SELECT airlinex_booking.flight_id,
            count(*) AS num_arriving_passengers
           FROM public.airlinex_booking
          WHERE (airlinex_booking.cancelled = false)
          GROUP BY airlinex_booking.flight_id) ba ON ((((f.number)::text = (ba.flight_id)::text) AND ((f.destination_airport_id)::text = (a.icao_code)::text))))
  WHERE (f.cancelled = false)
  GROUP BY a.icao_code, a.name;


ALTER TABLE public.airport_stats OWNER TO postgres;

--
-- Name: airportx_runway; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.airportx_runway (
    id bigint NOT NULL,
    length integer NOT NULL,
    name character varying(4) NOT NULL,
    airport_id character varying(4) NOT NULL
);


ALTER TABLE public.airportx_runway OWNER TO postgres;

--
-- Name: airportx_runway_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.airportx_runway_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.airportx_runway_id_seq OWNER TO postgres;

--
-- Name: airportx_runway_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.airportx_runway_id_seq OWNED BY public.airportx_runway.id;


--
-- Name: auth_group; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auth_group (
    id integer NOT NULL,
    name character varying(150) NOT NULL
);


ALTER TABLE public.auth_group OWNER TO postgres;

--
-- Name: auth_group_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.auth_group_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.auth_group_id_seq OWNER TO postgres;

--
-- Name: auth_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.auth_group_id_seq OWNED BY public.auth_group.id;


--
-- Name: auth_group_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auth_group_permissions (
    id bigint NOT NULL,
    group_id integer NOT NULL,
    permission_id integer NOT NULL
);


ALTER TABLE public.auth_group_permissions OWNER TO postgres;

--
-- Name: auth_group_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.auth_group_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.auth_group_permissions_id_seq OWNER TO postgres;

--
-- Name: auth_group_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.auth_group_permissions_id_seq OWNED BY public.auth_group_permissions.id;


--
-- Name: auth_permission; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auth_permission (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    content_type_id integer NOT NULL,
    codename character varying(100) NOT NULL
);


ALTER TABLE public.auth_permission OWNER TO postgres;

--
-- Name: auth_permission_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.auth_permission_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.auth_permission_id_seq OWNER TO postgres;

--
-- Name: auth_permission_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.auth_permission_id_seq OWNED BY public.auth_permission.id;


--
-- Name: auth_user; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auth_user (
    id integer NOT NULL,
    password character varying(128) NOT NULL,
    last_login timestamp with time zone,
    is_superuser boolean NOT NULL,
    username character varying(150) NOT NULL,
    first_name character varying(150) NOT NULL,
    last_name character varying(150) NOT NULL,
    email character varying(254) NOT NULL,
    is_staff boolean NOT NULL,
    is_active boolean NOT NULL,
    date_joined timestamp with time zone NOT NULL
);


ALTER TABLE public.auth_user OWNER TO postgres;

--
-- Name: auth_user_groups; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auth_user_groups (
    id bigint NOT NULL,
    user_id integer NOT NULL,
    group_id integer NOT NULL
);


ALTER TABLE public.auth_user_groups OWNER TO postgres;

--
-- Name: auth_user_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.auth_user_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.auth_user_groups_id_seq OWNER TO postgres;

--
-- Name: auth_user_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.auth_user_groups_id_seq OWNED BY public.auth_user_groups.id;


--
-- Name: auth_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.auth_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.auth_user_id_seq OWNER TO postgres;

--
-- Name: auth_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.auth_user_id_seq OWNED BY public.auth_user.id;


--
-- Name: auth_user_user_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auth_user_user_permissions (
    id bigint NOT NULL,
    user_id integer NOT NULL,
    permission_id integer NOT NULL
);


ALTER TABLE public.auth_user_user_permissions OWNER TO postgres;

--
-- Name: auth_user_user_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.auth_user_user_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.auth_user_user_permissions_id_seq OWNER TO postgres;

--
-- Name: auth_user_user_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.auth_user_user_permissions_id_seq OWNED BY public.auth_user_user_permissions.id;


--
-- Name: django_admin_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.django_admin_log (
    id integer NOT NULL,
    action_time timestamp with time zone NOT NULL,
    object_id text,
    object_repr character varying(200) NOT NULL,
    action_flag smallint NOT NULL,
    change_message text NOT NULL,
    content_type_id integer,
    user_id integer NOT NULL,
    CONSTRAINT django_admin_log_action_flag_check CHECK ((action_flag >= 0))
);


ALTER TABLE public.django_admin_log OWNER TO postgres;

--
-- Name: django_admin_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.django_admin_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.django_admin_log_id_seq OWNER TO postgres;

--
-- Name: django_admin_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.django_admin_log_id_seq OWNED BY public.django_admin_log.id;


--
-- Name: django_content_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.django_content_type (
    id integer NOT NULL,
    app_label character varying(100) NOT NULL,
    model character varying(100) NOT NULL
);


ALTER TABLE public.django_content_type OWNER TO postgres;

--
-- Name: django_content_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.django_content_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.django_content_type_id_seq OWNER TO postgres;

--
-- Name: django_content_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.django_content_type_id_seq OWNED BY public.django_content_type.id;


--
-- Name: django_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.django_migrations (
    id bigint NOT NULL,
    app character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    applied timestamp with time zone NOT NULL
);


ALTER TABLE public.django_migrations OWNER TO postgres;

--
-- Name: django_migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.django_migrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.django_migrations_id_seq OWNER TO postgres;

--
-- Name: django_migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.django_migrations_id_seq OWNED BY public.django_migrations.id;


--
-- Name: django_session; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.django_session (
    session_key character varying(40) NOT NULL,
    session_data text NOT NULL,
    expire_date timestamp with time zone NOT NULL
);


ALTER TABLE public.django_session OWNER TO postgres;

--
-- Name: airlinex_assignment id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.airlinex_assignment ALTER COLUMN id SET DEFAULT nextval('public.airlinex_assignment_id_seq'::regclass);


--
-- Name: airlinex_booking id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.airlinex_booking ALTER COLUMN id SET DEFAULT nextval('public.airlinex_booking_id_seq'::regclass);


--
-- Name: airlinex_employee id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.airlinex_employee ALTER COLUMN id SET DEFAULT nextval('public.airlinex_employee_id_seq'::regclass);


--
-- Name: airlinex_passenger id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.airlinex_passenger ALTER COLUMN id SET DEFAULT nextval('public.airlinex_passenger_id_seq'::regclass);


--
-- Name: airportx_runway id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.airportx_runway ALTER COLUMN id SET DEFAULT nextval('public.airportx_runway_id_seq'::regclass);


--
-- Name: auth_group id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_group ALTER COLUMN id SET DEFAULT nextval('public.auth_group_id_seq'::regclass);


--
-- Name: auth_group_permissions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_group_permissions ALTER COLUMN id SET DEFAULT nextval('public.auth_group_permissions_id_seq'::regclass);


--
-- Name: auth_permission id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_permission ALTER COLUMN id SET DEFAULT nextval('public.auth_permission_id_seq'::regclass);


--
-- Name: auth_user id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_user ALTER COLUMN id SET DEFAULT nextval('public.auth_user_id_seq'::regclass);


--
-- Name: auth_user_groups id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_user_groups ALTER COLUMN id SET DEFAULT nextval('public.auth_user_groups_id_seq'::regclass);


--
-- Name: auth_user_user_permissions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_user_user_permissions ALTER COLUMN id SET DEFAULT nextval('public.auth_user_user_permissions_id_seq'::regclass);


--
-- Name: django_admin_log id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_admin_log ALTER COLUMN id SET DEFAULT nextval('public.django_admin_log_id_seq'::regclass);


--
-- Name: django_content_type id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_content_type ALTER COLUMN id SET DEFAULT nextval('public.django_content_type_id_seq'::regclass);


--
-- Name: django_migrations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_migrations ALTER COLUMN id SET DEFAULT nextval('public.django_migrations_id_seq'::regclass);


--
-- Data for Name: airlinex_aircraft; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.airlinex_aircraft (registration, type_series, passenger_capacity) FROM stdin;
D-ABYA	B748	364
D-AIXP	A359	293
\.


--
-- Data for Name: airlinex_assignment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.airlinex_assignment (id, employee_id, flight_id) FROM stdin;
1	1	LH480
2	2	LH480
3	3	LH470
4	4	LH480
5	3	LH480
6	1	LH470
7	2	LH470
8	4	LH470
9	1	LH440
\.


--
-- Data for Name: airlinex_booking; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.airlinex_booking (id, "time", cancelled, flight_id, passenger_id) FROM stdin;
1	2023-02-19 14:22:41.408284+00	f	LH470	1
2	2023-02-19 14:22:47.910238+00	f	LH480	1
3	2023-02-19 14:22:55.240668+00	f	LH440	1
4	2023-02-19 14:23:01.765973+00	f	LH470	2
5	2023-02-19 14:23:07.689948+00	f	LH480	2
6	2023-02-19 14:23:13.392197+00	f	LH440	2
\.


--
-- Data for Name: airlinex_employee; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.airlinex_employee (id, first_name, last_name, email, role, based_in_id, spouse_id) FROM stdin;
1	Jürgen	Raps	raps@lufthansa.com	C	EDDF	\N
2	Joong Gi	Joost	joost@lufthansa.com	FO	EDDM	\N
3	Janine	Neumann	neumann@lufthansa.com	CC	EDDF	4
4	Tobias	Reuter	treuter@lufthansa.com	CC	EDDM	3
\.


--
-- Data for Name: airlinex_flight; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.airlinex_flight (number, departure_time, arrival_time, delay, cancelled, aircraft_id, departure_airport_id, destination_airport_id) FROM stdin;
LH470	2023-02-19 08:10:00+00	2023-02-19 16:40:00+00	5	f	D-AIXP	EDDM	KJFK
LH480	2023-02-20 10:12:00+00	2023-02-20 19:10:00+00	0	f	D-ABYA	EDDF	KJFK
LH440	2023-02-21 10:15:00+00	2023-02-21 19:20:00+00	80	f	D-AIXP	KJFK	EDDM
\.


--
-- Data for Name: airlinex_passenger; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.airlinex_passenger (id, first_name, last_name, status, notes) FROM stdin;
1	James	Bond	P	Likes his drinks stirred, not shaken.
2	Rainer	Zufall	S	Preferes to choose his meals randomly.
\.


--
-- Data for Name: airportx_airport; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.airportx_airport (icao_code, name) FROM stdin;
EDDF	Frankfurt Airport
EDDM	Munich Airport
KJFK	John F. Kennedy International Airport
\.


--
-- Data for Name: airportx_runway; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.airportx_runway (id, length, name, airport_id) FROM stdin;
1	3343	07L	EDDF
2	3343	07C	EDDF
3	4231	18	EDDF
4	2560	04R	KJFK
5	3682	04L	KJFK
6	2560	22L	KJFK
7	3682	22R	KJFK
8	4231	36	EDDF
9	3343	25L	EDDF
10	3343	25R	EDDF
\.


--
-- Data for Name: auth_group; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_group (id, name) FROM stdin;
\.


--
-- Data for Name: auth_group_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_group_permissions (id, group_id, permission_id) FROM stdin;
\.


--
-- Data for Name: auth_permission; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_permission (id, name, content_type_id, codename) FROM stdin;
1	Can add airport employees	1	add_airportemployees
2	Can change airport employees	1	change_airportemployees
3	Can delete airport employees	1	delete_airportemployees
4	Can view airport employees	1	view_airportemployees
5	Can add airport stats	2	add_airportstats
6	Can change airport stats	2	change_airportstats
7	Can delete airport stats	2	delete_airportstats
8	Can view airport stats	2	view_airportstats
9	Can add airport	3	add_airport
10	Can change airport	3	change_airport
11	Can delete airport	3	delete_airport
12	Can view airport	3	view_airport
13	Can add runway	4	add_runway
14	Can change runway	4	change_runway
15	Can delete runway	4	delete_runway
16	Can view runway	4	view_runway
17	Can add aircraft	5	add_aircraft
18	Can change aircraft	5	change_aircraft
19	Can delete aircraft	5	delete_aircraft
20	Can view aircraft	5	view_aircraft
21	Can add assignment	6	add_assignment
22	Can change assignment	6	change_assignment
23	Can delete assignment	6	delete_assignment
24	Can view assignment	6	view_assignment
25	Can add employee	7	add_employee
26	Can change employee	7	change_employee
27	Can delete employee	7	delete_employee
28	Can view employee	7	view_employee
29	Can add passenger	8	add_passenger
30	Can change passenger	8	change_passenger
31	Can delete passenger	8	delete_passenger
32	Can view passenger	8	view_passenger
33	Can add flight	9	add_flight
34	Can change flight	9	change_flight
35	Can delete flight	9	delete_flight
36	Can view flight	9	view_flight
37	Can add booking	10	add_booking
38	Can change booking	10	change_booking
39	Can delete booking	10	delete_booking
40	Can view booking	10	view_booking
41	Can add log entry	11	add_logentry
42	Can change log entry	11	change_logentry
43	Can delete log entry	11	delete_logentry
44	Can view log entry	11	view_logentry
45	Can add permission	12	add_permission
46	Can change permission	12	change_permission
47	Can delete permission	12	delete_permission
48	Can view permission	12	view_permission
49	Can add group	13	add_group
50	Can change group	13	change_group
51	Can delete group	13	delete_group
52	Can view group	13	view_group
53	Can add user	14	add_user
54	Can change user	14	change_user
55	Can delete user	14	delete_user
56	Can view user	14	view_user
57	Can add content type	15	add_contenttype
58	Can change content type	15	change_contenttype
59	Can delete content type	15	delete_contenttype
60	Can view content type	15	view_contenttype
61	Can add session	16	add_session
62	Can change session	16	change_session
63	Can delete session	16	delete_session
64	Can view session	16	view_session
\.


--
-- Data for Name: auth_user; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_user (id, password, last_login, is_superuser, username, first_name, last_name, email, is_staff, is_active, date_joined) FROM stdin;
\.


--
-- Data for Name: auth_user_groups; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_user_groups (id, user_id, group_id) FROM stdin;
\.


--
-- Data for Name: auth_user_user_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_user_user_permissions (id, user_id, permission_id) FROM stdin;
\.


--
-- Data for Name: django_admin_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.django_admin_log (id, action_time, object_id, object_repr, action_flag, change_message, content_type_id, user_id) FROM stdin;
\.


--
-- Data for Name: django_content_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.django_content_type (id, app_label, model) FROM stdin;
1	airportx	airportemployees
2	airportx	airportstats
3	airportx	airport
4	airportx	runway
5	airlinex	aircraft
6	airlinex	assignment
7	airlinex	employee
8	airlinex	passenger
9	airlinex	flight
10	airlinex	booking
11	admin	logentry
12	auth	permission
13	auth	group
14	auth	user
15	contenttypes	contenttype
16	sessions	session
\.


--
-- Data for Name: django_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.django_migrations (id, app, name, applied) FROM stdin;
1	contenttypes	0001_initial	2023-05-07 11:43:44.057303+00
2	auth	0001_initial	2023-05-07 11:43:44.196084+00
3	admin	0001_initial	2023-05-07 11:43:44.229019+00
4	admin	0002_logentry_remove_auto_add	2023-05-07 11:43:44.233726+00
5	admin	0003_logentry_add_action_flag_choices	2023-05-07 11:43:44.23769+00
6	airportx	0001_initial	2023-05-07 11:43:44.239847+00
7	airportx	0002_airport_runway	2023-05-07 11:43:44.284968+00
8	airlinex	0001_initial	2023-05-07 11:43:44.441298+00
9	contenttypes	0002_remove_content_type_name	2023-05-07 11:43:44.476387+00
10	auth	0002_alter_permission_name_max_length	2023-05-07 11:43:44.480357+00
11	auth	0003_alter_user_email_max_length	2023-05-07 11:43:44.483917+00
12	auth	0004_alter_user_username_opts	2023-05-07 11:43:44.487048+00
13	auth	0005_alter_user_last_login_null	2023-05-07 11:43:44.49087+00
14	auth	0006_require_contenttypes_0002	2023-05-07 11:43:44.492078+00
15	auth	0007_alter_validators_add_error_messages	2023-05-07 11:43:44.495713+00
16	auth	0008_alter_user_username_max_length	2023-05-07 11:43:44.507905+00
17	auth	0009_alter_user_last_name_max_length	2023-05-07 11:43:44.512397+00
18	auth	0010_alter_group_name_max_length	2023-05-07 11:43:44.518563+00
19	auth	0011_update_proxy_permissions	2023-05-07 11:43:44.524028+00
20	auth	0012_alter_user_first_name_max_length	2023-05-07 11:43:44.528094+00
21	sessions	0001_initial	2023-05-07 11:43:44.547848+00
\.


--
-- Data for Name: django_session; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.django_session (session_key, session_data, expire_date) FROM stdin;
\.


--
-- Name: airlinex_assignment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.airlinex_assignment_id_seq', 10, true);


--
-- Name: airlinex_booking_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.airlinex_booking_id_seq', 7, true);


--
-- Name: airlinex_employee_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.airlinex_employee_id_seq', 5, true);


--
-- Name: airlinex_passenger_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.airlinex_passenger_id_seq', 3, true);


--
-- Name: airportx_runway_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.airportx_runway_id_seq', 11, true);


--
-- Name: auth_group_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auth_group_id_seq', 1, false);


--
-- Name: auth_group_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auth_group_permissions_id_seq', 1, false);


--
-- Name: auth_permission_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auth_permission_id_seq', 64, true);


--
-- Name: auth_user_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auth_user_groups_id_seq', 1, false);


--
-- Name: auth_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auth_user_id_seq', 1, false);


--
-- Name: auth_user_user_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auth_user_user_permissions_id_seq', 1, false);


--
-- Name: django_admin_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.django_admin_log_id_seq', 1, false);


--
-- Name: django_content_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.django_content_type_id_seq', 16, true);


--
-- Name: django_migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.django_migrations_id_seq', 21, true);


--
-- Name: airportx_airport airportx_airport_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.airportx_airport
    ADD CONSTRAINT airportx_airport_pkey PRIMARY KEY (icao_code);


--
-- Name: airport_and_based_crew; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW public.airport_and_based_crew AS
 SELECT airportx_airport.icao_code,
    airportx_airport.name,
    count(airlinex_employee.based_in_id) AS num_employees
   FROM (public.airportx_airport
     LEFT JOIN public.airlinex_employee ON (((airportx_airport.icao_code)::text = (airlinex_employee.based_in_id)::text)))
  GROUP BY airportx_airport.icao_code
  WITH NO DATA;


ALTER TABLE public.airport_and_based_crew OWNER TO postgres;

--
-- Name: airlinex_aircraft airlinex_aircraft_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.airlinex_aircraft
    ADD CONSTRAINT airlinex_aircraft_pkey PRIMARY KEY (registration);


--
-- Name: airlinex_assignment airlinex_assignment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.airlinex_assignment
    ADD CONSTRAINT airlinex_assignment_pkey PRIMARY KEY (id);


--
-- Name: airlinex_booking airlinex_booking_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.airlinex_booking
    ADD CONSTRAINT airlinex_booking_pkey PRIMARY KEY (id);


--
-- Name: airlinex_employee airlinex_employee_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.airlinex_employee
    ADD CONSTRAINT airlinex_employee_pkey PRIMARY KEY (id);


--
-- Name: airlinex_employee airlinex_employee_spouse_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.airlinex_employee
    ADD CONSTRAINT airlinex_employee_spouse_id_key UNIQUE (spouse_id);


--
-- Name: airlinex_flight airlinex_flight_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.airlinex_flight
    ADD CONSTRAINT airlinex_flight_pkey PRIMARY KEY (number);


--
-- Name: airlinex_passenger airlinex_passenger_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.airlinex_passenger
    ADD CONSTRAINT airlinex_passenger_pkey PRIMARY KEY (id);


--
-- Name: airportx_runway airportx_runway_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.airportx_runway
    ADD CONSTRAINT airportx_runway_pkey PRIMARY KEY (id);


--
-- Name: auth_group auth_group_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_group
    ADD CONSTRAINT auth_group_name_key UNIQUE (name);


--
-- Name: auth_group_permissions auth_group_permissions_group_id_permission_id_0cd325b0_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_group_id_permission_id_0cd325b0_uniq UNIQUE (group_id, permission_id);


--
-- Name: auth_group_permissions auth_group_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_pkey PRIMARY KEY (id);


--
-- Name: auth_group auth_group_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_group
    ADD CONSTRAINT auth_group_pkey PRIMARY KEY (id);


--
-- Name: auth_permission auth_permission_content_type_id_codename_01ab375a_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_content_type_id_codename_01ab375a_uniq UNIQUE (content_type_id, codename);


--
-- Name: auth_permission auth_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_pkey PRIMARY KEY (id);


--
-- Name: auth_user_groups auth_user_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_user_groups
    ADD CONSTRAINT auth_user_groups_pkey PRIMARY KEY (id);


--
-- Name: auth_user_groups auth_user_groups_user_id_group_id_94350c0c_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_user_groups
    ADD CONSTRAINT auth_user_groups_user_id_group_id_94350c0c_uniq UNIQUE (user_id, group_id);


--
-- Name: auth_user auth_user_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_user
    ADD CONSTRAINT auth_user_pkey PRIMARY KEY (id);


--
-- Name: auth_user_user_permissions auth_user_user_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_user_user_permissions
    ADD CONSTRAINT auth_user_user_permissions_pkey PRIMARY KEY (id);


--
-- Name: auth_user_user_permissions auth_user_user_permissions_user_id_permission_id_14a6b632_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_user_user_permissions
    ADD CONSTRAINT auth_user_user_permissions_user_id_permission_id_14a6b632_uniq UNIQUE (user_id, permission_id);


--
-- Name: auth_user auth_user_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_user
    ADD CONSTRAINT auth_user_username_key UNIQUE (username);


--
-- Name: django_admin_log django_admin_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_pkey PRIMARY KEY (id);


--
-- Name: django_content_type django_content_type_app_label_model_76bd3d3b_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_content_type
    ADD CONSTRAINT django_content_type_app_label_model_76bd3d3b_uniq UNIQUE (app_label, model);


--
-- Name: django_content_type django_content_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_content_type
    ADD CONSTRAINT django_content_type_pkey PRIMARY KEY (id);


--
-- Name: django_migrations django_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_migrations
    ADD CONSTRAINT django_migrations_pkey PRIMARY KEY (id);


--
-- Name: django_session django_session_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_session
    ADD CONSTRAINT django_session_pkey PRIMARY KEY (session_key);


--
-- Name: airlinex_booking flight_passenger_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.airlinex_booking
    ADD CONSTRAINT flight_passenger_unique UNIQUE (flight_id, passenger_id);


--
-- Name: airlinex_aircraft_registration_e1d865b7_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX airlinex_aircraft_registration_e1d865b7_like ON public.airlinex_aircraft USING btree (registration varchar_pattern_ops);


--
-- Name: airlinex_assignment_employee_id_1b62b316; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX airlinex_assignment_employee_id_1b62b316 ON public.airlinex_assignment USING btree (employee_id);


--
-- Name: airlinex_assignment_flight_id_1d95d3bb; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX airlinex_assignment_flight_id_1d95d3bb ON public.airlinex_assignment USING btree (flight_id);


--
-- Name: airlinex_assignment_flight_id_1d95d3bb_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX airlinex_assignment_flight_id_1d95d3bb_like ON public.airlinex_assignment USING btree (flight_id varchar_pattern_ops);


--
-- Name: airlinex_booking_flight_id_084d83f2; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX airlinex_booking_flight_id_084d83f2 ON public.airlinex_booking USING btree (flight_id);


--
-- Name: airlinex_booking_flight_id_084d83f2_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX airlinex_booking_flight_id_084d83f2_like ON public.airlinex_booking USING btree (flight_id varchar_pattern_ops);


--
-- Name: airlinex_booking_passenger_id_da0d1fa1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX airlinex_booking_passenger_id_da0d1fa1 ON public.airlinex_booking USING btree (passenger_id);


--
-- Name: airlinex_employee_based_in_id_3cb1b962; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX airlinex_employee_based_in_id_3cb1b962 ON public.airlinex_employee USING btree (based_in_id);


--
-- Name: airlinex_employee_based_in_id_3cb1b962_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX airlinex_employee_based_in_id_3cb1b962_like ON public.airlinex_employee USING btree (based_in_id varchar_pattern_ops);


--
-- Name: airlinex_employee_last_name_d771ddd0; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX airlinex_employee_last_name_d771ddd0 ON public.airlinex_employee USING btree (last_name);


--
-- Name: airlinex_employee_last_name_d771ddd0_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX airlinex_employee_last_name_d771ddd0_like ON public.airlinex_employee USING btree (last_name varchar_pattern_ops);


--
-- Name: airlinex_flight_aircraft_id_d51880de; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX airlinex_flight_aircraft_id_d51880de ON public.airlinex_flight USING btree (aircraft_id);


--
-- Name: airlinex_flight_aircraft_id_d51880de_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX airlinex_flight_aircraft_id_d51880de_like ON public.airlinex_flight USING btree (aircraft_id varchar_pattern_ops);


--
-- Name: airlinex_flight_departure_airport_id_f4ea3b0d; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX airlinex_flight_departure_airport_id_f4ea3b0d ON public.airlinex_flight USING btree (departure_airport_id);


--
-- Name: airlinex_flight_departure_airport_id_f4ea3b0d_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX airlinex_flight_departure_airport_id_f4ea3b0d_like ON public.airlinex_flight USING btree (departure_airport_id varchar_pattern_ops);


--
-- Name: airlinex_flight_destination_airport_id_85ec5ad1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX airlinex_flight_destination_airport_id_85ec5ad1 ON public.airlinex_flight USING btree (destination_airport_id);


--
-- Name: airlinex_flight_destination_airport_id_85ec5ad1_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX airlinex_flight_destination_airport_id_85ec5ad1_like ON public.airlinex_flight USING btree (destination_airport_id varchar_pattern_ops);


--
-- Name: airlinex_flight_number_7f01238e_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX airlinex_flight_number_7f01238e_like ON public.airlinex_flight USING btree (number varchar_pattern_ops);


--
-- Name: airlinex_passenger_last_name_75af25a0; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX airlinex_passenger_last_name_75af25a0 ON public.airlinex_passenger USING btree (last_name);


--
-- Name: airlinex_passenger_last_name_75af25a0_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX airlinex_passenger_last_name_75af25a0_like ON public.airlinex_passenger USING btree (last_name varchar_pattern_ops);


--
-- Name: airportx_airport_icao_code_6ea576a0_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX airportx_airport_icao_code_6ea576a0_like ON public.airportx_airport USING btree (icao_code varchar_pattern_ops);


--
-- Name: airportx_airport_name_ade6ba46; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX airportx_airport_name_ade6ba46 ON public.airportx_airport USING btree (name);


--
-- Name: airportx_airport_name_ade6ba46_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX airportx_airport_name_ade6ba46_like ON public.airportx_airport USING btree (name varchar_pattern_ops);


--
-- Name: airportx_runway_airport_id_b23484e2; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX airportx_runway_airport_id_b23484e2 ON public.airportx_runway USING btree (airport_id);


--
-- Name: airportx_runway_airport_id_b23484e2_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX airportx_runway_airport_id_b23484e2_like ON public.airportx_runway USING btree (airport_id varchar_pattern_ops);


--
-- Name: auth_group_name_a6ea08ec_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX auth_group_name_a6ea08ec_like ON public.auth_group USING btree (name varchar_pattern_ops);


--
-- Name: auth_group_permissions_group_id_b120cbf9; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX auth_group_permissions_group_id_b120cbf9 ON public.auth_group_permissions USING btree (group_id);


--
-- Name: auth_group_permissions_permission_id_84c5c92e; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX auth_group_permissions_permission_id_84c5c92e ON public.auth_group_permissions USING btree (permission_id);


--
-- Name: auth_permission_content_type_id_2f476e4b; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX auth_permission_content_type_id_2f476e4b ON public.auth_permission USING btree (content_type_id);


--
-- Name: auth_user_groups_group_id_97559544; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX auth_user_groups_group_id_97559544 ON public.auth_user_groups USING btree (group_id);


--
-- Name: auth_user_groups_user_id_6a12ed8b; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX auth_user_groups_user_id_6a12ed8b ON public.auth_user_groups USING btree (user_id);


--
-- Name: auth_user_user_permissions_permission_id_1fbb5f2c; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX auth_user_user_permissions_permission_id_1fbb5f2c ON public.auth_user_user_permissions USING btree (permission_id);


--
-- Name: auth_user_user_permissions_user_id_a95ead1b; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX auth_user_user_permissions_user_id_a95ead1b ON public.auth_user_user_permissions USING btree (user_id);


--
-- Name: auth_user_username_6821ab7c_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX auth_user_username_6821ab7c_like ON public.auth_user USING btree (username varchar_pattern_ops);


--
-- Name: django_admin_log_content_type_id_c4bce8eb; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX django_admin_log_content_type_id_c4bce8eb ON public.django_admin_log USING btree (content_type_id);


--
-- Name: django_admin_log_user_id_c564eba6; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX django_admin_log_user_id_c564eba6 ON public.django_admin_log USING btree (user_id);


--
-- Name: django_session_expire_date_a5c62663; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX django_session_expire_date_a5c62663 ON public.django_session USING btree (expire_date);


--
-- Name: django_session_session_key_c0390e0f_like; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX django_session_session_key_c0390e0f_like ON public.django_session USING btree (session_key varchar_pattern_ops);


--
-- Name: airlinex_flight cancel_flight_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER cancel_flight_trigger AFTER UPDATE ON public.airlinex_flight FOR EACH ROW EXECUTE FUNCTION public.cancel_flight_trigger_function();


--
-- Name: airlinex_assignment airlinex_assignment_employee_id_1b62b316_fk_airlinex_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.airlinex_assignment
    ADD CONSTRAINT airlinex_assignment_employee_id_1b62b316_fk_airlinex_ FOREIGN KEY (employee_id) REFERENCES public.airlinex_employee(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: airlinex_assignment airlinex_assignment_flight_id_1d95d3bb_fk_airlinex_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.airlinex_assignment
    ADD CONSTRAINT airlinex_assignment_flight_id_1d95d3bb_fk_airlinex_ FOREIGN KEY (flight_id) REFERENCES public.airlinex_flight(number) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: airlinex_booking airlinex_booking_flight_id_084d83f2_fk_airlinex_flight_number; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.airlinex_booking
    ADD CONSTRAINT airlinex_booking_flight_id_084d83f2_fk_airlinex_flight_number FOREIGN KEY (flight_id) REFERENCES public.airlinex_flight(number) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: airlinex_booking airlinex_booking_passenger_id_da0d1fa1_fk_airlinex_passenger_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.airlinex_booking
    ADD CONSTRAINT airlinex_booking_passenger_id_da0d1fa1_fk_airlinex_passenger_id FOREIGN KEY (passenger_id) REFERENCES public.airlinex_passenger(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: airlinex_employee airlinex_employee_based_in_id_3cb1b962_fk_airportx_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.airlinex_employee
    ADD CONSTRAINT airlinex_employee_based_in_id_3cb1b962_fk_airportx_ FOREIGN KEY (based_in_id) REFERENCES public.airportx_airport(icao_code) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: airlinex_employee airlinex_employee_spouse_id_858f6049_fk_airlinex_employee_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.airlinex_employee
    ADD CONSTRAINT airlinex_employee_spouse_id_858f6049_fk_airlinex_employee_id FOREIGN KEY (spouse_id) REFERENCES public.airlinex_employee(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: airlinex_flight airlinex_flight_aircraft_id_d51880de_fk_airlinex_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.airlinex_flight
    ADD CONSTRAINT airlinex_flight_aircraft_id_d51880de_fk_airlinex_ FOREIGN KEY (aircraft_id) REFERENCES public.airlinex_aircraft(registration) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: airlinex_flight airlinex_flight_departure_airport_id_f4ea3b0d_fk_airportx_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.airlinex_flight
    ADD CONSTRAINT airlinex_flight_departure_airport_id_f4ea3b0d_fk_airportx_ FOREIGN KEY (departure_airport_id) REFERENCES public.airportx_airport(icao_code) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: airlinex_flight airlinex_flight_destination_airport__85ec5ad1_fk_airportx_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.airlinex_flight
    ADD CONSTRAINT airlinex_flight_destination_airport__85ec5ad1_fk_airportx_ FOREIGN KEY (destination_airport_id) REFERENCES public.airportx_airport(icao_code) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: airportx_runway airportx_runway_airport_id_b23484e2_fk_airportx_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.airportx_runway
    ADD CONSTRAINT airportx_runway_airport_id_b23484e2_fk_airportx_ FOREIGN KEY (airport_id) REFERENCES public.airportx_airport(icao_code) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_group_permissions auth_group_permissio_permission_id_84c5c92e_fk_auth_perm; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissio_permission_id_84c5c92e_fk_auth_perm FOREIGN KEY (permission_id) REFERENCES public.auth_permission(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_group_permissions auth_group_permissions_group_id_b120cbf9_fk_auth_group_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_group_id_b120cbf9_fk_auth_group_id FOREIGN KEY (group_id) REFERENCES public.auth_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_permission auth_permission_content_type_id_2f476e4b_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_content_type_id_2f476e4b_fk_django_co FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_user_groups auth_user_groups_group_id_97559544_fk_auth_group_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_user_groups
    ADD CONSTRAINT auth_user_groups_group_id_97559544_fk_auth_group_id FOREIGN KEY (group_id) REFERENCES public.auth_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_user_groups auth_user_groups_user_id_6a12ed8b_fk_auth_user_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_user_groups
    ADD CONSTRAINT auth_user_groups_user_id_6a12ed8b_fk_auth_user_id FOREIGN KEY (user_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_user_user_permissions auth_user_user_permi_permission_id_1fbb5f2c_fk_auth_perm; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_user_user_permissions
    ADD CONSTRAINT auth_user_user_permi_permission_id_1fbb5f2c_fk_auth_perm FOREIGN KEY (permission_id) REFERENCES public.auth_permission(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_user_user_permissions auth_user_user_permissions_user_id_a95ead1b_fk_auth_user_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_user_user_permissions
    ADD CONSTRAINT auth_user_user_permissions_user_id_a95ead1b_fk_auth_user_id FOREIGN KEY (user_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: django_admin_log django_admin_log_content_type_id_c4bce8eb_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_content_type_id_c4bce8eb_fk_django_co FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: django_admin_log django_admin_log_user_id_c564eba6_fk_auth_user_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_user_id_c564eba6_fk_auth_user_id FOREIGN KEY (user_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: airport_and_based_crew; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: postgres
--

REFRESH MATERIALIZED VIEW public.airport_and_based_crew;


--
-- PostgreSQL database dump complete
--

