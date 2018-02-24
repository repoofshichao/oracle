--配置快速恢复区
alter system set db_recovery_file_dest_size=10G;

alter system set db_recovery_file_dest='/u02/fra';

shutdown

startup mount

--启用归档日志模式
alter database archivelog;

alter database open;

archive log list;

--确认已经生成归档日志
select name,is_recovery_dest_file from v$archived_log;


rman target /

show all;
--配置参数
configure retention policy to recovery window of 14 days;
configure backup optimization on;
configure controlfile autobackup on;
configure device type disk parallelism 4 backup type to compressed backupset;
configure channel device type disk format '/u02/backups/%d%T%u';
configure archivelog deletion policy to backed up 2 times to disk;
show all;
--备份数据库和归档日志
backup database;
backup archivelog all delete input;


