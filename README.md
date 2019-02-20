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

