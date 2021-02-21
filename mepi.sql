-- Disable errors
whenever sqlerror continue;

-- Drop old indexes
drop index customer_full_name;
drop index product_name_description;

-- Drop old triggers
drop trigger contract_date_ensure;
drop trigger street_credibility_ensure;

-- Drop old views
drop view liabilities;
drop view user_overview;
drop view demands;
drop view product_overview;

-- Drop old other constraints
alter table contact_address drop constraint region_name_must_be_known;
alter table customer drop constraint street_credit_must_be_in_range;
alter table plan drop constraint warning_interest_percentage;
alter table claim drop constraint claim_rejected_boolean;
alter table contract drop constraint contract_risk_percentage;

-- Drop old foreign key constraints
alter table customer drop constraint customer_address_fk;
alter table contract drop constraint contract_customer_fk;
alter table contract drop constraint contract_payment_method_fk;
alter table contract drop constraint contract_plan_fk;
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
    property_id number,
    risk_reason varchar2(255) not null,
    risk_multiplier float not null
);
create table plan (
    name varchar(80) not null,
    base_monthly_cost float(2) not null,
    initial_cost float(2) not null,
    warning_interval interval year to month not null,
    max_warnings number not null,
    warning_interest float not null
);
create table product (
    name varchar2(80),
    description varchar2(255)
);
create table property (
    product_id number
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
    external_id varchar2(80),
    ledger varchar2(255) not null
);

-- Create identity columns
alter table contact_address
add contact_address_id number;
alter table customer
add customer_id number;
alter table contract
add contract_id number;
alter table payment_method
add payment_method_id number;
alter table plan
add plan_id number;
alter table property
add property_id number;
alter table product
add product_id number;
alter table bill
add bill_id number;
alter table payment
add payment_id number;
alter table claim
add claim_id number;
alter table payout
add payout_id number;

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
alter table contract
add constraint contract_risk_percentage check(risk_multiplier between 0 and 2);

-- Create new views
create or replace view liabilities as
select sum(claim.compensation_amount) as componensation_amount
from claim
where claim.claim_date between (sysdate - 30) and sysdate;
create or replace view user_overview as
select customer.customer_id,
    customer.first_name,
    customer.last_name,
    plan.name
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
create or replace view product_overview as
select product.name,
    count(*) as times_insured
from product,
    property
where product.product_id = property.product_id (+)
group by product.name;

-- Create new triggers
create or replace trigger contract_date_ensure
before insert
on contract
for each row 
begin
    :new.acceptance_date := sysdate;
end;
/
create or replace trigger street_credibility_ensure
before update
on customer
for each row
begin
    if :new.street_credit < :old.street_credit then
        update contract set risk_multiplier = case when ( risk_multiplier > 0.1 and risk_multiplier < 2 ) then risk_multiplier + 0.1 else risk_multiplier end where contract.customer_id = customer_id;
    elsif :new.street_credit > :old.street_credit then
        update contract set risk_multiplier = case when ( risk_multiplier > 0.1 and risk_multiplier < 2 ) then risk_multiplier - 0.1 else risk_multiplier end where contract.customer_id = customer_id;
    end if;
end;
/

-- Create new indexes
create index customer_full_name on customer(first_name, last_name);
create index product_name_description on product(name, description);

-- Create test data

-- Aragon
insert into contact_address (
        contact_address_id,
        region_name,
        city,
        street,
        house_name
    )
values(2, 'gond', 'Minas Tirith', 'White Tower', 7);
insert into customer (
        customer_id,
        first_name,
        last_name,
        birthday,
        street_credit,
        contact_address_id
    )
values(
        2,
        'Aragorn II',
        'Elessar',
        to_date('01.03.2931', 'DD.MM.YYYY'),
        9,
        2
    );
insert into plan (
        plan_id,
        name,
        base_monthly_cost,
        initial_cost,
        warning_interval,
        max_warnings,
        warning_interest
    )
values(2, 'Weapon', 20, 16, '0-6', 6, 0.25);
insert into product (product_id, name, description)
values(
        2,
        'Andúril',
        'Andúril, also called the Flame of the West, was the sword which was reforged from the shards of Narsil'
    );
insert into property (property_id, product_id)
values(2, 2);
insert into payment_method (
        payment_method_id,
        priority,
        customer_id,
        external_id,
        ledger
    )
values(2, 1, 2, 2, 'Bank of Lake-town');
insert into contract (
        contract_id,
        acceptance_date,
        duration,
        customer_id,
        payment_method_id,
        plan_id,
        property_id,
        risk_reason,
        risk_multiplier
    )
values(
        2,
        to_date('06.04.2980', 'DD.MM.YYYY'),
        '2-0',
        2,
        2,
        2,
        2,
        'King',
        1.2
    );
insert into claim (
        claim_id,
        compensation_amount,
        rejected,
        rejected_reason,
        contract_id,
        claim_date
    )
values(
        2,
        200,
        0,
        null,
        2,
        to_date('14.11.3017', 'DD.MM.YYYY')
    );
insert into bill (bill_id, contract_id)
values(2, 2);
insert into payment (payment_id, bill_id, payment_date)
values(2, 2, to_date('10.11.3017', 'DD.MM.YYYY'));
insert into payout (payout_id, claim_id, payout_date)
values(2, 2, to_date('16.11.3017', 'DD.MM.YYYY'));