-- Drop old tables

whenever sqlerror continue;

drop table contact_address;
drop table customer;
drop table contract;
drop table plan;
drop table property;

whenever sqlerror exit sql.sqlcode;

-- Create new tables

create table contact_address (
        address_id number not null,
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
        warning_interest float
);

create table property (
        property_id number,
        product_id number,
        contract_id number
);