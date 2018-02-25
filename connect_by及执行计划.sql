--1.构造测试数据。使用oracle12C的demo：/u01/app/oracle/product/12.2.1/db/demo/schema/human_resources
--构造表employees

--2.
set linesize 1000
set pagesize 1000

alter session set statistics_level=all;

select /*+connect_by_filtering*/level, employee_id,prior first_name as manager, first_name,employee_id from employees start with manager_id is null connect by prior employee_id = manager_id;

select * from table(dbms_xplan.display_cursor(null,null,'allstats last'));

--3.查询计划如下：
PLAN_TABLE_OUTPUT
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SQL_ID	5rd08uuy2vx00, child number 0
-------------------------------------
select /*+connect_by_filtering*/ employee_id,prior first_name as
manager, first_name,employee_id from employees start with manager_id is
null connect by prior employee_id = manager_id

Plan hash value: 1278685279

----------------------------------------------------------------------------------------------------------------------------
| Id  | Operation		  | Name      | Starts | E-Rows | A-Rows |   A-Time   | Buffers |  OMem |  1Mem | Used-Mem |
----------------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT	  |	      |      1 |	|    107 |00:00:00.01 |      35 |	|	|	   |
|*  1 |  CONNECT BY WITH FILTERING|	      |      1 |	|    107 |00:00:00.01 |      35 |  9216 |  9216 | 8192	(0)|
|*  2 |   TABLE ACCESS FULL	  | EMPLOYEES |      1 |      1 |      1 |00:00:00.01 |       7 |	|	|	   |
|*  3 |   HASH JOIN		  |	      |      4 |      6 |    106 |00:00:00.01 |      28 |  2545K|  2545K| 1658K (0)|
|   4 |    CONNECT BY PUMP	  |	      |      4 |	|    107 |00:00:00.01 |       0 |	|	|	   |
|   5 |    TABLE ACCESS FULL	  | EMPLOYEES |      4 |    107 |    428 |00:00:00.01 |      28 |	|	|	   |
----------------------------------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - access("MANAGER_ID"=PRIOR NULL)
   2 - filter("MANAGER_ID" IS NULL)
   3 - access("connect$_by$_pump$_002"."prior employee_id "="MANAGER_ID")

--4.查询计划解读
使用hint，强制走filter，filter的效率只比nested loops高一点。原因是对于重复的连接字段，filter不会再执行全表扫描。
从查询出的记录可以看出，level一共有4级。所以执行计划中id=4的地方，执行了4次。id=5的地方每次都进行全表扫描。

--5.查看表和索引的统计信息收集时间
select t.TABLE_NAME,t.NUM_ROWS,t.BLOCKS,t.LAST_ANALYZED from user_tables t  where table_name in ('EMPLOYEES');
select table_name,index_name,t.blevel,t.num_rows,t.leaf_blocks,t.last_analyzed from user_indexes t  where table_name in ('EMPLOYEES');