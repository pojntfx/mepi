-- Disable errors
whenever sqlerror continue;

-- Drop old views
drop view liabilities;
drop view user_overview;
drop view demands;

-- Drop old other constraints
alter table contact_address drop constraint region_name_must_be_known;
alter table customer drop constraint street_credit_must_be_in_range;
alter table plan drop constraint warning_interest_percentage;
alter table claim drop constraint claim_rejected_boolean;

-- Drop old foreign key constraints
alter table customer drop constraint customer_address_fk;
alter table contract drop constraint contract_customer_fk;
alter table contract drop constraint contract_payment_method_fk;
alter table contract drop constraint contract_plan_fk;
alter table contract drop constraint contract_risk_fk;
alter table contract drop constraint contract_property_fk;
alter table property drop constraint property_product_fk;
alter table bill drop constraint bill_contract_fk;
alter table payment drop constraint payment_bill_fk;
alter table claim drop constraint claim_contract_fk;
alter table payout drop constraint payout_claim_fk;

-- Drop primary key constraints
alter table contact_address drop constraint contact_address_pk;
alter table customer drop constraint customer_pk;
alter table contract drop constraint contract_pk;
alter table payment_method drop constraint payment_method_pk;
alter table plan drop constraint plan_pk;
alter table risk drop constraint risk_pk;
alter table property drop constraint property_pk;
alter table payment drop constraint payment_pk;
alter table bill drop constraint bill_pk;
alter table payout drop constraint payout_pk;
alter table claim drop constraint claim_pk;

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
    product_id number
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
    priority integer not null,
    customer_id integer,
    external_id integer,
    ledger varchar2(255) not null
);
create table risk (
    reason varchar2(255) not null,
    multiplier float not null
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
alter table bill
add bill_id number generated always as identity;
alter table payment
add payment_id number generated always as identity;
alter table claim
add claim_id number generated always as identity;
alter table payout
add payout_id number generated always as identity;

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
alter table bill
add constraint bill_pk primary key(bill_id);
alter table payment
add constraint payment_pk primary key(payment_id);
alter table payout
add constraint payout_pk primary key(payout_id);
alter table claim
add constraint claim_pk primary key(claim_id);

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
alter table bill
add constraint bill_contract_fk foreign key(contract_id) references contract(contract_id);
alter table payment
add constraint payment_bill_fk foreign key(bill_id) references bill(bill_id);
alter table claim
add constraint claim_contract_fk foreign key(contract_id) references contract(contract_id);
alter table payout
add constraint payout_claim_fk foreign key(claim_id) references claim(claim_id);

-- Create new other constraints
alter table contact_address
add constraint region_name_must_be_known check(region_name in ('eria', 'rhov', 'gond', 'mord'));
alter table customer
add constraint street_credit_must_be_in_range check(street_credit between 1 and 10);
alter table plan
add constraint warning_interest_percentage check(warning_interest between 0 and 1);
alter table claim
add constraint claim_rejected_boolean check(rejected in (0,1));

-- Create new views
create or replace view liabilities as
select sum(claim.compensation_amount) as componensation_amount
from claim
where claim.claim_date between (sysdate - 30) and sysdate;
create or replace view user_overview as
select customer.customer_id,
    customer.first_name,
    customer.last_name,
    plan.name,
    contract.risk_id
from customer,
    contract,
    plan
where customer.customer_id = contract.customer_id
    and contract.plan_id = plan.plan_id;
create or replace view demands as
select bill.bill_id,
    customer.first_name,
    customer.last_name,
    plan.base_monthly_cost
from bill,
    payment,
    contract,
    customer,
    plan
where bill.bill_id not in (payment.bill_id)
    and bill.contract_id = contract.contract_id
    and contract.customer_id = customer.customer_id
    and contract.plan_id = plan.plan_id;