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
    - TBD

  - `deprecated.Proc_RenameDeprecatedFN`
    - TBD

  - `deprecated.Proc_RenameDeprecatedSP`
    - TBD
