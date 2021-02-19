-- Disable errors
whenever sqlerror continue;

-- Drop old constraints
alter table contact_address drop constraint region_name_must_be_known;
-- Drop old tables
drop table contact_address;
drop table customer;
drop table contract;
drop table plan;
drop table property;
drop table product;
drop table bill;
drop table payment;
drop table claim;
drop table payout;
drop table payment_method;
drop table risk;

-- Enable errors
whenever sqlerror exit sql.sqlcode;

-- Create new tables
create table contact_address (
    region_name char(4) not null,
    city varchar2(80) not null,
    street varchar2(80) not null,
    house_name varchar2(80) not null
);
create table customer (
    customer_id number not null,
    first_name varchar2(80) not null,
    last_name varchar2(80),
    birthday date not null,
    street_credit number,
    address_id number
);
create table contract (
    contract_id number not null,
    acceptance_date date not null,
    duration interval year to month not null,
    customer_id number,
    payment_method_id number,
    plan_id number,
    risk_id number,
    property_id number
);
create table plan (
    plan_id number not null,
    name varchar(80) not null,
    base_monthly_cost float(2) not null,
    warning_interval interval year to month not null,
    max_warnings number not null,
    warning_interest float,
    initial_cost float(2) not null
);
create table property (
    property_id number not null,
    product_id number,
    contract_id number
);
create table product (
    product_id number not null,
    name varchar2(80),
    description varchar2(80)
);
create table bill (
    bill_id number not null,
    contract_id number
);
create table payment (
    payment_id number not null,
    bill_id number,
    payment_date date
);
create table claim (
    claim_id number not null,
    compensation_amount float(2),
    rejected number not null,
    rejected_reason varchar2(255),
    contract_id number,
    claim_date date
);
create table payout (
    payout_id number not null,
    claim_id number,
    payout_date date
);
create table payment_method (
    priority_id integer not null,
    payment_method_id integer,
    customer_id integer,
    external_id integer,
    ledger varchar2(80)
);
create table risk (
    risk_id integer not null,
    reason varchar2(80),
    multiplier float
);

-- Create identity columns
alter table contact_address
add contact_address_id number generated always as identity;

-- Create new constraints
alter table contact_address
add constraint region_name_must_be_known check(region_name in ('eria', 'rhov', 'gond', 'mord'));