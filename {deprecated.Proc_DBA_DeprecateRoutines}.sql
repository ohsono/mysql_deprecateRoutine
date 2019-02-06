DROP IF EXISTS PROCEDURE `deprecated`.`Proc_DBA_DeprecateRoutines`;

DELIMITER $$
CREATE PROCEDURE `deprecated`.`Proc_DBA_DeprecateRoutines`(
	object_source varchar(60),
    object_destination VARCHAR(60),
    object_name	varchar(100),
    object_type VARCHAR(20)
)
Proc_LV:BEGIN

    DECLARE object_newname	varchar(100) default NULL;
    DECLARE error_Message varchar(128);   # char limit 128
    DECLARE last_id int default -1;
    DECLARE status_id int default -1;     # status_flag
    DECLARE processing_date datetime default CURRENT_TIMESTAMP;
    DECLARE DEPR varchar(128) default CONCAT(object_name,'_DEPR_',curdate()+0);
    DECLARE err_state_code varchar(10);
    DECLARE err_num INT;
    DECLARE err_msg varchar(128);
    DECLARE exit_code int default 0;
    DECLARE final_message varchar(1000);
    DECLARE naming_limits int default 0;
    DECLARE regex_rule varchar(100);

	DECLARE EXIT HANDLER FOR sqlexception
	BEGIN
        GET STACKED DIAGNOSTICS @cno = NUMBER;

		GET STACKED DIAGNOSTICS CONDITION @cno
            err_msg = MESSAGE_TEXT,
            err_state_code = RETURNED_SQLSTATE,
            err_num = MYSQL_ERRNO;

		IF err_state_code = '42000'
        THEN
			ROLLBACK;
		END IF;

        UPDATE deprecated.DBA_migration_status SET status_flag = status_id, comments = err_msg where uid = last_id;
        SELECT last_id, status_id, err_msg, err_state_code, err_num;
        INSERT INTO `deprecated`.`DBA_migration_log` (migration_status_id,log_text,status_flag_id,condition_code,error_code,error_num,log_date)
			VALUES (last_id, err_msg, status_id, @cno, err_state_code, err_num, now());
	END;

    SET regex_rule = '^.+_DEPR_([0-9]{8})$';

    # due to the fact that charcter length limit of routine is 64 by MYSQL,
    #    and our deprecated naming convention, {_DEPR_YYYYMMDD}, require 14 char to tag it.
    #    the total size become 64-14
    IF (naming_limits < 1)
    THEN
	     SET naming_limits = 64-14;
    END IF

    ##Reminder!! procedure name limits 64 char but we should consider the DEPR name with 14 char more due to our naming rule (_DEPR_YYYYMMDD) ##
    IF ((char_length(object_name) > naming_limits) AND (object_name regexp(regex_rule)) = 0) THEN
		SELECT CONCAT('Warnings: original name char "', char_length(object_name), '" is excceeding the char limit of [', naming_limits, ']') INTO error_Message;
		SIGNAL SQLSTATE '42000'
			SET MESSAGE_TEXT = error_Message;
    END IF;

	## if the proc has already change it's name tag _DEPR_YYYYMMDD, don't change it
    IF (object_name regexp(regex_rule)) THEN
		SET object_newname = object_name;
	ELSE
		SET object_newname = DEPR;
	END IF;

    select concat('debug:',object_newname);

	SET status_id := status_id+1; #0
    UPDATE deprecated.DBA_migration_status SET status_flag = status_id where uid = last_id;
	SELECT CONCAT('checking object_type') INTO error_Message;
    INSERT INTO `deprecated`.`DBA_migration_log` (migration_status_id,log_text,status_flag_id,condition_code,error_code,error_num,log_date)
		VALUES (last_id,error_Message,status_id,NULL,NULL,NULL,now());

	IF object_type not in ('procedure','function')
    THEN
		SELECT CONCAT('Please check the object_type error!') INTO error_Message;
        SIGNAL SQLSTATE '42000'
			SET MESSAGE_TEXT = error_Message;
    END IF;

    START TRANSACTION;

	# record init object name
    INSERT INTO deprecated.DBA_migration_status (source,destination,object_name, object_newname ,object_type,create_date,update_date, comments,status_flag)
		VALUES (object_source,	object_destination,	object_name, object_newname, object_type, NOW(),NOW(),'init',status_id);

	SET status_id := status_id+1;  #1
	SELECT LAST_INSERT_ID() INTO last_id;
	INSERT INTO `deprecated`.`DBA_migration_log` (migration_status_id,log_text,status_flag_id,condition_code,error_code,error_num,log_date)
		VALUES (last_id,'passed init',status_id,NULL,NULL,NULL,now());

    COMMIT;

	# object doesn''t exist on source or new tagged object is already exist on destination
	IF (deprecated.UDF_DBA_FindObjects_isExist(object_source, object_name)=0 OR
			deprecated.UDF_DBA_FindObjects_isExist(object_destination, object_newname)=1)
    THEN
        SELECT concat('{', object_name ,'} cannot be found or exist already!') INTO error_Message;
        SIGNAL SQLSTATE '42000'
			SET MESSAGE_TEXT = error_Message;
	END IF;

	IF deprecated.UDF_DBA_FindObjects_isExist(object_source, object_name)=1
    THEN # If object exist from source

		SET status_id := status_id+1; #2
        UPDATE deprecated.DBA_migration_status SET status_flag = status_id where uid = last_id;
        SET status_id = 3; #3
		UPDATE deprecated.DBA_migration_status SET object_newname = object_newname, status_flag = status_id where uid = last_id;

		START TRANSACTION;

		IF deprecated.UDF_DBA_FindObjects_isExist(object_destination, object_newname)=1
		THEN # check if destination has new tagged objects
			SELECT CONCAT('{',object_destination,'.',DEPR,'} already exists!') INTO error_Message;
			SIGNAL SQLSTATE '42000'
				SET MESSAGE_TEXT = error_Message;
		END IF;

		SET status_id := status_id+1; #4
		UPDATE deprecated.DBA_migration_status SET status_flag = status_id where uid = last_id;
		SELECT CONCAT('entering [mysql.procs_priv]!') INTO error_Message;
		INSERT INTO `deprecated`.`DBA_migration_log` (migration_status_id,log_text,status_flag_id,condition_code,error_code,error_num,log_date)
			VALUES (last_id,error_Message,status_id,NULL,NULL,NULL,now());

		IF EXISTS(SELECT COUNT(1) FROM mysql.procs_priv where routine_name = object_newname AND Db = object_source AND routine_type = object_type)
		THEN

			UPDATE mysql.procs_priv
			SET
				Db = object_destination,
				routine_name = object_newname,
				timestamp = CURRENT_TIMESTAMP()
			WHERE
				routine_name = object_name
				AND Db = object_source
				AND routine_type = object_type;

			SET status_id := status_id+1; #5
			UPDATE deprecated.DBA_migration_status SET status_flag = status_id where uid = last_id;
			SELECT CONCAT('[mysql.procs_priv]: moving completed!') INTO error_Message;
			INSERT INTO `deprecated`.`DBA_migration_log` (migration_status_id,log_text,status_flag_id,condition_code,error_code,error_num,log_date)
				VALUES (last_id,error_Message,status_id,NULL,NULL,NULL,now());
		END IF;

		SET status_id := status_id+1; #5 (if failed or no record) | 6 (if succeeded or exists)
		UPDATE deprecated.DBA_migration_status SET status_flag = status_id where uid = last_id;
		SELECT CONCAT('entering [mysql.proc]!') INTO error_Message;
		INSERT INTO `deprecated`.`DBA_migration_log` (migration_status_id,log_text,status_flag_id,condition_code,error_code,error_num,log_date)
			VALUES (last_id,error_Message,status_id,NULL,NULL,NULL,now());

		IF EXISTS(SELECT COUNT(1) FROM mysql.proc where `name` = object_newname AND db = object_source AND `type` = object_type)
		THEN

			UPDATE mysql.proc
			SET
				db = object_destination,
				`name` = object_newname,
				modified = CURRENT_TIMESTAMP()
			WHERE
				`name` = object_name
				AND db = object_source
				AND `type` = object_type;

			SET status_id = status_id+1; # 6 | 7
			UPDATE deprecated.DBA_migration_status SET status_flag = status_id where uid = last_id;
			SELECT CONCAT('[mysql.proc]: routines migration completed!') INTO error_Message;
			INSERT INTO `deprecated`.`DBA_migration_log` (migration_status_id,log_text,status_flag_id,condition_code,error_code,error_num,log_date)
				VALUES (last_id,error_Message,status_id,NULL,NULL,NULL,now());

		END IF;

		COMMIT;

	ELSE
		SELECT concat('{', object_source,'.', object_name,'} cannot be found!!!') into error_Message;
		SIGNAL SQLSTATE '42000'
			SET MESSAGE_TEXT = error_Message;
    END IF;

	# final check
	IF deprecated.UDF_DBA_FindObjects_isExist(object_destination, object_newname)=1
    THEN
		SET exit_code = 1;
	END IF;

    SET status_id = status_id+1; # 7 | 8

    IF (exit_code = 1) # if final check passed
	THEN
		set final_message = CONCAT('{',object_destination,'.', object_newname,'}: migration comleted!');
	ELSE
		SET final_message = CONCAT('{',object_destination,'.', object_newname,'}: migration failed!');
    END IF;

	UPDATE deprecated.DBA_migration_status
	SET
		status_flag = exit_code,
        comments = final_message
	WHERE
		uid = last_id;

	INSERT INTO `deprecated`.`DBA_migration_log` (migration_status_id,log_text,status_flag_id,condition_code,error_code,error_num,log_date)
		VALUES (last_id,final_message,status_id,NULL,NULL,NULL,now());

  # validation
	SELECT
		last_id,
		deprecated.UDF_DBA_FindObjects_isExist(object_source, DEPR) AS src_final_check,
		deprecated.UDF_DBA_FindObjects_isExist(object_destination, DEPR) AS dest_final_check;

END$$
DELIMITER ;
