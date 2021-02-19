-- Drop old tables

whenever sqlerror continue;

drop table contact_address;
drop table customer;

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