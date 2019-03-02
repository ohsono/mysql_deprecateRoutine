## Overview
__This feature originally built for MySQL 5.7__

A deprecation feature for `stored procedure` and `user defined function` on the database level.

This feature consists of `3 major components`:
- `A control table`
- `A logging table`
- few Deprecation `Procedures` & `functions`

## Control TABLE
  - `DBA_migration_status`
    - unique_check contrain by combination of 4 elements:
     {`source`,`destination`,`object_name`,`object_newname`,`object_type`}
    - daily restriction of deprecation by unique_check constraint

## Logging TABLE
  - `DBA_migration_log`
     - migration_status_id => uid.DBA_migration_status (no foreign_key but logically)
     - log_text: detail of logging
     - status_flg_id: to keep track of where/what happened (step_id internal procedure)

## Functions and Procedures
  - `deprecated.Proc_DBA_DeprecateRoutines`
    - Deprecate Routines (Stored Procedures or Functions)
    
    ```
    * params:
     - object_source: the name of the database schema where object currently placed i.e.) reporting
     - object_destination: the name of the database schema where object ended up. i.e.) deprecated
     - object_name: the name of object (stored procedure or function)
     - object_type: type ('procedure' or 'function')

    call `deprecated.Proc_DBA_DeprecateRoutines` ('reporting','deprecated','Proc_daily_report','procedure'); 
    ```

  - `deprecated.Proc_RenameDeprecatedFN`
    - Rename functions to follow our naming convention 
    ```
    # nameing convention 
    - {function_name}_DEPR_YYYYMMDD
    call `deprecated.Proc_RenameDeprecatedFN` ('reporting','fn_daily_report','fn_daily_report_DEPR_20190101');
    ```

  - `deprecated.Proc_RenameDeprecatedSP`
    - Rename procedure to follow our naming convention 
    ```
    # nameing convention 
    - {Procedure_name}_DEPR_YYYYMMDD
    call `deprecated.Proc_RenameDeprecatedSP` ('reporting','Proc_daily_report','Proc_daily_report_DEPR_20190101');
    ```

## Test
 - create test database
 - create test.Proc_test1234
 - create test.FN_test1234
 - call deprecated.Proc_DBA_DeprecateRoutines for both function and procedure
 - sample output
 ```
 mysql> select * from deprecated.DBA_migration_log;
 +-----+---------------------+---------------------------------------------------------------+----------------+----------------+------------+-----------+---------------------+
 | uid | migration_status_id | log_text                                                      | status_flag_id | condition_code | error_code | error_num | log_date            |
 +-----+---------------------+---------------------------------------------------------------+----------------+----------------+------------+-----------+---------------------+
 |   1 |                  -1 | checking object_type                                          |              0 |           NULL | NULL       |      NULL | 2019-03-01 18:39:44 |
 |   2 |                   1 | passed init                                                   |              1 |           NULL | NULL       |      NULL | 2019-03-01 18:39:44 |
 |   3 |                   1 | entering [mysql.procs_priv]!                                  |              4 |           NULL | NULL       |      NULL | 2019-03-01 18:39:45 |
 |   4 |                   1 | [mysql.procs_priv]: moving completed!                         |              5 |           NULL | NULL       |      NULL | 2019-03-01 18:39:45 |
 |   5 |                   1 | entering [mysql.proc]!                                        |              6 |           NULL | NULL       |      NULL | 2019-03-01 18:39:45 |
 |   6 |                   1 | [mysql.proc]: routines migration completed!                   |              7 |           NULL | NULL       |      NULL | 2019-03-01 18:39:45 |
 |   7 |                   1 | {deprecated.Proc_test1234_DEPR_20190301}: migration comleted! |              8 |           NULL | NULL       |      NULL | 2019-03-01 18:39:45 |
 |   8 |                  -1 | checking object_type                                          |              0 |           NULL | NULL       |      NULL | 2019-03-01 18:39:45 |
 |   9 |                   2 | passed init                                                   |              1 |           NULL | NULL       |      NULL | 2019-03-01 18:39:45 |
 |  10 |                   2 | {Proc_test1234} cannot be found or exist already!             |              1 |              1 | 42000      |      1644 | 2019-03-01 18:39:45 |
 +-----+---------------------+---------------------------------------------------------------+----------------+----------------+------------+-----------+---------------------+
 10 rows in set (0.00 sec)

 mysql> select * from deprecated.DBA_migration_status;
 +-----+--------+-------------+---------------+-----------------------------+-------------+---------------------+---------------------+---------------------------------------------------------------+-------------+
 | uid | source | destination | object_name   | object_newname              | object_type | create_date         | update_date         | comments                                                      | status_flag |
 +-----+--------+-------------+---------------+-----------------------------+-------------+---------------------+---------------------+---------------------------------------------------------------+-------------+
 |   1 | test   | deprecated  | Proc_test1234 | Proc_test1234_DEPR_20190301 | procedure   | 2019-03-01 18:39:44 | 2019-03-01 18:39:45 | {deprecated.Proc_test1234_DEPR_20190301}: migration comleted! |           1 |
 |   2 | test   | deprecated  | Proc_test1234 | Proc_test1234_DEPR_20190301 | function    | 2019-03-01 18:39:45 | 2019-03-01 18:39:45 | {Proc_test1234} cannot be found or exist already!             |           1 |
 +-----+--------+-------------+---------------+-----------------------------+-------------+---------------------+---------------------+---------------------------------------------------------------+-------------+
 2 rows in set (0.00 sec)
 ```
