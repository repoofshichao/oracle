load data
infile 'names.txt'
badfile 'names.bad'
truncate
into table names
fields terminated by ','
trailing nullcols
(first,last)