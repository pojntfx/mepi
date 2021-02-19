-- Disable errors
whenever sqlerror continue;

-- Drop old other constraints
alter table contact_address drop constraint region_name_must_be_known;
alter table customer drop constraint street_credit_must_be_in_range;
alter table plan drop constraint warning_interest_percentage;

-- Drop old foreign key constraints
alter table customer drop constraint customer_address_fk;
alter table contract drop constraint contract_customer_fk;
alter table contract drop constraint contract_payment_method_fk;
alter table contract drop constraint contract_plan_fk;
alter table contract drop constraint contract_risk_fk;
alter table contract drop constraint contract_property_fk;
alter table property drop constraint property_product_fk;

-- Drop primary key constraints
alter table contact_address drop constraint contact_address_pk;
alter table customer drop constraint customer_pk;
alter table contract drop constraint contract_pk;
alter table payment_method drop constraint payment_method_pk;
alter table plan drop constraint plan_pk;
alter table risk drop constraint risk_pk;
alter table property drop constraint property_pk;

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
    initial_cost float(2) not null,
    warning_interval interval year to month not null,
    max_warnings number not null,
    warning_interest float not null
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
alter table payment_method
add payment_method_id number generated always as identity;
alter table plan
add plan_id number generated always as identity;
alter table risk
add risk_id number generated always as identity;
alter table property
add property_id number generated always as identity;
alter table product
add product_id number generated always as identity;

-- Create new primary key constraints
alter table contact_address
add constraint contact_address_pk primary key(contact_address_id);
alter table customer
add constraint customer_pk primary key(customer_id);
alter table contract
add constraint contract_pk primary key(contract_id);
alter table payment_method
add constraint payment_method_pk primary key(payment_method_id);
alter table plan
add constraint plan_pk primary key(plan_id);
alter table risk
add constraint risk_pk primary key(risk_id);
alter table property
add constraint property_pk primary key(property_id);
alter table product
add constraint product_pk primary key(product_id);

-- Create new foreign key constraints
alter table customer
add constraint customer_address_fk foreign key(contact_address_id) references contact_address(contact_address_id);
alter table contract
add constraint contract_customer_fk foreign key(customer_id) references customer(customer_id);
alter table contract
add constraint contract_payment_method_fk foreign key(payment_method_id) references payment_method(payment_method_id);
alter table contract
add constraint contract_risk_fk foreign key(risk_id) references risk(risk_id);
alter table contract
add constraint contract_plan_fk foreign key(plan_id) references plan(plan_id);
alter table contract
add constraint contract_property_fk foreign key(property_id) references property(property_id);
alter table property
add constraint property_product_fk foreign key(product_id) references product(product_id);

-- Create new other constraints
alter table contact_address
add constraint region_name_must_be_known check(region_name in ('eria', 'rhov', 'gond', 'mord'));
alter table customer
add constraint street_credit_must_be_in_range check(street_credit between 1 and 10);
alter table plan
add constraint warning_interest_percentage check(warning_interest between 0 and 1);