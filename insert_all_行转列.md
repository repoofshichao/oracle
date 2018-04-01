## insert all 行转列
```
drop table sales_source_data purge;

create table sales_source_data
( 
  employee_id number(6),
  week_id number(2),
  sales_mon number(8,2),
  sales_tue number(8,2),
  sales_wed number(8,2),
  sales_thur number(8,2),
  sales_fri number(8,2)
);

insert into sales_source_data values(176,6,2000,3000,4000,5000,6000);
commit;

drop table sales_info purge;
create table sales_info 
( 
  employee_id number(6),
  week number(2),
  sales number(8,2)
);


insert all
       into sales_info values(employee_id,week_id,sales_mon)
       into sales_info values(employee_id,week_id,sales_tue)
       into sales_info values(employee_id,week_id,sales_wed)
       into sales_info values(employee_id,week_id,sales_thur)
       into sales_info values(employee_id,week_id,sales_fri)
select employee_id,week_id,sales_mon,sales_tue,sales_wed,
       sales_thur,sales_fri
  from sales_source_data;

  
select * from sales_info;
```
### 结果
```
EMPLOYEE_ID	  WEEK	    SALES
----------- ---------- ----------
	176	     6	     2000
	176	     6	     3000
	176	     6	     4000
	176	     6	     5000
	176	     6	     6000

```
