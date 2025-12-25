drop table if exists rpc_test;

create table rpc_test (
	customer_name varchar(99), email varchar(50), top_customer Boolean
);

insert into rpc_test (customer_name, email, top_customer)
VALUES ('Enter a name here', 'enter a working email address here', TRUE),
('Optional - add second name here', 'optional - add second working email address here', TRUE);