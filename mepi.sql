/*
                      _ 
 _ __ ___   ___ _ __ (_)
| '_ ` _ \ / _ \ '_ \| |
| | | | | |  __/ |_) | |
|_| |_| |_|\___| .__/|_|
               |_|

Middle Earth Property Insurance (c) 2021 Felicitas Pojtinger and contributors

SPDX-License-Identifier: AGPL-3.0

Full source code: https://github.com/pojntfx/mepi
To clear the database before starting: https://github.com/pojntfx/uni-db1-notes#reset-everything
*/

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
alter table contact_addresses drop constraint region_name_must_be_known;
alter table customers drop constraint street_credit_must_be_in_range;
alter table plans drop constraint warning_interest_percentage;
alter table claims drop constraint claim_rejected_boolean;
alter table contracts drop constraint contract_risk_percentage;

-- Drop old foreign key constraints
alter table customers drop constraint customer_address_fk;
alter table contracts drop constraint contract_customer_fk;
alter table contracts drop constraint contract_payment_method_fk;
alter table contracts drop constraint contract_plan_fk;
alter table contracts drop constraint contract_property_fk;
alter table properties drop constraint property_product_fk;
alter table bills drop constraint bill_contract_fk;
alter table payments drop constraint payment_bill_fk;
alter table claims drop constraint claim_contract_fk;
alter table payouts drop constraint payout_claim_fk;

-- Drop primary key constraints
alter table contact_addresses drop constraint contact_address_pk;
alter table customers drop constraint customer_pk;
alter table contracts drop constraint contract_pk;
alter table payment_methods drop constraint payment_method_pk;
alter table plans drop constraint plan_pk;
alter table properties drop constraint property_pk;
alter table payments drop constraint payment_pk;
alter table bills drop constraint bill_pk;
alter table payouts drop constraint payout_pk;
alter table claims drop constraint claim_pk;

-- Drop old tables
drop table contact_addresses;
drop table customers;
drop table contracts;
drop table plans;
drop table properties;
drop table products;
drop table bills;
drop table payments;
drop table claims;
drop table payouts;
drop table payment_methods;

-- Enable errors
whenever sqlerror exit sql.sqlcode;

-- Create new tables
create table contact_addresses (
    region_name char(4) not null,
    city varchar2(80) not null,
    street varchar2(80) not null,
    house_name varchar2(80) not null
);
create table customers (
    first_name varchar2(80) not null,
    last_name varchar2(80),
    birthday date,
    street_credit number,
    contact_address_id number
);
create table contracts (
    acceptance_date date default sysdate not null,
    duration interval year to month not null,
    customer_id number,
    payment_method_id number,
    plan_id number,
    property_id number,
    risk_reason varchar2(255) not null,
    risk_multiplier float not null
);
create table plans (
    name varchar(80) not null,
    base_monthly_cost float(2) not null,
    initial_cost float(2) not null,
    warning_interval interval year to month not null,
    max_warnings number not null,
    warning_interest float not null
);
create table products (
    name varchar2(80),
    description varchar2(255)
);
create table properties (product_id number);
create table bills (contract_id number);
create table payments (
    bill_id number,
    payment_date date default sysdate
);
create table claims (
    compensation_amount float(2),
    rejected number not null,
    rejected_reason varchar2(255),
    contract_id number,
    claim_date date default sysdate
);
create table payouts (
    claim_id number,
    payout_date date default sysdate
);
create table payment_methods (
    priority integer not null,
    customer_id integer,
    external_id varchar2(80),
    ledger varchar2(255) not null
);

-- Create identity columns
alter table contact_addresses
add contact_address_id number;
alter table customers
add customer_id number;
alter table contracts
add contract_id number;
alter table payment_methods
add payment_method_id number;
alter table plans
add plan_id number;
alter table properties
add property_id number;
alter table products
add product_id number;
alter table bills
add bill_id number;
alter table payments
add payment_id number;
alter table claims
add claim_id number;
alter table payouts
add payout_id number;

