## sql硬解析的发现

### 执行硬解析的sql
```
drop table t purge;
create table t(x int);
select * from v$mystat where rownum=1;

begin 
    for i in 1..100000
    loop
        execute immediate
        'insert into t values('||i||')';
    end loop;
    commit;
end;
/
```

### 执行定位问题的sql
```
drop table t_bind_sql purge;
create table t_bind_sql as select sql_text,module from v$sqlarea;
alter table t_bind_sql add sql_text_wo_constants varchar2(1000);

create or replace function
remove_constants(p_query in varchar2) return varchar2 
as 
    l_query long;
    l_char varchar2(10);
    l_in_quotes boolean default FALSE;
begin
    for i in 1..length(p_query)
    loop
        l_char := substr(p_query,i,1);
        if ( l_char = '''' and l_in_quotes )
        then
            l_in_quotes := FALSE;
        elsif ( l_char = '''' and NOT l_in_quotes )
        then
            l_in_quotes := TRUE;
            l_query := l_query || '''#';
        end if;
        if ( NOT l_in_quotes ) then
            l_query := l_query || l_char;
        end if;
    end loop;
    l_query := translate( l_query, '0123456789', '@@@@@@@@@@' );
    for i in 0 .. 8 loop
        l_query := replace( l_query, lpad('@',10-i,'@'), '@' );
        l_query := replace( l_query, lpad(' ',10-i,' '), ' ' );
    end loop;
    return upper(l_query);
end;
/
update t_bind_sql set sql_text_wo_constants = remove_constants(sql_text);
commit;   
```

### 显示结果的sql
* 如果没有结果，可以把having count(*) > 100 的100改小一些。

```
set linesize 266
col  sql_text_wo_constants format a30
col  module format  a30
col  CNT format  999999
select sql_text_wo_constants, module,count(*) CNT
  from t_bind_sql
 group by sql_text_wo_constants,module
having count(*) > 100
 order by 3 desc;
 
```

### 结果
```
SQL_TEXT_WO_CONSTANTS	       MODULE				  CNT
------------------------------ ------------------------------ -------
INSERT INTO T VALUES(@)        sqlplus@localhost.localdomain	   28
			       (TNS V1-V3)

```
