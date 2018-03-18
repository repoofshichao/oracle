## 创建索引通过online方式  
### 构建测试数据  
```
drop table t purge;
create table t as select * from dba_objects;
insert into t select * from t;
insert into t select * from t;
insert into t select * from t;
insert into t select * from t;
insert into t select * from t;
insert into t select * from t;
insert into t select * from t;

commit;
select sid from v$mystat where rownum = 1;


set timing on;
create index idx_object_id on t(object_id) online;
```
```

       SID
----------
	 1

```

### 新建一个会话，update不阻塞，建立索引被阻塞   
```
set linesize 1000
select sid from v$mystat where rownum =1;
update t set object_id=9999 where object_id=8;
```
```

       SID
----------
	47

```
### 观察锁  
```
set linesize 1000
select * from v$lock where sid in (1,47);

select /*+no_merge(a) no_merge(b)*/ 
       (select username from v$session where sid=a.sid) blocker, a.sid, 'is blocker',
       (select username from v$session where sid=b.sid) blockee, b.sid
  from v$lock a, v$lock b
 where a.block=1 and b.request>0
   and a.id1=b.id1
   and a.id2 = b.id2
/
```
```
BLOCKER 																SID 'ISBLOCKER BLOCKEE														            SID
-------------------------------------------------------------------------------------------------------------------------------- ---------- ---------- -------------------------------------------------------------------------------------------------------------------------------- ----------
C##user																 47 is blocker C##user													      1

```