-- Create new primary key constraints
alter table contact_addresses
add constraint contact_address_pk primary key(contact_address_id);
alter table customers
add constraint customer_pk primary key(customer_id);
alter table contracts
add constraint contract_pk primary key(contract_id);
alter table payment_methods
add constraint payment_method_pk primary key(payment_method_id);
alter table plans
add constraint plan_pk primary key(plan_id);
alter table properties
add constraint property_pk primary key(property_id);
alter table products
add constraint product_pk primary key(product_id);
alter table bills
add constraint bill_pk primary key(bill_id);
alter table payments
add constraint payment_pk primary key(payment_id);
alter table payouts
add constraint payout_pk primary key(payout_id);
alter table claims
add constraint claim_pk primary key(claim_id);

-- Create new foreign key constraints
alter table customers
add constraint customer_address_fk foreign key(contact_address_id) references contact_addresses(contact_address_id);
alter table contracts
add constraint contract_customer_fk foreign key(customer_id) references customers(customer_id);
alter table contracts
add constraint contract_payment_method_fk foreign key(payment_method_id) references payment_methods(payment_method_id);
alter table contracts
add constraint contract_plan_fk foreign key(plan_id) references plans(plan_id);
alter table contracts
add constraint contract_property_fk foreign key(property_id) references properties(property_id);
alter table properties
add constraint property_product_fk foreign key(product_id) references products(product_id);
alter table bills
add constraint bill_contract_fk foreign key(contract_id) references contracts(contract_id);
alter table payments
add constraint payment_bill_fk foreign key(bill_id) references bills(bill_id);
alter table claims
add constraint claim_contract_fk foreign key(contract_id) references contracts(contract_id);
alter table payouts
add constraint payout_claim_fk foreign key(claim_id) references claims(claim_id);

-- Create new other constraints
alter table contact_addresses
add constraint region_name_must_be_known check(region_name in ('eria', 'rhov', 'gond', 'mord'));
alter table customers
add constraint street_credit_must_be_in_range check(
        street_credit between 1 and 10
    );
alter table plans
add constraint warning_interest_percentage check(
        warning_interest between 0 and 2
    );
alter table claims
add constraint claim_rejected_boolean check(rejected in (0, 1));
alter table contracts
add constraint contract_risk_percentage check(
        risk_multiplier between 0 and 2
    );

-- Create new views
create or replace view liabilities as
select sum(claims.compensation_amount) as componensation_amount
from claims
where claims.rejected = 0;
create or replace view user_overview as
select customers.customer_id,
    customers.first_name,
    customers.last_name,
    plans.name
from customers,
    contracts,
    plans
where customers.customer_id = contracts.customer_id
    and contracts.plan_id = plans.plan_id;
create or replace view demands as
select bills.bill_id,
    customers.customer_id,
    customers.first_name,
    customers.last_name,
    plans.base_monthly_cost
from bills,
    payments,
    contracts,
    customers,
    plans
where bills.bill_id not in (payments.bill_id)
    and bills.contract_id = contracts.contract_id
    and contracts.customer_id = customers.customer_id
    and contracts.plan_id = plans.plan_id;
create or replace view product_overview as
select products.name,
    count(*) as times_insured
from products,
    properties
where products.product_id = properties.product_id (+)
group by products.name;

-- Create new triggers
create or replace trigger contract_date_ensure before
insert on contracts for each row begin :new.acceptance_date := sysdate;
end;
/
create or replace trigger street_credibility_ensure before
update on customers for each row begin if :new.street_credit < :old.street_credit then
update contracts
set risk_multiplier = case
        when (
            risk_multiplier > 0.1
            and risk_multiplier < 2
        ) then risk_multiplier + 0.1
        else risk_multiplier
    end
where contracts.customer_id = customer_id;
elsif :new.street_credit > :old.street_credit then
update contracts
set risk_multiplier = case
        when (
            risk_multiplier > 0.1
            and risk_multiplier < 2
        ) then risk_multiplier - 0.1
        else risk_multiplier
    end
where contracts.customer_id = customer_id;
end if;
end;
/ 
-- Create new indexes
create index customer_full_name on customers(first_name, last_name);
create index product_name_description on products(name, description);

-- Create test data

