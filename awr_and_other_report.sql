1.查看awr快照的生成频率和保存时间
select snap_interval,retention from dba_hist_wr_control;

2.产看awr占用的空间大小。
select occupant_desc,space_usage_kbytes from v$sysaux_occupants where occupant_name='SM/AWR';

3.手动获取awr
exec dbms_workload_repository.create_snapshot();

exec dbms_workload_repository.create_snapshot();

@?/rdbms/admin/awrrpt.sql

4.相关的其他报告
@?/rdbms/admin/ashrpt.sql
@?/rdbms/admin/addmrpt.sql
@?/rdbms/admin/awrddrpt.sql
@?/rdbms/admin/awrsqrtp.sql

