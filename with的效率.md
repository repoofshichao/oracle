## with 写法的执行效率
### 没有with时的sql
```
drop table t_with;
create table t_with as select rownum  id,a.* from dba_source a where rownum <100001;
set autotrace traceonly;
set linesize 1000;


select id,name 
  from t_with
 where id in (select max(id) 
                from t_with
               union all
              select min(id)
                from t_with
               union all
              select trunc(avg(id)) 
                from t_with
              )
/
```
执行计划
```
Execution Plan
----------------------------------------------------------
Plan hash value: 647530712

-----------------------------------------------------------------------------------
| Id  | Operation	       | Name	  | Rows  | Bytes | Cost (%CPU)| Time	  |
-----------------------------------------------------------------------------------
|   0 | SELECT STATEMENT       |	  |	3 |    96 |  1380   (1)| 00:00:01 |
|*  1 |  HASH JOIN	       |	  |	3 |    96 |  1380   (1)| 00:00:01 |
|   2 |   VIEW		       | VW_NSO_1 |	3 |    39 |  1034   (1)| 00:00:01 |
|   3 |    HASH UNIQUE	       |	  |	3 |    15 |  1034   (1)| 00:00:01 |
|   4 |     UNION-ALL	       |	  |	  |	  |	       |	  |
|   5 |      SORT AGGREGATE    |	  |	1 |	5 |	       |	  |
|   6 |       TABLE ACCESS FULL| T_WITH   |   100K|   488K|   345   (1)| 00:00:01 |
|   7 |      SORT AGGREGATE    |	  |	1 |	5 |	       |	  |
|   8 |       TABLE ACCESS FULL| T_WITH   |   100K|   488K|   345   (1)| 00:00:01 |
|   9 |      SORT AGGREGATE    |	  |	1 |	5 |	       |	  |
|  10 |       TABLE ACCESS FULL| T_WITH   |   100K|   488K|   345   (1)| 00:00:01 |
|  11 |   TABLE ACCESS FULL    | T_WITH   |   100K|  1855K|   345   (1)| 00:00:01 |
-----------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - access("ID"="MAX(ID)")


Statistics
----------------------------------------------------------
	 76  recursive calls
	 29  db block gets
       5086  consistent gets
       2462  physical reads
       2028  redo size
	695  bytes sent via SQL*Net to client
	607  bytes received via SQL*Net from client
	  2  SQL*Net roundtrips to/from client
	  6  sorts (memory)
	  0  sorts (disk)
	  3  rows processed
```
      
### 带with的sql
```
with agg as (select max(id) max,
                    min(id) min,
                    trunc(avg(id)) avg
               from t_with
            )
select id,
       name
  from t_with
 where id in
       (select max
          from agg
         union all
        select min
          from agg
         union all
        select avg
          from agg
       )
/
```

执行计划
```
Execution Plan
----------------------------------------------------------
Plan hash value: 1654566816

----------------------------------------------------------------------------------------------------------------------
| Id  | Operation				 | Name 		     | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT			 |			     |	   3 |	  96 |	 696   (1)| 00:00:01 |
|   1 |  TEMP TABLE TRANSFORMATION		 |			     |	     |	     |		  |	     |
|   2 |   LOAD AS SELECT (CURSOR DURATION MEMORY)| SYS_TEMP_0FD9D6605_2F3070 |	     |	     |		  |	     |
|   3 |    SORT AGGREGATE			 |			     |	   1 |	   5 |		  |	     |
|   4 |     TABLE ACCESS FULL			 | T_WITH		     |	 100K|	 488K|	 345   (1)| 00:00:01 |
|*  5 |   HASH JOIN				 |			     |	   3 |	  96 |	 352   (1)| 00:00:01 |
|   6 |    VIEW 				 | VW_NSO_1		     |	   3 |	  39 |	   6   (0)| 00:00:01 |
|   7 |     HASH UNIQUE 			 |			     |	   3 |	  39 |	   6   (0)| 00:00:01 |
|   8 |      UNION-ALL				 |			     |	     |	     |		  |	     |
|   9 |       VIEW				 |			     |	   1 |	  13 |	   2   (0)| 00:00:01 |
|  10 |        TABLE ACCESS FULL		 | SYS_TEMP_0FD9D6605_2F3070 |	   1 |	   5 |	   2   (0)| 00:00:01 |
|  11 |       VIEW				 |			     |	   1 |	  13 |	   2   (0)| 00:00:01 |
|  12 |        TABLE ACCESS FULL		 | SYS_TEMP_0FD9D6605_2F3070 |	   1 |	   5 |	   2   (0)| 00:00:01 |
|  13 |       VIEW				 |			     |	   1 |	  13 |	   2   (0)| 00:00:01 |
|  14 |        TABLE ACCESS FULL		 | SYS_TEMP_0FD9D6605_2F3070 |	   1 |	   5 |	   2   (0)| 00:00:01 |
|  15 |    TABLE ACCESS FULL			 | T_WITH		     |	 100K|	1855K|	 345   (1)| 00:00:01 |
----------------------------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   5 - access("ID"="MAX")


Statistics
----------------------------------------------------------
	113  recursive calls
	 10  db block gets
       2595  consistent gets
	  0  physical reads
	  0  redo size
	695  bytes sent via SQL*Net to client
	607  bytes received via SQL*Net from client
	  2  SQL*Net roundtrips to/from client
	  8  sorts (memory)
	  0  sorts (disk)
	  3  rows processed
```

### 使用with后，逻辑读和cost都小很多。效率明显，因为with的表缓存在了内存中多次使用。