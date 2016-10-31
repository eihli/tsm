CREATE TABLE worker_managers(id integer primary key, uuid char(36));
CREATE TABLE workers(id integer primary key, uuid char(36), state char(50), worker_manager_id integer, foreign key(worker_manager_id) references worker_managers(id));
