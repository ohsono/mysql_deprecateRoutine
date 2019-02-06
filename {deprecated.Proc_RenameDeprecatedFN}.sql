DELIMITER $$
CREATE DEFINER=`hochanson`@`localhost` PROCEDURE `Proc_RenameDeprecatedFN`(dbschema varchar(20), origin varchar(100), destin varchar(100))
BEGIN

	#DECLARE destin varchar(200);
	DECLARE destination1 varchar(200);
	DECLARE destination2 varchar(200);

	DECLARE EXIT HANDLER FOR SQLSTATE '42000'
		BEGIN
		ROLLBACK;
            SELECT 'A serious error has occurred, the operation rollbacked and the stored procedure was terminated';
		END;

	IF (destin is null or destin = '') THEN
		SET destin = CONCAT(origin,'_DEPR_',curdate()+0);
	END IF;

  #  select origin, destin;


	START TRANSACTION;

	# looking for function privileges on mysql
	IF (SELECT count(1) FROM mysql.procs_priv WHERE routine_name=origin and Db=dbschema and routine_type='FUNCTION') > 0 THEN
		SELECT concat('found [',origin,'] on procs_priv!');
        #checking dest proc
        IF (SELECT count(1) FROM mysql.procs_priv WHERE routine_name=destin and Db=dbschema and routine_type='FUNCTION') > 0 THEN
			SELECT concat('[',destin,']: the deprecated function already exists! please check on mysql.procs_priv!');
            #rollback
			SIGNAL SQLSTATE '42000';
		ELSE
			#'we should rename it now';
			UPDATE mysql.procs_priv
			SET
				routine_name = destination,
				timestamp = CURRENT_TIMESTAMP()
			WHERE
				routine_name = dest AND Db = dbschema
					AND routine_type = 'FUNCTION';

			SELECT `routine_name` FROM mysql.proc WHERE name=destin and db=dbschema and `type`='FUNCTION' INTO @destination1;

            IF (@destination1 is not null) THEN
				SELECT CONCAT('procs_priv:{',@destination1,'} is done!');
			END IF;
        END IF;
	ELSE
		SELECT concat('{',origin,'}: the procs_priv has reviewed and found no data!');
	END IF;

	COMMIT;

    START TRANSACTION;

	# looking for function on mysql
	IF (SELECT count(1) FROM mysql.proc WHERE name=origin and db=dbschema and `type`='FUNCTION') > 0 THEN
		SELECT concat('found [',origin,'] on proc!');
        #checking dest proc
        IF (SELECT count(1) FROM mysql.proc WHERE name=destin and db=dbschema and `type`='FUNCTION') > 0 THEN
			SELECT concat('{',destin,'}: the deprecated function already exists! please check on mysql.proc!');
            #rollback
			SIGNAL SQLSTATE '42000';
		ELSE
			#'we should rename it now';
			UPDATE mysql.proc
			SET
				`name` = destin,
                specific_name = destin,
				modified = CURRENT_TIMESTAMP()
			WHERE
				name = origin
                    AND db = dbschema
					AND `type` = 'FUNCTION';

            SELECT `name` FROM mysql.proc WHERE name=destin and db=dbschema and `type`='FUNCTION' INTO @destination2;

            IF (@destination2 is not null) THEN
				SELECT CONCAT('proc:{',@destination2,'} is done!');
			END IF;
		END IF;
	ELSE
		SELECT concat('{',origin,'} function doesn''t exist!');
        SIGNAL SQLSTATE '42000';
	END IF;

	COMMIT;


END$$
DELIMITER ;
