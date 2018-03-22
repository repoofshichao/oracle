## move导致索引失效

### 准备测试表
```
drop table t purge;

create table t as select * from dba_objects;
create index idx_object_id on t(object_id);

select * from t where object_id = 8;
```

执行计划：  
``` 
Execution Plan
----------------------------------------------------------
Plan hash value: 1296629646

-----------------------------------------------------------------------------------------------------
| Id  | Operation			    | Name	    | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT		    |		    |	  1 |	481 |	  2   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| T 	    |	  1 |	481 |	  2   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN		    | IDX_OBJECT_ID |	  1 |	    |	  1   (0)| 00:00:01 |
-----------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("OBJECT_ID"=8)

Note
-----
   - dynamic statistics used: dynamic sampling (level=2)


Statistics
----------------------------------------------------------
	 76  recursive calls
	  5  db block gets
	201  consistent gets
	  0  physical reads
	  0  redo size
       2476  bytes sent via SQL*Net to client
	607  bytes received via SQL*Net from client
	  2  SQL*Net roundtrips to/from client
	  3  sorts (memory)
	  0  sorts (disk)
	  1  rows processed
```
      
### move操作：
```
alter table t move;
select table_name,index_name,status from user_indexes where index_name = 'IDX_OBJECT_ID';

select * from t where object_id = 8;
```

执行计划：
```
Execution Plan
----------------------------------------------------------
Plan hash value: 1601196873

--------------------------------------------------------------------------
| Id  | Operation	  | Name | Rows  | Bytes | Cost (%CPU)| Time	 |
--------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |	 |     4 |  1924 |   110   (1)| 00:00:01 |
|*  1 |  TABLE ACCESS FULL| T	 |     4 |  1924 |   110   (1)| 00:00:01 |
--------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter("OBJECT_ID"=8)

Note
-----
   - dynamic statistics used: dynamic sampling (level=2)


Statistics
----------------------------------------------------------
	  8  recursive calls
	 11  db block gets
	490  consistent gets
	397  physical reads
	132  redo size
       2476  bytes sent via SQL*Net to client
	607  bytes received via SQL*Net from client
	  2  SQL*Net roundtrips to/from client
	  0  sorts (memory)
	  0  sorts (disk)
	  1  rows processed
```
执行计划变为全表扫描，说明move操作导致索引失效了。
修复索引：
alter index idx_object_id rebuild;

### 外键约束，索引失效
如果建立了外键约束，且对子表进行move操作，导致子表上的索引失效，更严重的是引起锁表。当删除子表的记录，然后删除父表的记录（不同的会话），这时会产生锁。
测试方式：
```
drop table t_p cascade constraints purge;
drop table t_c cascade constraints purge;

create table t_p(id number,name varchar2(30));
alter table t_p add constraints t_p_id_pk primary key(id);
create table t_c (id number,fid number,name varchar2(30));

alter table t_c add constraints fk_t_c foreign key(fid) references t_p(id);

alter table t_c move;

select sid from v$mystat where rownum=1;
delete from t_c where id =2;

select sid from v$mystat where rownum=1;
delete from t_p where id = 2000;

create index idx_ind_tc_fid on t_c(fid);
```
更详细的描述：
https://www.cnblogs.com/iyoume2008/p/6081669.html
