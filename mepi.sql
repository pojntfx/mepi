-- Disable errors
whenever sqlerror continue;

-- Drop old other constraints
alter table contact_address drop constraint region_name_must_be_known;
alter table customer drop constraint street_credit_must_be_in_range;

-- Drop old foreign key constraints
alter table customer drop constraint customer_address_fk;
alter table contract drop constraint contract_customer_fk;

-- Drop primary key constraints
alter table contact_address drop constraint contact_address_pk;
alter table customer drop constraint customer_pk;
alter table contract drop constraint contract_pk;

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
    first_name varchar2(80) not null,
    last_name varchar2(80),
    birthday date,
    street_credit number,
    contact_address_id number
);
create table contract (
    acceptance_date date default sysdate not null,
    duration interval year to month not null,
    customer_id number,
    payment_method_id number,
    plan_id number,
    risk_id number,
    property_id number
);
create table plan (
    name varchar(80) not null,
    base_monthly_cost float(2) not null,
    warning_interval interval year to month not null,
    max_warnings number not null,
    warning_interest float,
    initial_cost float(2) not null
);
create table property (
    product_id number,
    contract_id number
);
create table product (
    name varchar2(80),
    description varchar2(80)
);
create table bill (
    contract_id number
);
create table payment (
    bill_id number,
    payment_date date default sysdate
);
create table claim (
    compensation_amount float(2),
    rejected number not null,
    rejected_reason varchar2(255),
    contract_id number,
    claim_date date default sysdate
);
create table payout (
    claim_id number,
    payout_date date default sysdate
);
create table payment_method (
    payment_method_id integer,
    customer_id integer,
    external_id integer,
    ledger varchar2(80)
);
create table risk (
    reason varchar2(80),
    multiplier float
);

-- Create identity columns
alter table contact_address
add contact_address_id number generated always as identity;
alter table customer
add customer_id number generated always as identity;
alter table contract
add contract_id number generated always as identity;

-- Create new primary key constraints
alter table contact_address
add constraint contact_address_pk primary key(contact_address_id);
alter table customer
add constraint customer_pk primary key(customer_id);
alter table contract
add constraint contract_pk primary key(contract_id);

-- Create new foreign key constraints
alter table customer
add constraint customer_address_fk foreign key(contact_address_id) references contact_address(contact_address_id);
alter table contract
add constraint contract_customer_fk foreign key(customer_id) references customer(customer_id);

-- Create new other constraints
alter table contact_address
add constraint region_name_must_be_known check(region_name in ('eria', 'rhov', 'gond', 'mord'));
alter table customer
add constraint street_credit_must_be_in_range check(street_credit between 1 and 10);