-- Plans
insert into plans (
        plan_id,
        name,
        base_monthly_cost,
        initial_cost,
        warning_interval,
        max_warnings,
        warning_interest
    )
values (1, 'Weapon Insurance', 12, 4, '0-6', 4, 1.2);
insert into plans (
        plan_id,
        name,
        base_monthly_cost,
        initial_cost,
        warning_interval,
        max_warnings,
        warning_interest
    )
values (2, 'Horse Insurance', 6, 2, '0-6', 4, 1.4);
insert into plans (
        plan_id,
        name,
        base_monthly_cost,
        initial_cost,
        warning_interval,
        max_warnings,
        warning_interest
    )
values (3, 'Hobbit Hole Insurance', 16, 6, '0-4', 8, 1.6);

-- Aragon
insert into contact_addresses (
        contact_address_id,
        region_name,
        city,
        street,
        house_name
    )
values(
        2,
        'gond',
        'Minas Tirith',
        'White Tower',
        'Top Tower'
    );
insert into customers (
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
insert into products (product_id, name, description)
values(
        2,
        'AndÃºril',
        'AndÃºril, also called the Flame of the West, was the sword which was reforged from the shards of Narsil'
    );
insert into properties (property_id, product_id)
values(2, 2);
insert into payment_methods (
        payment_method_id,
        priority,
        customer_id,
        external_id,
        ledger
    )
values(2, 1, 2, 'Aragorn', 'Bank of Lake-town');
insert into contracts (
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
        1,
        2,
        'King of Gondor',
        1.2
    );
insert into claims (
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
insert into bills (bill_id, contract_id)
values(2, 2);
insert into payments (payment_id, bill_id, payment_date)
values(2, 2, to_date('10.11.3017', 'DD.MM.YYYY'));
insert into payouts (payout_id, claim_id, payout_date)
values(2, 2, to_date('16.11.3017', 'DD.MM.YYYY'));

-- Samwise
insert into contact_addresses (
        contact_address_id,
        region_name,
        city,
        street,
        house_name
    )
values(
        1,
        'eria',
        'The Shire',
        'Gardenerstreet',
        'Under the Stone'
    );
insert into customers (
        customer_id,
        first_name,
        last_name,
        birthday,
        street_credit,
        contact_address_id
    )
values(
        1,
        'Samwise',
        'Gamgee',
        to_date('06.04.2980', 'DD.MM.YYYY'),
        8,
        1
    );
insert into products (product_id, name, description)
values(
        1,
        'barrow blades',
        'The Barrow-blades had long, leaf-shaped blades, which were damasked with serpent-forms in red and gold'
    );
insert into properties (property_id, product_id)
values(1, 1);
insert into payment_methods (
        payment_method_id,
        priority,
        customer_id,
        external_id,
        ledger
    )
values(1, 1, 1, 'Sam', 'Trust of Sackville-Baggins');
insert into contracts (
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
        1,
        to_date('06.04.2980', 'DD.MM.YYYY'),
        '2-0',
        1,
        1,
        1,
        1,
        'Frodos companion',
        1.15
    );
insert into claims (
        claim_id,
        compensation_amount,
        rejected,
        rejected_reason,
        contract_id,
        claim_date
    )
values(
        1,
        80,
        0,
        null,
        1,
        to_date('14.11.3016', 'DD.MM.YYYY')
    );
insert into bills (bill_id, contract_id)
values(1, 1);
insert into payments (payment_id, bill_id, payment_date)
values(1, 1, to_date('10.11.3016', 'DD.MM.YYYY'));
insert into payouts (payout_id, claim_id, payout_date)
values(1, 1, to_date('16.11.3016', 'DD.MM.YYYY'));

-- Gandalf the Grey
insert into contact_addresses (
        contact_address_id,
        region_name,
        city,
        street,
        house_name
    )
values(
        3,
        'eria',
        'Rivendell',
        'Wanderers passage',
        'Guest appartment'
    );
insert into customers (
        customer_id,
        first_name,
        last_name,
        birthday,
        street_credit,
        contact_address_id
    )
values(
        3,
        'Gandalf',
        'The Grey',
        NULL,
        10,
        3
    );
insert into products (product_id, name, description)
values(
        3,
        'Staff',
        'A base model wizard staff of the Istari'
    );
insert into properties (property_id, product_id)
values(3, 3);
insert into payment_methods (
        payment_method_id,
        priority,
        customer_id,
        external_id,
        ledger
    )
values(3, 1, 3, 'Gandalf the Grey', 'Bank of Rivendell');
insert into contracts (
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
        3,
        to_date('06.04.2980', 'DD.MM.YYYY'),
        '2-0',
        3,
        3,
        1,
        3,
        'Is a well-known wizard with remarkable powers',
        0.6
    );
insert into claims (
        claim_id,
        compensation_amount,
        rejected,
        rejected_reason,
        contract_id,
        claim_date
    )
values(
        3,
        1200,
        0,
        null,
        3,
        to_date('03.07.3018', 'DD.MM.YYYY')
    );
insert into bills (bill_id, contract_id)
values(3, 3);
insert into payouts (payout_id, claim_id, payout_date)
values(3, 3, to_date('08.07.3018', 'DD.MM.YYYY'));

-- Legolas Greenleaf
insert into contact_addresses (
        contact_address_id,
        region_name,
        city,
        street,
        house_name
    )
values(
        4,
        'eria',
        'Mirkwood',
        'By the lake',
        'House of the elves'
    );
insert into customers (
        customer_id,
        first_name,
        last_name,
        birthday,
        street_credit,
        contact_address_id
    )
values(
        4,
        'Legolas',
        'Greenleaf',
        TO_DATE('14.03.0185', 'DD.MM.YYYY'),
        9,
        4
    );
insert into products (product_id, name, description)
values(
        4,
        'Dual Long Knives',
        'Base Model Long Knifes'
    );
insert into properties (property_id, product_id)
values(4, 4);
insert into payment_methods (
        payment_method_id,
        priority,
        customer_id,
        external_id,
        ledger
    )
values(
        4,
        1,
        4,
        'Legolas Greenleaf',
        'Bank of Rivendell'
    );
insert into contracts (
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
        4,
        to_date('06.04.3018', 'DD.MM.YYYY'),
        '2-0',
        4,
        4,
        1,
        4,
        'Remarkable fighter. Somehow often in trouble',
        1
    );
insert into claims (
        claim_id,
        compensation_amount,
        rejected,
        rejected_reason,
        contract_id,
        claim_date
    )
values(
        4,
        500,
        1,
        'We cannot pay him if he looses one of his two knifes',
        4,
        to_date('03.07.3018', 'DD.MM.YYYY')
    );
insert into bills (bill_id, contract_id)
values(4, 4);
insert into payouts (payout_id, claim_id, payout_date)
values(4, 4, to_date('08.07.3018', 'DD.MM.YYYY'));

-- Frodo
insert into contact_addresses (
        contact_address_id,
        region_name,
        city,
        street,
        house_name
    )
values(
        5,
        'eria',
        'The Shire',
        'Chosenstreet',
        'The lowered ceiling'
    );
insert into customers (
        customer_id,
        first_name,
        last_name,
        birthday,
        street_credit,
        contact_address_id
    )
values(
        5,
        'Frodo',
        'Beutlin',
        to_date('22.9.2968', 'DD.MM.YYYY'),
        8,
        5
    );
insert into products (product_id, name, description)
values(
        5,
        'short sword',
        'Handy short sword'
    );
insert into properties (property_id, product_id)
values(5, 5);
insert into payment_methods (
        payment_method_id,
        priority,
        customer_id,
        external_id,
        ledger
    )
values(5, 5, 5, 'Frodo', 'Trust of Sackville-Baggins');
insert into contracts (
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
        5,
        to_date('10.11.3010', 'DD.MM.YYYY'),
        '2-0',
        5,
        5,
        1,
        5,
        'Is on a heavy mission',
        1.8
    );
insert into claims (
        claim_id,
        compensation_amount,
        rejected,
        rejected_reason,
        contract_id,
        claim_date
    )
values(
        5,
        10,
        1,
        'There are still outstanding receivables',
        5,
        to_date('12.10.3010', 'DD.MM.YYYY')
    );
insert into bills (bill_id, contract_id)
values(5, 5);
insert into payments (payment_id, bill_id, payment_date)
values(5, 5, to_date('12.08.3011', 'DD.MM.YYYY'));

-- Gimli 
insert into contact_addresses (
        contact_address_id,
        region_name,
        city,
        street,
        house_name
    )
values(
        6,
        'eria',
        'Glittering Caves',
        'Cavetown',
        'Gimlis Cave'
    );
insert into customers (
        customer_id,
        first_name,
        last_name,
        birthday,
        street_credit,
        contact_address_id
    )
values(
        6,
        'Gimli',
        'Caves',
        TO_DATE('5.10.2978', 'DD.MM.YYYY'),
        9,
        6
    );
insert into products (product_id, name, description)
values(
        6,
        'Battle axe',
        'Chop every tree and enemy'
    );
insert into properties (property_id, product_id)
values(6, 6);
insert into payment_methods (
        payment_method_id,
        priority,
        customer_id,
        external_id,
        ledger
    )
values(6, 1, 6, 'Gimli (dwarf)', 'Bank of Rivendell');
insert into contracts (
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
        6,
        to_date('12.01.3017', 'DD.MM.YYYY'),
        '2-0',
        6,
        6,
        1,
        6,
        'Short but strong',
        1
    );
insert into claims (
        claim_id,
        compensation_amount,
        rejected,
        rejected_reason,
        contract_id,
        claim_date
    )
values(
        6,
        200,
        1,
        'We do not pay dwarfs (even though they are customers)',
        6,
        to_date('04.04.3019', 'DD.MM.YYYY')
    );
insert into bills (bill_id, contract_id)
values(6, 6);

-- Legolas Greenleaf
insert into products (product_id, name, description)
values(
        7,
        'Roach',
        'Brown strong horse'
    );
insert into properties (property_id, product_id)
values(7, 7);
insert into contracts (
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
        7,
        to_date('06.04.3019', 'DD.MM.YYYY'),
        '2-0',
        4,
        4,
        2,
        7,
        'Remarkable fighter. Somehow often in trouble',
        1
    );
insert into bills (bill_id, contract_id)
values(7, 7);

-- Gandalf the Grey
insert into products (product_id, name, description)
values(
        8,
        'Glamdring',
        'An elven sword found in a troll cave'
    );
insert into properties (property_id, product_id)
values(8, 8);
insert into contracts (
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
        8,
        to_date('06.04.2982', 'DD.MM.YYYY'),
        '2-0',
        3,
        3,
        1,
        8,
        'Is a well-known wizard with remarkable powers',
        0.6
    );
insert into bills (bill_id, contract_id)
values(8, 8);

-- Demo

-- Complex query: Shows all products which Legolas has insured
select *
from products,
    properties,
    contracts,
    customers
where products.product_id = properties.product_id
    and properties.property_id = contracts.property_id
    and contracts.customer_id = customers.customer_id
    and customers.first_name = 'Legolas';

-- Test the views
select *
from liabilities;
select *
from user_overview
order by customer_id desc;
select *
from demands;
select *
from product_overview;

-- Test the tables
select *
from contact_addresses;
select *
from customers;
select *
from contracts;
select *
from payment_methods;
select *
from properties;
select *
from products;
select *
from bills;
select *
from plans;
select *
from payments;
select *
from payouts;
select *
from claims;

-- Test the update trigger (the insert trigger is already being triggered by the test data statements)

-- First, try to increase the street credit; this should decrease each contract's risk for the customers by 0.1.
select * from customers where customer_id = 2;
select * from contracts where customer_id = 2;

update customers
set street_credit = 10
where customer_id = 2;

-- Now decrease the street credit. This should increase each contract's risk for the customers by 0.1.
select * from customers where customer_id = 2;
select * from contracts where customer_id = 2;

update customers
set street_credit = 9
where customer_id = 2;

select * from customers where customer_id = 2;
select * from contracts where customer_id = 2;