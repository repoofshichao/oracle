## rman高级功能
### 1.配置恢复目录数据库
```
sqlplus / as sysdba;
create tablespace rman datafile '/u02/oradata/orcl/rman.DBF' size 150m
autoextend on next 50m;
```

### 2.创建恢复目录拥有者
```
create user c##rcat_owner identified by Rcat9095
default tablespace rman
quota unlimited on rman;

grant recovery_catalog_owner to c##rcat_owner;
```

### 3.创建恢复目录
```
exit;
rman catalog c##rcat_owner/Rcat9095
create catalog;
```

### 4.同步恢复目录
```
rman target / catalog c##rcat_owner/Rcat9095

register database;
resync catalog;
```

### 5.将脚本存储在恢复目录中
```
create global script global_backup_db {backup database plus archivelog;}
```

### 6.执行恢复目录中的脚本
```
run {execute script global_backup_db;}
```

### 7.查看脚本
```
list script names;
print global script global_backup_db;
```

### 8.删除catalog
```
drop catalog;
```