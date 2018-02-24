1.创建表
create table names(first varchar2(10), last varchar2(10));

2.导入数据
sqlldr user/<password> control=names.ctl

3.验证导入的数据
select * from names;

4.生成外部表的建表语句
sqlldr userid=user/<password> control=names.ctl external_table=generate_only

5.创建目录
create directory SYSTEM_DMP as '/home/oracle/test';

6.创建外部表
CREATE TABLE ext_names
(
  "FIRST" VARCHAR2(10),
  "LAST" VARCHAR2(10)
)
ORGANIZATION external
(
  TYPE oracle_loader
  DEFAULT DIRECTORY SYSTEM_DMP
  ACCESS PARAMETERS
  (
    RECORDS DELIMITED BY NEWLINE CHARACTERSET ZHS16GBK
    BADFILE 'SYSTEM_DMP':'names.bad'
    LOGFILE 'names.log_xt'
    READSIZE 1048576
    FIELDS TERMINATED BY "," LDRTRIM
    MISSING FIELD VALUES ARE NULL
    REJECT ROWS WITH ALL NULL FIELDS
    (
      "FIRST" CHAR(255)
        TERMINATED BY ",",
      "LAST" CHAR(255)
        TERMINATED BY ","
    )
  )
  location
  (
    'names.txt'
  )
)REJECT LIMIT UNLIMITED
/

7.从外部表读数据
truncate table names;

append hint加载会使用直接路径,产生更少的redo,缺点是锁表
INSERT /*+ append */ INTO NAMES
(
  FIRST,
  LAST
)
SELECT
  "FIRST",
  "LAST"
FROM ext_names
/

commit;

8.清理外部目录，外部表
DROP TABLE ext_names
DROP DIRECTORY SYSTEM_DMP
drop table names purge;
