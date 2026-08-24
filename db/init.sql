-- jumpbox VM에서 psql로 1회 실행 (vm-init.sh가 postgresql-client를 이미 설치해둔다):
--   psql "host=<postgresql_fqdn> port=5432 dbname=postgres user=psqladmin sslmode=require" -f init.sql
-- <postgresql_fqdn>과 관리자 비밀번호는 terraform output / secrets.auto.tfvars 참고.

CREATE DATABASE cicd_poc_db WITH ENCODING = 'UTF8' TEMPLATE = template0;

\c cicd_poc_db

CREATE TABLE "Employee" (
    "EmployeeId" SERIAL PRIMARY KEY,
    "LastName"  VARCHAR(100) NOT NULL,
    "FirstName" VARCHAR(100) NOT NULL,
    "Title"     VARCHAR(100)
);

INSERT INTO "Employee" ("LastName", "FirstName", "Title") VALUES
    ('Kim',   'Minjun',  'DevOps Engineer'),
    ('Lee',   'Seoyeon', 'Backend Developer'),
    ('Park',  'Jiho',    'Platform Architect'),
    ('Choi',  'Yuna',    'SRE');
