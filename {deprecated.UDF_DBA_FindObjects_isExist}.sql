DROP FUNCTION IF EXISTS `deprecated`.`UDF_DBA_FindObjects_isExist`;

DELIMITER $$
CREATE FUNCTION `deprecated`.`UDF_DBA_FindObjects_isExist`( schemaName varchar(50), object_name varchar(100) ) RETURNS tinyint(1)
    READS SQL DATA
BEGIN
	IF ((SELECT 1 FROM information_schema.ROUTINES WHERE	ROUTINE_NAME = object_name AND ROUTINE_SCHEMA =schemaName) > 0 ) THEN
		return true;
	ELSE
		return false;
	END IF;

END$$
DELIMITER ;
