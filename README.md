# SimpleSQLParser
+ A SQL Parser Based [pg_query](https://github.com/lfittl/pg_query) and [postgresql source code](https://www.postgresql.org/) 
+ It supports all TPCH and TPCDS queries , but it can't be used to "CREATE, UPDATE, etc." (**WAITING TO DO**)
# Usage
```
make fb         # to compile .y and .l files
make all
./a.out <sql_id>
```
# Tested Environment
```
CentOS Linux release 7.5.1804 (Core) 
gcc 4.8.5
bison (GNU Bison) 3.0.4
flex 2.5.37
```


