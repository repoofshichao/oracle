1.创建目录
create directory SYSTEM_DUMP as '/home/oracle/test'
select directory_path from dba_directories where directory_name='SYSTEM_DUMP';

2.导出数据
expdp <user>/<password> schemas=<schema> dumpfile=database_dump.dmp directory=SYSTEM_DUMP

3.导入数据
impdp <user>/<password> remap_schema=<from>:<to> dumpfile=database_dump.dmp

--------------------
实际操作过程中如果是<表空间>的导出导入，还需要将源数据库置为只读，并且考虑跨平台带来的字节大小端。
1.查询表空间是自包含的
execute dbms_tts.transport_set_check('tablespace_name')

2.查询对应平台的大小端
col platform_name for a40;
select * from v$transportable_platform order by platform_name

3.转换大小端
在源这里转换
convert datafile 'from_file' to platform 'target_platform' format 'to_file';
在目标这里转换
convert datafile 'from_file' to platform 'source_platform' format 'to_file';
